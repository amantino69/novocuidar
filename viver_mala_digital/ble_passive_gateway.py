"""
BLE Passive Gateway
===================

Coletor BLE passivo para varios dispositivos (15+ dependendo do hardware),
com fila para desacoplar recepcao BLE e envio HTTP.

Foco:
- scanning passivo (sem conexão GATT por padrão);
- robustez em picos de anúncios;
- simplicidade para rodar em Linux/Raspberry Pi e ambientes próximos.

Autoria:
- Assinatura: GUSTAVO_DEV_VP01
- Padrao de assinatura aplicado para rastreabilidade tecnica.
"""

import argparse
import asyncio
import signal
import threading
import time
from dataclasses import dataclass, field
from queue import Empty, Full, Queue
from typing import Dict, Optional, Set

import requests
from bleak import BleakScanner


DEFAULT_URL = "https://seu-sistema.com/api/receber-sinal"
DEFAULT_QUEUE_SIZE = 2000
DEFAULT_DEDUP_WINDOW_MS = 800


@dataclass
class GatewayStats:
    detected: int = 0
    enqueued: int = 0
    sent: int = 0
    send_errors: int = 0
    dropped_queue_full: int = 0
    dropped_dedup: int = 0
    start_ts: float = field(default_factory=time.time)


class BlePassiveGateway:
    def __init__(
        self,
        url: str,
        max_devices: int,
        queue_size: int,
        dedup_window_ms: int,
        allowed_macs: Optional[Set[str]] = None,
        request_timeout: float = 5.0,
    ) -> None:
        self.url = url
        self.max_devices = max_devices
        self.queue_size = queue_size
        self.dedup_window_ms = dedup_window_ms
        self.allowed_macs = {m.upper() for m in allowed_macs} if allowed_macs else None
        self.request_timeout = request_timeout

        self.signal_queue: Queue = Queue(maxsize=self.queue_size)
        self.stats = GatewayStats()
        self.seen_devices: Set[str] = set()
        self.last_seen_ms: Dict[str, int] = {}

        self.stop_event = threading.Event()
        self.http_thread = threading.Thread(target=self._http_worker, daemon=True)
        self.scanner: Optional[BleakScanner] = None

    def _now_ms(self) -> int:
        return int(time.time() * 1000)

    def _to_payload(self, device, advertisement_data) -> dict:
        return {
            "mac": device.address.upper(),
            "name": device.name or advertisement_data.local_name,
            "rssi": device.rssi,
            "service_uuids": list(advertisement_data.service_uuids or []),
            "service_data": dict(advertisement_data.service_data or {}),
            "manufacturer_data": dict(advertisement_data.manufacturer_data or {}),
            "ts": int(time.time()),
        }

    def _should_accept(self, mac: str) -> bool:
        if self.allowed_macs and mac not in self.allowed_macs:
            return False
        if len(self.seen_devices) >= self.max_devices and mac not in self.seen_devices:
            return False
        return True

    def _dedup_passed(self, mac: str) -> bool:
        now = self._now_ms()
        last = self.last_seen_ms.get(mac)
        if last and (now - last) < self.dedup_window_ms:
            self.stats.dropped_dedup += 1
            return False
        self.last_seen_ms[mac] = now
        return True

    def detection_callback(self, device, advertisement_data) -> None:
        mac = (device.address or "").upper()
        if not mac:
            return

        self.stats.detected += 1

        if not self._should_accept(mac):
            return
        if not self._dedup_passed(mac):
            return

        payload = self._to_payload(device, advertisement_data)
        self.seen_devices.add(mac)

        try:
            self.signal_queue.put_nowait(payload)
            self.stats.enqueued += 1
        except Full:
            self.stats.dropped_queue_full += 1

    def _http_worker(self) -> None:
        with requests.Session() as session:
            while not self.stop_event.is_set():
                try:
                    payload = self.signal_queue.get(timeout=0.2)
                except Empty:
                    continue

                try:
                    resp = session.post(self.url, json=payload, timeout=self.request_timeout)
                    if 200 <= resp.status_code < 300:
                        self.stats.sent += 1
                    else:
                        self.stats.send_errors += 1
                except Exception:
                    self.stats.send_errors += 1
                finally:
                    self.signal_queue.task_done()

    async def run(self) -> None:
        self.http_thread.start()
        self.scanner = BleakScanner(detection_callback=self.detection_callback)
        await self.scanner.start()
        print("[GATEWAY] Scanner BLE passivo iniciado")
        print(f"[GATEWAY] URL de destino: {self.url}")
        print(
            f"[GATEWAY] Configuracao: max_devices={self.max_devices} queue_size={self.queue_size} dedup_window_ms={self.dedup_window_ms}"
        )

        while not self.stop_event.is_set():
            await asyncio.sleep(10)
            uptime = int(time.time() - self.stats.start_ts)
            print(
                f"[GATEWAY] up={uptime}s det={self.stats.detected} enq={self.stats.enqueued} "
                f"sent={self.stats.sent} err={self.stats.send_errors} "
                f"drop_q={self.stats.dropped_queue_full} drop_dedup={self.stats.dropped_dedup} "
                f"tracked={len(self.seen_devices)} q={self.signal_queue.qsize()}"
            )

    async def shutdown(self) -> None:
        self.stop_event.set()
        if self.scanner:
            await self.scanner.stop()
        print("[GATEWAY] Scanner BLE parado")

        # Tenta drenar o restante da fila antes de finalizar.
        deadline = time.time() + 3
        while self.signal_queue.qsize() > 0 and time.time() < deadline:
            time.sleep(0.1)
        print("[GATEWAY] Worker HTTP finalizado")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="BLE Passive Gateway (scanner + fila + HTTP POST)")
    parser.add_argument("--url", default=DEFAULT_URL, help="URL de destino HTTP para POST")
    parser.add_argument("--max-devices", type=int, default=15, help="Máximo de MACs únicos rastreados")
    parser.add_argument("--queue-size", type=int, default=DEFAULT_QUEUE_SIZE, help="Capacidade da fila")
    parser.add_argument(
        "--dedup-window-ms",
        type=int,
        default=DEFAULT_DEDUP_WINDOW_MS,
        help="Janela de deduplicação por MAC (ms)",
    )
    parser.add_argument(
        "--allowed-macs",
        default="",
        help="Lista de MACs separados por vírgula (opcional)",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=5.0,
        help="Timeout do HTTP POST em segundos",
    )
    return parser.parse_args()


async def main() -> None:
    args = parse_args()
    allowed_macs = {
        part.strip().upper()
        for part in args.allowed_macs.split(",")
        if part.strip()
    }
    gateway = BlePassiveGateway(
        url=args.url,
        max_devices=args.max_devices,
        queue_size=args.queue_size,
        dedup_window_ms=args.dedup_window_ms,
        allowed_macs=allowed_macs if allowed_macs else None,
        request_timeout=args.timeout,
    )

    loop = asyncio.get_running_loop()

    def _stop_handler() -> None:
        gateway.stop_event.set()

    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, _stop_handler)
        except NotImplementedError:
            pass

    try:
        await gateway.run()
    finally:
        await gateway.shutdown()


if __name__ == "__main__":
    asyncio.run(main())

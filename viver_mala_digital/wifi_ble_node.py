"""
WiFi BLE Node
============

No BLE com scan passivo local e envio de eventos para o mestre via TCP.

Autoria:
- Assinatura: GUSTAVO_DEV_VP01
- Padrao de assinatura aplicado para rastreabilidade tecnica.
"""

import argparse
import asyncio
import json
import signal
import threading
import time
from dataclasses import dataclass, field
from queue import Empty, Full, Queue
from socket import AF_INET, SOCK_STREAM, socket
from typing import Dict, Optional, Set

from bleak import BleakScanner


DEVICES = {
    "F8:8F:C8:3A:B7:92": {"type": "scale", "name": "Balança OKOK", "method": "advertisement"},
    "00:5F:BF:9A:64:DF": {"type": "blood_pressure", "name": "Omron HEM-7156T", "method": "gatt"},
    "DC:23:4E:DA:E9:DD": {"type": "thermometer", "name": "MOBI m3ja", "method": "gatt"},
    "88:D2:11:C8:20:31": {"type": "stethoscope", "name": "Eko CORE 500", "method": "gatt_stream"},
}


@dataclass
class NodeStats:
    detected: int = 0
    enqueued: int = 0
    sent: int = 0
    send_errors: int = 0
    dropped_dedup: int = 0
    dropped_queue_full: int = 0
    start_ts: float = field(default_factory=time.time)


class WifiBleNode:
    def __init__(
        self,
        node_id: str,
        master_host: str,
        master_port: int,
        auth_token: str,
        max_devices: int,
        dedup_window_ms: int,
        queue_size: int,
        send_timeout: float,
        allowed_macs: Optional[Set[str]],
    ) -> None:
        self.node_id = node_id
        self.master_host = master_host
        self.master_port = master_port
        self.auth_token = auth_token
        self.max_devices = max_devices
        self.dedup_window_ms = dedup_window_ms
        self.send_timeout = send_timeout
        self.allowed_macs = {m.upper() for m in allowed_macs} if allowed_macs else None

        self.queue: Queue = Queue(maxsize=queue_size)
        self.stats = NodeStats()
        self.stop_event = threading.Event()
        self.sender_thread = threading.Thread(target=self._sender_worker, daemon=True)

        self.last_seen_ms: Dict[str, int] = {}
        self.seen_macs: Set[str] = set()
        self.scanner: Optional[BleakScanner] = None
        self.scale_state = {"valor": 0, "contador": 0, "confirmado": False}

    def _now_ms(self) -> int:
        return int(time.time() * 1000)

    def _should_accept(self, mac: str) -> bool:
        if self.allowed_macs and mac not in self.allowed_macs:
            return False
        if len(self.seen_macs) >= self.max_devices and mac not in self.seen_macs:
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

    def _processar_balanca(self, manufacturer_data: dict) -> Optional[dict]:
        for data in manufacturer_data.values():
            if not data or len(data) < 2:
                continue

            raw = (data[0] << 8) | data[1]
            peso = round(raw / 100, 2)

            if raw == 0:
                self.scale_state = {"valor": 0, "contador": 0, "confirmado": False}
                return None

            if raw == self.scale_state["valor"]:
                self.scale_state["contador"] += 1
            else:
                self.scale_state["valor"] = raw
                self.scale_state["contador"] = 1
                self.scale_state["confirmado"] = False

            if self.scale_state["contador"] >= 5 and not self.scale_state["confirmado"]:
                self.scale_state["confirmado"] = True
                return {"weight": peso}

        return None

    def detection_callback(self, device, advertisement_data) -> None:
        mac = (device.address or "").upper()
        if not mac:
            return

        self.stats.detected += 1
        known = DEVICES.get(mac)
        if not known:
            return

        if not self._should_accept(mac):
            return
        if not self._dedup_passed(mac):
            return

        values = {}
        if known["type"] == "scale":
            weight_data = self._processar_balanca(dict(advertisement_data.manufacturer_data or {}))
            if not weight_data:
                return
            values = weight_data
        else:
            # Neste modo, dispositivos nao-GATT enviam evento de presenca.
            values = {"detected": True, "rssi": device.rssi}

        payload = {
            "token": self.auth_token,
            "node_id": self.node_id,
            "timestamp": int(time.time()),
            "mac": mac,
            "name": known["name"] or device.name or advertisement_data.local_name,
            "rssi": device.rssi,
            "device_type": known["type"],
            "method": known["method"],
            "values": values,
            "service_data": dict(advertisement_data.service_data or {}),
            "manufacturer_data": dict(advertisement_data.manufacturer_data or {}),
            "service_uuids": list(advertisement_data.service_uuids or []),
        }
        self.seen_macs.add(mac)

        try:
            self.queue.put_nowait(payload)
            self.stats.enqueued += 1
        except Full:
            self.stats.dropped_queue_full += 1

    def _send_to_master(self, payload: dict) -> bool:
        packet = (json.dumps(payload, separators=(",", ":")) + "\n").encode("utf-8")
        with socket(AF_INET, SOCK_STREAM) as s:
            s.settimeout(self.send_timeout)
            s.connect((self.master_host, self.master_port))
            s.sendall(packet)
            data = s.recv(2048)
            if not data:
                return False
            try:
                ack = json.loads(data.decode("utf-8").strip())
            except Exception:
                return False
            return bool(ack.get("ok"))

    def _sender_worker(self) -> None:
        while not self.stop_event.is_set():
            try:
                payload = self.queue.get(timeout=0.2)
            except Empty:
                continue

            ok = False
            for attempt in range(3):
                try:
                    ok = self._send_to_master(payload)
                    if ok:
                        break
                except Exception:
                    pass
                time.sleep(min(1.0, 0.2 * (attempt + 1)))

            if ok:
                self.stats.sent += 1
            else:
                self.stats.send_errors += 1

            self.queue.task_done()

    async def run(self) -> None:
        self.sender_thread.start()
        self.scanner = BleakScanner(detection_callback=self.detection_callback)
        await self.scanner.start()
        print("[NODE] Scanner BLE passivo iniciado")
        print(f"[NODE] Mestre configurado: {self.master_host}:{self.master_port}")
        print(f"[NODE] Configuracao: node_id={self.node_id} max_devices={self.max_devices}")

        while not self.stop_event.is_set():
            await asyncio.sleep(10)
            up = int(time.time() - self.stats.start_ts)
            print(
                "[NODE] "
                f"up={up}s det={self.stats.detected} enq={self.stats.enqueued} "
                f"sent={self.stats.sent} err={self.stats.send_errors} "
                f"drop_dedup={self.stats.dropped_dedup} drop_q={self.stats.dropped_queue_full} "
                f"tracked={len(self.seen_macs)} q={self.queue.qsize()}"
            )

    async def shutdown(self) -> None:
        self.stop_event.set()
        if self.scanner:
            await self.scanner.stop()
        print("[NODE] Scanner BLE parado")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Nó BLE passivo para envio ao mestre WiFi")
    parser.add_argument("--node-id", required=True, help="Identificador único do nó")
    parser.add_argument("--master-host", required=True, help="IP/host do mestre")
    parser.add_argument("--master-port", type=int, default=12345, help="Porta TCP do mestre")
    parser.add_argument("--auth-token", default="", help="Token compartilhado com o mestre")
    parser.add_argument("--max-devices", type=int, default=7, help="Máximo de MACs únicos por nó")
    parser.add_argument("--dedup-window-ms", type=int, default=800, help="Janela de dedup por MAC")
    parser.add_argument("--queue-size", type=int, default=1500, help="Capacidade da fila local")
    parser.add_argument("--send-timeout", type=float, default=3.0, help="Timeout TCP de envio")
    parser.add_argument("--allowed-macs", default="", help="MACs permitidos separados por vírgula")
    return parser.parse_args()


async def main() -> None:
    args = parse_args()
    allowed_macs = {
        part.strip().upper()
        for part in args.allowed_macs.split(",")
        if part.strip()
    }
    node = WifiBleNode(
        node_id=args.node_id,
        master_host=args.master_host,
        master_port=args.master_port,
        auth_token=args.auth_token,
        max_devices=args.max_devices,
        dedup_window_ms=args.dedup_window_ms,
        queue_size=args.queue_size,
        send_timeout=args.send_timeout,
        allowed_macs=allowed_macs if allowed_macs else None,
    )

    loop = asyncio.get_running_loop()

    def _stop_handler() -> None:
        node.stop_event.set()

    for sig in (signal.SIGINT, signal.SIGTERM):
        try:
            loop.add_signal_handler(sig, _stop_handler)
        except NotImplementedError:
            pass

    try:
        await node.run()
    finally:
        await node.shutdown()


if __name__ == "__main__":
    asyncio.run(main())

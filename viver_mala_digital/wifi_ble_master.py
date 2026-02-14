"""
WiFi BLE Master
===============

Servidor central para receber sinais BLE de varios nos via WiFi
e processar uma fila global antes do envio HTTP.

Autoria:
- Assinatura: GUSTAVO_DEV_VP01
- Padrao de assinatura aplicado para rastreabilidade tecnica.
"""

import argparse
import json
import threading
import time
from dataclasses import dataclass, field
from queue import Empty, PriorityQueue
from socketserver import StreamRequestHandler, ThreadingTCPServer
from typing import Any, Dict, Optional, Tuple

import requests


@dataclass
class MasterStats:
    received: int = 0
    queued: int = 0
    sent: int = 0
    send_errors: int = 0
    auth_failures: int = 0
    invalid_payload: int = 0
    queue_drops: int = 0
    start_ts: float = field(default_factory=time.time)


class MasterState:
    def __init__(self, max_queue_size: int) -> None:
        self.queue: PriorityQueue[Tuple[int, int, Dict[str, Any]]] = PriorityQueue(maxsize=max_queue_size)
        self.seq = 0
        self.lock = threading.Lock()
        self.stats = MasterStats()
        self.current_appointment_id: Optional[str] = None
        self.last_check_ts: float = 0.0
        self.check_interval: float = 3.0

    def next_seq(self) -> int:
        with self.lock:
            self.seq += 1
            return self.seq


STATE: MasterState
CONFIG: Dict[str, Any]


def calc_priority(payload: Dict[str, Any]) -> int:
    # Quanto menor o numero, maior a prioridade.
    device_priority = {
        "blood_pressure": 1,
        "stethoscope": 2,
        "thermometer": 3,
        "scale": 4,
    }
    kind = str(payload.get("device_type", "generic")).lower()
    base = device_priority.get(kind, 5)
    rssi = int(payload.get("rssi", -100))
    # RSSI mais alto (menos negativo) ganha um pequeno bonus.
    rssi_bonus = max(-30, min(30, rssi + 100))
    return base * 100 - rssi_bonus


def get_active_appointment_from_api(session: requests.Session) -> Optional[str]:
    url = f"{CONFIG['api_url']}/biometrics/active-appointment"
    try:
        resp = session.get(url, timeout=5)
        if resp.status_code == 200:
            data = resp.json()
            if isinstance(data, dict) and data.get("id"):
                return data["id"]
            if isinstance(data, list) and data and isinstance(data[0], dict):
                return data[0].get("id")
    except Exception:
        return None
    return None


def detect_active_appointment(session: requests.Session) -> Optional[str]:
    fixed = CONFIG.get("fixed_appointment")
    if fixed:
        STATE.current_appointment_id = fixed
        return fixed

    now = time.time()
    if STATE.current_appointment_id and (now - STATE.last_check_ts) < STATE.check_interval:
        return STATE.current_appointment_id
    STATE.last_check_ts = now

    appointment_id = get_active_appointment_from_api(session)
    if appointment_id:
        STATE.current_appointment_id = appointment_id
    return STATE.current_appointment_id


def send_cache(session: requests.Session, payload: Dict[str, Any]) -> None:
    cache_payload = {
        "deviceType": payload.get("device_type", "generic"),
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
        "values": payload.get("values", {}),
    }
    try:
        session.post(
            f"{CONFIG['api_url']}/biometrics/ble-cache",
            json=cache_payload,
            timeout=CONFIG["http_timeout"],
        )
    except Exception:
        pass


class NodeTCPHandler(StreamRequestHandler):
    def handle(self) -> None:
        raw = self.rfile.readline(1024 * 128)
        if not raw:
            return

        try:
            payload = json.loads(raw.decode("utf-8"))
        except Exception:
            STATE.stats.invalid_payload += 1
            self.wfile.write(b'{"ok":false,"error":"invalid_json"}\n')
            return

        token = payload.get("token")
        if CONFIG["auth_token"] and token != CONFIG["auth_token"]:
            STATE.stats.auth_failures += 1
            self.wfile.write(b'{"ok":false,"error":"unauthorized"}\n')
            return

        STATE.stats.received += 1
        seq = STATE.next_seq()
        priority = calc_priority(payload)

        try:
            STATE.queue.put_nowait((priority, seq, payload))
            STATE.stats.queued += 1
            self.wfile.write(b'{"ok":true}\n')
        except Exception:
            STATE.stats.queue_drops += 1
            self.wfile.write(b'{"ok":false,"error":"queue_full"}\n')


def queue_worker(stop_event: threading.Event) -> None:
    with requests.Session() as session:
        while not stop_event.is_set():
            try:
                _, _, item = STATE.queue.get(timeout=0.2)
            except Empty:
                continue

            send_cache(session, item)
            appointment_id = detect_active_appointment(session)
            if not appointment_id:
                STATE.queue.task_done()
                continue

            outbound = {
                "appointmentId": appointment_id,
                "deviceType": item.get("device_type", "generic"),
                "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
                "values": item.get("values", {}),
                "metadata": {
                    "nodeId": item.get("node_id"),
                    "mac": item.get("mac"),
                    "name": item.get("name"),
                    "rssi": item.get("rssi"),
                    "method": item.get("method"),
                    "serviceData": item.get("service_data", {}),
                    "manufacturerData": item.get("manufacturer_data", {}),
                    "serviceUuids": item.get("service_uuids", []),
                    "sourceTimestamp": item.get("timestamp", int(time.time())),
                },
            }

            ok = False
            for attempt in range(CONFIG["http_retries"] + 1):
                try:
                    resp = session.post(
                        f"{CONFIG['api_url']}/biometrics/ble-reading",
                        json=outbound,
                        timeout=CONFIG["http_timeout"],
                    )
                    if 200 <= resp.status_code < 300:
                        ok = True
                        break
                except Exception:
                    pass
                time.sleep(min(2.0, 0.2 * (attempt + 1)))

            if ok:
                STATE.stats.sent += 1
            else:
                STATE.stats.send_errors += 1

            STATE.queue.task_done()


def print_stats_loop(stop_event: threading.Event) -> None:
    while not stop_event.is_set():
        time.sleep(10)
        up = int(time.time() - STATE.stats.start_ts)
        print(
            "[MASTER] "
            f"up={up}s recv={STATE.stats.received} queued={STATE.stats.queued} "
            f"sent={STATE.stats.sent} err={STATE.stats.send_errors} "
            f"auth_fail={STATE.stats.auth_failures} invalid={STATE.stats.invalid_payload} "
            f"drop_q={STATE.stats.queue_drops} q={STATE.queue.qsize()}"
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Mestre WiFi para agregacao BLE")
    parser.add_argument("--host", default="0.0.0.0", help="Host TCP do servidor mestre")
    parser.add_argument("--port", type=int, default=12345, help="Porta TCP do servidor mestre")
    parser.add_argument("--local", action="store_true", help="Usar ambiente local (http://localhost:5239)")
    parser.add_argument("--url", default="", help="URL base customizada (ex: http://192.168.1.100:5239)")
    parser.add_argument("--appointment", default="", help="ID fixo da consulta (opcional)")
    parser.add_argument("--auth-token", default="", help="Token compartilhado entre mestre e nós")
    parser.add_argument("--max-queue-size", type=int, default=5000, help="Capacidade da fila global")
    parser.add_argument("--http-timeout", type=float, default=5.0, help="Timeout HTTP em segundos")
    parser.add_argument("--http-retries", type=int, default=2, help="Tentativas adicionais de envio")
    return parser.parse_args()


def main() -> None:
    global STATE, CONFIG
    args = parse_args()
    if args.url:
        base_url = args.url.rstrip("/")
    elif args.local:
        base_url = "http://localhost:5239"
    else:
        base_url = "https://www.telecuidar.com.br"

    CONFIG = {
        "base_url": base_url,
        "api_url": f"{base_url}/api",
        "fixed_appointment": args.appointment or None,
        "auth_token": args.auth_token,
        "http_timeout": args.http_timeout,
        "http_retries": args.http_retries,
    }
    STATE = MasterState(max_queue_size=args.max_queue_size)

    server = ThreadingTCPServer((args.host, args.port), NodeTCPHandler)
    server.daemon_threads = True
    server.allow_reuse_address = True

    stop_event = threading.Event()
    worker = threading.Thread(target=queue_worker, args=(stop_event,), daemon=True)
    stats = threading.Thread(target=print_stats_loop, args=(stop_event,), daemon=True)
    worker.start()
    stats.start()

    print(f"[MASTER] Servidor TCP ativo em {args.host}:{args.port}")
    print(f"[MASTER] API configurada: {CONFIG['api_url']}")
    if CONFIG["fixed_appointment"]:
        print(f"[MASTER] Consulta fixa configurada: {CONFIG['fixed_appointment']}")
    print(f"[MASTER] Capacidade da fila global: {args.max_queue_size}")

    try:
        server.serve_forever(poll_interval=0.5)
    except KeyboardInterrupt:
        print("\n[MASTER] Encerrando servico...")
    finally:
        stop_event.set()
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    main()

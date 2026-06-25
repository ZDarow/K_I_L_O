#!/usr/bin/env python3
"""
Парсер btmon логов — извлечение GATT-операций из вывода btmon/btmon.

Парсит вывод btmon (Bluetooth Monitor) и извлекает:
  - GATT-сервисы и характеристики
  - Read/Write/Nofity операции
  - MTU exchange
  - HCI команды/события

Поддерживаемые форматы ввода:
  - stdout btmon (--filter, btmon -w)
  - текстовый файл с логом btmon
  - pipe из btmon в реальном времени

Примеры:
  python3 btmon-parse.py capture.log
  python3 btmon-parse.py capture.log --format json --output gatt.json
  python3 btmon-parse.py capture.log --filter gatt
  btmon | python3 btmon-parse.py --stdin
"""

import argparse
import json
import logging
import re
import sys
from collections import defaultdict
from datetime import datetime
from typing import Optional

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger("btmon-parse")

# Регулярные выражения для парсинга btmon
RE_TIMESTAMP = re.compile(r"^= (\S+ \S+)")
RE_ATT_READ_REQ = re.compile(
    r"ATT Handle: 0x([0-9a-fA-F]+)"
)
RE_ATT_READ_RSP = re.compile(r"Read Response|Value: ([0-9a-fA-F ]+)")
RE_ATT_WRITE_REQ = re.compile(r"ATT Handle: 0x([0-9a-fA-F]+)")
RE_ATT_WRITE_CMD = re.compile(r"ATT Handle: 0x([0-9a-fA-F]+)")
RE_ATT_NOTIFY = re.compile(r"ATT Handle: 0x([0-9a-fA-F]+)")
RE_ATT_INDICATE = re.compile(r"ATT Handle: 0x([0-9a-fA-F]+)")
RE_MTU = re.compile(r"MTU ([RF]X|TX): (\d+)")
RE_HCI_EVT = re.compile(r"> HCI Event: ([^(]+)")
RE_HCI_CMD = re.compile(r"< HCI Command: ([^(]+)")
RE_ACL_DATA = re.compile(r"(>|<) ACL Data TX|ACL Data RX")
RE_HANDLE = re.compile(r"Handle: 0x([0-9a-fA-F]+)")
RE_VALUE = re.compile(r"Value: ([0-9a-fA-F ]+)")
RE_UUID = re.compile(r"UUID: ([0-9a-fA-F-]+)")
RE_RSSI = re.compile(r"RSSI: (-?\d+)")
RE_ADDRESS = re.compile(r"Address: ([0-9A-F:]+)")

# Типы GATT-операций
GATT_OPS = {
    "read_req": "Read Request",
    "read_rsp": "Read Response",
    "write_req": "Write Request",
    "write_cmd": "Write Command",
    "notify": "Notification",
    "indicate": "Indication",
    "mtu": "MTU Exchange",
}


def parse_hex_value(text: str) -> str:
    """Извлекает hex-значение из текста и форматирует."""
    match = RE_VALUE.search(text)
    if match:
        return match.group(1).strip().replace(" ", "")
    return ""


def parse_btmon_line(line: str, state: dict) -> Optional[dict]:
    """Парсит одну строку btmon и возвращает событие, если найдено."""
    event: Optional[dict] = None

    # HCI событие
    m = RE_HCI_EVT.search(line)
    if m:
        state["current_hci_evt"] = m.group(1).strip()
        event = {"type": "hci_event", "name": state["current_hci_evt"]}

    # HCI команда
    m = RE_HCI_CMD.search(line)
    if m:
        state["current_hci_cmd"] = m.group(1).strip()
        event = {"type": "hci_cmd", "name": state["current_hci_cmd"]}

    # MTU
    m = RE_MTU.search(line)
    if m:
        event = {"type": "mtu", "direction": m.group(1), "size": int(m.group(2))}

    # Read Request
    if "Read Request" in line:
        m = RE_HANDLE.search(line)
        handle = f"0x{m.group(1).lower()}" if m else ""
        event = {"type": "read_req", "handle": handle}

    # Read Response
    if "Read Response" in line:
        val = parse_hex_value(line)
        event = {"type": "read_rsp", "value": val} if val else {"type": "read_rsp"}

    # Write Request
    if "Write Request" in line:
        m = RE_HANDLE.search(line)
        handle = f"0x{m.group(1).lower()}" if m else ""
        event = {"type": "write_req", "handle": handle}

    # Write Command
    if "Write Command" in line:
        m = RE_HANDLE.search(line)
        handle = f"0x{m.group(1).lower()}" if m else ""
        event = {"type": "write_cmd", "handle": handle}

    # Notification
    if "Handle Value Notification" in line or "Notification" in line:
        m = RE_HANDLE.search(line)
        handle = f"0x{m.group(1).lower()}" if m else ""
        event = {"type": "notify", "handle": handle}

    # Indication
    if "Handle Value Indication" in line or "Indication" in line:
        m = RE_HANDLE.search(line)
        handle = f"0x{m.group(1).lower()}" if m else ""
        event = {"type": "indicate", "handle": handle}

    # Handle в ACL данных
    m = RE_HANDLE.search(line)
    if m and event is None:
        val = parse_hex_value(line)
        event = {"type": "acl_data", "handle": f"0x{m.group(1).lower()}", "value": val}

    return event


def parse_btmon_log(text: str) -> list[dict]:
    """Парсит полный лог btmon и возвращает список событий."""
    events: list[dict] = []
    state: dict = {
        "current_hci_evt": None,
        "current_hci_cmd": None,
        "line_number": 0,
    }

    for line in text.splitlines():
        state["line_number"] += 1
        line_stripped = line.strip()

        if not line_stripped:
            continue

        # Пропорциональный timestamp
        ts_match = RE_TIMESTAMP.search(line_stripped)

        # Парсим GATT/HCI событие
        evt = parse_btmon_line(line_stripped, state)
        if evt:
            evt["line"] = state["line_number"]
            evt["raw"] = line_stripped[:120]
            if ts_match:
                evt["time"] = ts_match.group(1)
            events.append(evt)

    return events


def analyze_gatt_operations(events: list[dict]) -> dict:
    """Анализирует GATT-операции и группирует по типам."""
    stats: dict = defaultdict(int)
    handles: dict = defaultdict(list)
    operations: dict = defaultdict(list)

    for evt in events:
        t = evt["type"]
        stats[t] += 1

        if "handle" in evt:
            handles[evt["handle"]].append(t)

        # Группируем GATT-операции
        if t in GATT_OPS:
            operations[t].append({
                "handle": evt.get("handle"),
                "value": evt.get("value"),
                "line": evt.get("line"),
            })

    return {
        "total_events": len(events),
        "statistics": dict(stats),
        "gatt_operations": dict(operations),
        "handle_usage": {h: list(set(ops)) for h, ops in handles.items()},
    }


def print_summary(events: list[dict], analysis: dict) -> None:
    """Выводит сводку по GATT-операциям."""
    log.info(f"\n{'=' * 60}")
    log.info(f"BTMON Analysis Report")
    log.info(f"{'=' * 60}")
    log.info(f"Всего событий: {analysis['total_events']}")
    log.info(f"")

    log.info(f"{'Тип события':25s} {'Количество':10s}")
    log.info("-" * 35)
    for evt_type, count in sorted(analysis["statistics"].items(), key=lambda x: -x[1])[:20]:
        log.info(f"{evt_type:25s} {count:10d}")

    log.info(f"")
    log.info(f"GATT-операции:")
    for op_type, op_name in GATT_OPS.items():
        ops = analysis["gatt_operations"].get(op_type, [])
        if ops:
            log.info(f"  {op_name}: {len(ops)}")
            for op in ops[:5]:
                h = op.get("handle", "?")
                v = op.get("value", "")
                if v:
                    log.info(f"    Handle: {h} Value: {v[:48]}")
                else:
                    log.info(f"    Handle: {h}")

    log.info(f"")
    log.info(f"Используемые Handle-ы: {len(analysis['handle_usage'])}")
    for handle, ops in sorted(analysis["handle_usage"].items()):
        log.info(f"  Handle {handle}: {', '.join(ops)}")


def main():
    parser = argparse.ArgumentParser(
        description="Парсер btmon логов — извлечение GATT-операций",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Примеры:
  python3 btmon-parse.py capture.log
  python3 btmon-parse.py capture.log --format json --output gatt.json
  btmon | python3 btmon-parse.py --stdin
  python3 btmon-parse.py --format summary capture.log
        """,
    )
    parser.add_argument("input", nargs="?", help="Файл с логом btmon (или --stdin)")
    parser.add_argument("--stdin", action="store_true", help="Чтение из STDIN")
    parser.add_argument("--format", "-f", choices=["text", "json", "summary"], default="summary",
                        help="Формат вывода (по умолч. summary)")
    parser.add_argument("--output", "-o", help="Файл для сохранения результатов")
    parser.add_argument("--filter", help="Фильтр по типу событий (gatt, hci, acl, mtu)")

    args = parser.parse_args()

    # Чтение ввода
    text = ""
    if args.stdin or (not args.input and not sys.stdin.isatty()):
        log.info("Чтение из STDIN...")
        text = sys.stdin.read()
    elif args.input:
        with open(args.input, "r") as f:
            text = f.read()
    else:
        parser.print_help()
        sys.exit(1)

    if not text.strip():
        log.error("Пустой ввод")
        sys.exit(1)

    # Парсинг
    events = parse_btmon_log(text)

    # Фильтр
    if args.filter:
        type_filter = {
            "gatt": ["read_req", "read_rsp", "write_req", "write_cmd", "notify", "indicate", "mtu"],
            "hci": ["hci_event", "hci_cmd"],
            "acl": ["acl_data"],
            "mtu": ["mtu"],
        }.get(args.filter, [])
        events = [e for e in events if e["type"] in type_filter]
        log.info(f"Фильтр '{args.filter}': {len(events)} событий")

    log.info(f"Обработано событий: {len(events)}")

    # Анализ
    analysis = analyze_gatt_operations(events)

    # Вывод
    result = {
        "events": events,
        "analysis": analysis,
    }

    if args.format == "json":
        output = json.dumps(result, indent=2, ensure_ascii=False, default=str)
        if args.output:
            with open(args.output, "w") as f:
                f.write(output)
            log.info(f"JSON сохранён: {args.output}")
        else:
            print(output)
    elif args.format == "summary":
        print_summary(events, analysis)
        if args.output:
            with open(args.output, "w") as f:
                json.dump(result, f, indent=2, ensure_ascii=False, default=str)
            log.info(f"Результаты сохранены: {args.output}")
    else:
        # text — просто список событий
        for evt in events:
            t = evt.get("time", "")
            etype = evt["type"]
            handle = evt.get("handle", "")
            val = evt.get("value", "")
            name = evt.get("name", "")
            line_info = f" [{t}]" if t else ""
            if name:
                print(f"{evt['line']:6d}{line_info} {etype:15s} {name}")
            elif handle:
                v = f" = {val[:32]}" if val else ""
                print(f"{evt['line']:6d}{line_info} {etype:15s} {handle}{v}")
            else:
                print(f"{evt['line']:6d}{line_info} {etype:15s}")


if __name__ == "__main__":
    main()

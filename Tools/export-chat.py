#!/usr/bin/env python3
"""Esporta una sessione di Cline in Markdown leggibile.

Le sessioni sono salvate da Cline in ~/.cline/data/sessions/<id>/<id>.messages.json.
Il file serve a due scopi:

* conservare lo storico di una conversazione in forma consultabile e versionabile;
* fornire il contesto all'AI di Cursor, che non sa importare conversazioni altrui.

Uso:
    python3 Tools/export-chat.py <session-id> [-o output.md] [--thinking] [--tool-output]

Con l'id si ricava il percorso; con --latest si esporta la sessione più recente.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys

SESSIONS_DIR = os.path.expanduser("~/.cline/data/sessions")

# Il testo dell'utente arriva incapsulato in un tag con la modalità della richiesta.
USER_INPUT_RE = re.compile(r"^<user_input[^>]*>(.*)</user_input>\s*$", re.S)


def sessions() -> list[tuple[float, str]]:
    """Elenco delle sessioni presenti, dalla più vecchia alla più recente."""
    found = []
    for name in os.listdir(SESSIONS_DIR) if os.path.isdir(SESSIONS_DIR) else []:
        path = os.path.join(SESSIONS_DIR, name, f"{name}.messages.json")
        if os.path.isfile(path):
            found.append((os.path.getmtime(path), name))
    return sorted(found)


def resolve(which: str) -> str:
    if which == "--latest":
        found = sessions()
        if not found:
            sys.exit("nessuna sessione trovata in ~/.cline/data/sessions")
        return os.path.join(SESSIONS_DIR, found[-1][1], f"{found[-1][1]}.messages.json")
    direct = which if which.endswith(".json") else os.path.join(
        SESSIONS_DIR, which, f"{which}.messages.json")
    if os.path.isfile(direct):
        return direct
    sys.exit(f"sessione non trovata: {direct}")


def ts_label(value) -> str:
    if not value:
        return ""
    try:
        stamp = dt.datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        return stamp.astimezone().strftime("%d/%m %H:%M")
    except ValueError:
        return ""


def tool_hint(block: dict) -> str:
    """Riga sintetica per uno strumento: nome più il parametro più indicativo."""
    name = block.get("name", "?")
    hint = block.get("input", {})
    if not isinstance(hint, dict):
        return f"`{name}`"
    for key in ("command", "commands", "path", "relative_path", "url", "query"):
        value = hint.get(key)
        if value in (None, "", []):
            continue
        if isinstance(value, (list, tuple)):
            value = value[0] if value else ""
        return f"`{name}` → {str(value)[:90]}"
    return f"`{name}`"


def render(data: dict, with_thinking: bool, with_tool_output: bool) -> str:
    """Trasforma i messaggi in Markdown: testo per l'utente e l'assistente,
    strumenti in un blocco richiudibile, riflessioni interne solo se richiesto."""
    out: list[str] = []
    messages = data.get("messages", [])
    out.append(f"# Storico chat Cline — sessione `{data.get('sessionId', '?')}`\n")
    out.append(f"- Aggiornato: {data.get('updated_at', 'n.d.')}\n")
    out.append(f"- Messaggi: {len(messages)}\n")
    out.append(f"- Origine: {json.dumps(data.get('origin', {}), ensure_ascii=False)[:160]}\n")
    out.append("\n> Generato con `Tools/export-chat.py`: riflessioni interne e output degli "
               "strumenti sono omessi salvo diversa indicazione.\n")

    for msg in messages:
        role = msg.get("role", "?")
        content = msg.get("content")
        if isinstance(content, str):
            content = [{"type": "text", "text": content}]

        body: list[str] = []
        tools: list[str] = []
        for block in content or []:
            if not isinstance(block, dict):
                continue
            kind = block.get("type")
            if kind == "text":
                text = (block.get("text") or "").strip()
                if role == "user":
                    match = USER_INPUT_RE.match(text)
                    if match:
                        text = match.group(1).strip()
                if text:
                    body.append(text)
            elif kind == "thinking" and with_thinking:
                text = (block.get("thinking") or "").strip()
                if text:
                    body.append("> " + text.replace("\n", "\n> "))
            elif kind == "tool_use":
                tools.append(tool_hint(block))
            elif kind == "tool_result" and with_tool_output:
                text = json.dumps(block.get("content"), ensure_ascii=False)[:400]
                if text:
                    body.append("```\n" + text + "\n```")

        if not body and not tools:
            continue
        label = "Tu" if role == "user" else "Assistente"
        when = ts_label(msg.get("ts"))
        out.append(f"\n---\n\n### {label}" + (f" · {when}" if when else "") + "\n")
        if body:
            out.append("\n\n".join(body) + "\n")
        if tools:
            out.append("\n<details><summary>Strumenti usati</summary>\n")
            out.append("\n".join(f"- {t}" for t in tools) + "\n")
            out.append("</details>\n")
    return "".join(out)


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("session", help="id della sessione, percorso del .json, oppure --latest")
    ap.add_argument("-o", "--output", help="file di destinazione (default: stdout)")
    ap.add_argument("--thinking", action="store_true", help="include le riflessioni interne")
    ap.add_argument("--tool-output", action="store_true", help="include l'output degli strumenti")
    args = ap.parse_args()

    with open(resolve(args.session), encoding="utf-8") as handle:
        data = json.load(handle)
    text = render(data, args.thinking, args.tool_output)

    if args.output:
        os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
        with open(args.output, "w", encoding="utf-8") as handle:
            handle.write(text)
        print(f"scritto {args.output} ({len(text)} caratteri, {len(data['messages'])} messaggi)")
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())

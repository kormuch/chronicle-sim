#!/usr/bin/env python3
"""
Chronicle Sim — History Graph Generator
Reads savegame.json and outputs a Mermaid flowchart of the played history.

Usage:
    python chronicle_graph.py                     # reads default save location
    python chronicle_graph.py path/to/savegame.json
    python chronicle_graph.py > history.md        # pipe to file for Obsidian/GitHub

Render in:
    - Obsidian (Mermaid plugin, built-in in newer versions)
    - GitHub (paste into any .md file)
    - https://mermaid.live (paste & preview instantly)
"""

import json
import os
import sys


def default_save_path() -> str:
    appdata = os.environ.get("APPDATA", "")
    return os.path.join(appdata, "Godot", "app_userdata", "Chronicle Sim", "savegame.json")


def node_style(delta: dict) -> str:
    alignment = int(delta.get("alignment", 0))
    if alignment > 0:
        return "fill:#2d6a3f,color:#fff,stroke:#1a3d24"
    elif alignment < 0:
        return "fill:#7a2020,color:#fff,stroke:#3d0a0a"
    elif delta.get("flag"):
        return "fill:#1a3a5c,color:#fff,stroke:#0a1f33"
    return "fill:#333,color:#ccc,stroke:#555"


def season_label(season: int) -> str:
    names = ["Spr", "Sum", "Aut", "Win"]
    if 1 <= season <= 4:
        return names[season - 1]
    return ""


SKIP_EVENT_IDS = {
    "gen_new_game_choice", "gen_choose_location", "gen_choose_trade",
    "chieftain_marriage", "chieftain_heir", "village_naming", "village_named",
    "resume", "pool_empty",
}


def truncate(text: str, max_len: int = 45) -> str:
    text = text.replace('"', "'").replace("\n", " ")
    return text[:max_len] + "…" if len(text) > max_len else text


def build_mermaid(save: dict) -> str:
    chronicle = save.get("chronicle_log", [])
    gs = save.get("game_state", {})
    settlement = gs.get("settlement", {})
    name = settlement.get("name", "—")
    gen = gs.get("generation", 1)
    year = gs.get("year", 1)
    alignment = gs.get("alignment", 0)

    lines = [
        "```mermaid",
        "flowchart TD",
        f'    header["Chronicle: {name} · Gen {gen} · Year {year} · Alignment {alignment:+d}"]',
        "    style header fill:#1a1a2e,color:#9999cc,stroke:#333",
        "",
    ]

    prev_id = "header"
    node_count = 0

    for i, entry in enumerate(chronicle):
        eid = str(entry.get("event_id", ""))

        if eid.startswith("gen_") and eid != "settlement_generated":
            continue
        if eid in SKIP_EVENT_IDS:
            continue

        desc = truncate(str(entry.get("description", eid)))
        year_e = entry.get("year", "?")
        season = int(entry.get("season", 0))
        delta = entry.get("delta", {})
        gen_e = entry.get("generation", 1)

        season_str = f" {season_label(season)}" if season else ""
        align_tag = ""
        if int(delta.get("alignment", 0)) != 0:
            align_tag = f" ({int(delta['alignment']):+d})"
        flag_tag = f" [flag:{delta['flag']}]" if delta.get("flag") else ""

        node_id = f"n{node_count}"
        node_count += 1
        label = f"G{gen_e}·Y{year_e}{season_str}: {desc}{align_tag}{flag_tag}"

        lines.append(f'    {node_id}["{label}"]')
        lines.append(f"    style {node_id} {node_style(delta)}")
        lines.append(f"    {prev_id} --> {node_id}")
        lines.append("")

        prev_id = node_id

    lines.append("```")
    return "\n".join(lines)


def main():
    save_path = sys.argv[1] if len(sys.argv) > 1 else default_save_path()

    if not os.path.exists(save_path):
        print(f"# Error: Save file not found\n\nLooked at: `{save_path}`", file=sys.stderr)
        print(f"Usage: python chronicle_graph.py [path/to/savegame.json]", file=sys.stderr)
        sys.exit(1)

    with open(save_path, encoding="utf-8") as f:
        save = json.load(f)

    print(build_mermaid(save))


if __name__ == "__main__":
    main()

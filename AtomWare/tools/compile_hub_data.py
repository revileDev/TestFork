#!/usr/bin/env python3
r"""
AtomWare Giant Hub Compiler
Parses all 418 game txt files from C:\Users\Revil\Documents\New folder
and compiles them into an optimized Lua database: hub/games_database.lua
"""

import os
import re
import glob

SOURCE_DIR = r"C:\Users\Revil\Documents\New folder"

_parent = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if os.path.exists(os.path.join(_parent, "init.lua")):
    OUTPUT_FILE = os.path.join(_parent, "games_database.lua")
else:
    OUTPUT_FILE = os.path.join(_parent, "hub", "games_database.lua")

def escape_lua_string(s: str) -> str:
    """Escapes string safely for Lua double-quoted literal."""
    return s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '')

def main():
    files = glob.glob(os.path.join(SOURCE_DIR, "*.txt"))
    print(f"Compiling from {len(files)} game files in: {SOURCE_DIR}")

    games = []
    seen_ids = set()

    for fpath in files:
        with open(fpath, "r", encoding="utf-8", errors="replace") as fh:
            content = fh.read()

        m_game = re.search(r"# Game:\s*(.+)", content)
        m_pid = re.search(r"# Place(?:/Game)? ID:\s*(\d+)", content)
        m_load = re.search(r"Loadstring:\s*\n([^\n]+)", content)
        m_title = re.search(r"Title:\s*(.+)", content)

        if m_game and m_pid and m_load:
            game_name = m_game.group(1).strip()
            place_id = int(m_pid.group(1).strip())
            loadstring = m_load.group(1).strip()
            title = m_title.group(1).strip() if m_title else "Script"

            if place_id in seen_ids:
                continue
            seen_ids.add(place_id)

            games.append({
                "place_id": place_id,
                "name": game_name,
                "title": title,
                "loadstring": loadstring
            })

    # Sort games alphabetically by name
    games.sort(key=lambda x: x["name"].lower())
    print(f"Successfully processed {len(games)} unique games.")

    # Generate Lua Code
    lines = [
        "--[[",
        "    AtomWare Universal Script Hub - Games Database",
        f"    Compiled: {len(games)} Supported Roblox Games",
        "    Generated automatically by compile_hub_data.py",
        "--]]",
        "",
        "local GamesDatabase = {}",
        "GamesDatabase.ByPlaceId = {}",
        "GamesDatabase.List = {}",
        "",
        "local function addGame(placeId, name, title, loadstring)",
        "    local entry = {",
        "        PlaceId = placeId,",
        "        Name = name,",
        "        Title = title,",
        "        Loadstring = loadstring",
        "    }",
        "    GamesDatabase.ByPlaceId[placeId] = entry",
        "    table.insert(GamesDatabase.List, entry)",
        "end",
        "",
    ]

    for g in games:
        pid = g["place_id"]
        name_esc = escape_lua_string(g["name"])
        title_esc = escape_lua_string(g["title"])
        load_esc = escape_lua_string(g["loadstring"])

        lines.append(f'addGame({pid}, "{name_esc}", "{title_esc}", "{load_esc}")')

    # Add helper search and query methods
    lines.extend([
        "--// Helper Methods",
        "function GamesDatabase:GetAll()",
        "    return self.List",
        "end",
        "",
        "function GamesDatabase:GetByPlaceId(placeId)",
        "    local id = tonumber(placeId)",
        "    if not id then return nil end",
        "    return self.ByPlaceId[id]",
        "end",
        "",
        "function GamesDatabase:Search(query, limit)",
        "    limit = limit or 50",
        "    local q = tostring(query or ''):lower():gsub('^%s*(.-)%s*$', '%1')",
        "    local results = {}",
        "    if q == '' then",
        "        for i = 1, math.min(#self.List, limit) do",
        "            table.insert(results, self.List[i])",
        "        end",
        "        return results",
        "    end",
        "",
        "    -- Direct Place ID match priority",
        "    local numQ = tonumber(q)",
        "    if numQ and self.ByPlaceId[numQ] then",
        "        table.insert(results, self.ByPlaceId[numQ])",
        "    end",
        "",
        "    -- Name search",
        "    for _, gameData in ipairs(self.List) do",
        "        if #results >= limit then break end",
        "        if gameData.PlaceId ~= numQ then",
        "            if gameData.Name:lower():find(q, 1, true) or tostring(gameData.PlaceId):find(q, 1, true) then",
        "                table.insert(results, gameData)",
        "            end",
        "        end",
        "    end",
        "    return results",
        "end",
        "",
        "return GamesDatabase"
    ])

    with open(OUTPUT_FILE, "w", encoding="utf-8") as out:
        out.write("\n".join(lines))

    print(f"Generated {OUTPUT_FILE} ({os.path.getsize(OUTPUT_FILE)} bytes).")

if __name__ == "__main__":
    main()

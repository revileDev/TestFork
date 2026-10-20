"""
AtomWare Giant Script Hub - Bundle Compiler
Combines all modules and database into a single standalone .lua file
"""

import os
from datetime import datetime, timezone

# Locate HUB_DIR whether tools/ is inside AtomWare/ or sibling to hub/
_parent = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if os.path.exists(os.path.join(_parent, "games_database.lua")):
    HUB_DIR = _parent
else:
    HUB_DIR = os.path.join(_parent, "hub")

OUTPUT_FILE = os.path.join(HUB_DIR, "build", "atomware_hub.bundle.lua")

def read_module(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def bundle():
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    
    db_code = read_module(os.path.join(HUB_DIR, "games_database.lua"))
    notif_code = read_module(os.path.join(HUB_DIR, "modules", "notification.lua"))
    telemetry_code = read_module(os.path.join(HUB_DIR, "modules", "telemetry.lua"))
    auth_code = read_module(os.path.join(HUB_DIR, "modules", "auth_prompt.lua"))
    search_code = read_module(os.path.join(HUB_DIR, "modules", "search_widget.lua"))
    watermark_code = read_module(os.path.join(HUB_DIR, "modules", "watermark.lua"))
    init_code = read_module(os.path.join(HUB_DIR, "init.lua"))

    bundle_header = f"""--[[
======================================================================
     ATOMWARE UNIVERSAL GAME HUB (407+ ROBLOX GAMES SUPPORTED)
======================================================================
  * Key: THEBESTFIXED
  * Discord: https://discord.gg/AeCYnnQmq5
  * Compiled At: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S UTC')}
  * Features:
    - Auto Game Detection (407+ Place IDs)
    - Key Auth Prompt Modal with Discord Clipboard Integration
    - Discord Telemetry & Execution Audit Logger
    - Floating Draggable 🔍 Search & Gamehop Engine
    - Bottom-Right Live Watermark & Real-Time FPS Monitor
    - Cross-Platform UI (PC & Mobile Touch Responsive)
======================================================================
]]

"""

    bundle_content = bundle_header + f"""
do
    -- [MODULE 1: Games Database]
    local GamesDatabase = (function()
{indent(db_code, "        ")}
    end)()

    -- [MODULE 2: Toast Notification Engine]
    local Notification = (function()
{indent(notif_code, "        ")}
    end)()

    -- [MODULE 3: Discord Telemetry Logger]
    local Telemetry = (function()
{indent(telemetry_code, "        ")}
    end)()

    -- [MODULE 4: Key Authentication Modal]
    local AuthPrompt = (function()
{indent(auth_code, "        ")}
    end)()

    -- [MODULE 5: Floating Draggable Search & Gamehop Widget]
    local SearchWidget = (function()
{indent(search_code, "        ")}
    end)()

    -- [MODULE 6: Persistent Watermark & Live FPS Counter]
    local Watermark = (function()
{indent(watermark_code, "        ")}
    end)()

    -- [MODULE 7: Main Entry Orchestrator]
    local runAtomwareHub = (function()
{indent(init_code, "        ")}
    end)()

    -- Initialize and start AtomWare Hub
    runAtomwareHub(GamesDatabase, Notification, Telemetry, AuthPrompt, SearchWidget, Watermark)
end
"""

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write(bundle_content)

    file_size_kb = os.path.getsize(OUTPUT_FILE) / 1024
    print(f"[OK] Successfully built standalone bundle: {OUTPUT_FILE} ({file_size_kb:.2f} KB)")

def indent(code, prefix):
    return "\n".join(prefix + line if line.strip() else "" for line in code.splitlines())

if __name__ == "__main__":
    bundle()

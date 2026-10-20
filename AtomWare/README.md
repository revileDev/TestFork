# AtomWare Universal Script Hub (407+ Games)

AtomWare is a high-performance, cross-platform (PC & Mobile) Roblox script hub supporting 407+ games with automatic place detection, key verification, game hopping, and live telemetry.

---

## 📁 Project Structure

```text
hub/
├── build/
│   └── atomware_hub.bundle.lua  # Ready-to-execute single-file standalone bundle (239 KB)
├── modules/
│   ├── auth_prompt.lua          # Key modal (Key: THEBESTFIXED) & Discord clipboard
│   ├── notification.lua         # In-game animated toast notifications
│   ├── search_widget.lua        # Floating draggable 🔍 search & gamehop engine
│   ├── telemetry.lua            # Discord webhook audit logger
│   └── watermark.lua            # Bottom-right live FPS monitor & watermark
├── games_database.lua           # 407 compiled games database
├── init.lua                     # Core orchestrator
└── README.md                    # Documentation
```

---

## 🚀 How to Execute AtomWare

### Option 1: Standalone Single-File Bundle (Recommended)
You can directly load the bundled script in any executor (Delta, Fluxus, Codex, Arceus, Synapse, Krnl, Wave, etc.):

```lua
-- If hosting on GitHub / Pastebin / Web server:
loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/AtomWare/main/hub/build/atomware_hub.bundle.lua"))()
```

Or copy-paste the entire contents of `hub/build/atomware_hub.bundle.lua` directly into your executor's script tab.

---

## 🔑 Authentication Key & Discord Link
- **Master Key:** `THEBESTFIXED`
- **Discord Community:** `https://discord.gg/AeCYnnQmq5` (Clicking "Join Discord" automatically copies this link to the clipboard)

---

## 🛠️ Rebuilding or Updating Games
If new games or scripts are added to `C:\Users\Revil\Documents\New folder`, run:

```bash
# 1. Recompile game database
python tools/compile_hub_data.py

# 2. Rebuild the standalone bundle
python tools/bundle_hub.py
```

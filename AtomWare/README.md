# AtomWare Universal Script Hub (407+ Games)

AtomWare is a high-performance, cross-platform (PC & Mobile) Roblox script hub supporting 407+ games with automatic place detection, key verification, game hopping, and live telemetry.

---

## 🚀 How to Execute AtomWare

### Primary Entry Point (Direct from `init.lua`):
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/revileDev/TestFork/main/AtomWare/init.lua"))()
```

### Alternative Bundle Link:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/revileDev/TestFork/main/AtomWare/build/atomware_hub.bundle.lua"))()
```

---

## 📁 Project Structure

```text
AtomWare/
├── init.lua                     # Primary executable entry point (Self-contained, 239 KB)
├── games_database.lua           # 407 compiled games database
├── README.md                    # Documentation & setup guide
├── build/
│   └── atomware_hub.bundle.lua  # Bundle distribution copy
├── modules/
│   ├── orchestrator.lua         # Core orchestrator logic
│   ├── auth_prompt.lua          # Key modal (Key: THEBESTFIXED) & Discord clipboard
│   ├── notification.lua         # In-game animated toast notifications
│   ├── search_widget.lua        # Floating draggable 🔍 search & gamehop engine
│   ├── telemetry.lua            # Discord webhook audit logger
│   └── watermark.lua            # Bottom-right live FPS monitor & watermark
└── tools/
    ├── bundle_hub.py            # Bundler script
    └── compile_hub_data.py      # Database compiler script
```

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

# 2. Rebuild the standalone executable init.lua and bundle
python tools/bundle_hub.py
```

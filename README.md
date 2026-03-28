# MythicLootMap

Browse all Mythic+ dungeon loot in one window. Filter by slot, armor type, dungeon, stats, and spec.

Stop alt-tabbing to Wowhead. Stop clicking through the Adventure Journal dungeon by dungeon. MythicLootMap puts everything in one place so you can plan your gear efficiently.

## Features

- **All M+ Loot in One Window** — Automatically loads every equipment drop from all current season Mythic+ dungeons via the in-game Encounter Journal API. No hardcoded data, updates every season automatically.

- **Powerful Filters** — Narrow down exactly what you need:
  - **Slot** — Head, Chest, Weapon, Ring, Trinket, etc.
  - **Armor Type** — Cloth, Leather, Mail, Plate
  - **Dungeon** — Filter to a specific dungeon
  - **Stats** — Two independent stat filters (Crit, Haste, Mastery, Versatility). Find that perfect Crit/Haste ring instantly.
  - **My Spec** — Toggle to show only items usable by your current specialization

- **Item Comparison** — Shows ilvl delta (+/-) relative to your currently equipped gear. Handles multi-slot items (rings, trinkets) and 2-hand vs 1-hand weapons correctly.

- **Secondary Stats at a Glance** — Each item shows which secondary stats it has (e.g. "Crit / Haste") right in the list, no tooltip hovering needed.

- **Shift-Click to Link** — Shift-click any item to link it in chat.

- **Minimap Button** — Draggable minimap icon to toggle the window. Or use `/mlm`.

- **Multi-Language** — Supports English, Simplified Chinese, and Traditional Chinese.

- **Zero Dependencies** — No libraries required. Pure lightweight addon.

## Installation

1. Download the latest release from [CurseForge](https://www.curseforge.com/wow/addons/mythiclootmap) or [GitHub Releases](https://github.com/rhoninl/MythicLootMap/releases).
2. Extract the `MythicLootMap` folder into your `World of Warcraft/_retail_/Interface/AddOns/` directory.
3. Restart WoW or type `/reload` in-game.

## Usage

| Command | Description |
|---|---|
| `/mlm` | Toggle the loot browser window |
| `/mlm reload` | Reload dungeon data |
| `/mlm help` | Show help |

`/equipmap` also works as an alias.

You can also click the minimap button to toggle the window.

## How It Works

MythicLootMap dynamically queries the WoW Encounter Journal API to load all dungeon loot for the current M+ season. It detects the active dungeon rotation via `C_ChallengeMode.GetMapTable()`, maps each dungeon to the Encounter Journal, and pulls all item data including secondary stats. Everything is loaded in-game — no external data files that go stale.

## Compatibility

- **WoW Retail 12.0+** (Midnight)
- Uses modern WoW 12.0 APIs (ScrollBox, DropdownButton, C_EncounterJournal)

## Project Structure

```
MythicLootMap/
├── Core.lua            # Initialization, events, slash commands, minimap button
├── Data.lua            # Dungeon/loot loading via Encounter Journal API
├── Filters.lua         # Filter logic and state management
├── Compare.lua         # Item comparison against equipped gear
├── Utils.lua           # Constants, slot mappings, localization helpers
├── Locales.lua         # Translations (enUS, zhCN, zhTW)
├── UI/
│   └── MainFrame.lua   # Main UI: filters, item list, settings panel
├── Tests/
│   ├── TestRunner.lua  # Test harness
│   ├── TestData.lua    # Data structure tests
│   ├── TestCompare.lua # Item comparison tests
│   └── TestFilters.lua # Filter logic tests
└── docs/
    └── design.md       # Architecture documentation
```

## Running Tests

In-game, type `/mlm test` to run the built-in test suite covering data structures, item comparison logic, and filter behavior.

## Feedback & Issues

Report bugs or request features at: [GitHub Issues](https://github.com/rhoninl/MythicLootMap/issues)

## License

MIT

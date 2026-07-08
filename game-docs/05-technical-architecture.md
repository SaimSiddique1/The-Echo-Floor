# 05 — Technical Architecture

## Overview

- **Engine**: Roblox (Luau)
- **Framework**: None — vanilla Luau with ModuleScripts
- **Network model**: Server-authoritative. All anomaly selection, timer, scoring, and elimination runs on the server.

## Data Model Hierarchy

```
game (DataModel)
├── Workspace
│   ├── Lobby (Model) — lobby area at Y = 1000
│   │   ├── Desk (Parts) — reception desk
│   │   ├── JeremyATS (Model) — shop NPC (Torso+Head+Arms+BillboardGui+ProximityPrompt)
│   │   ├── ElevatorBay (Model) — physical bay with countdown SurfaceGui
│   │   │   └── BayDetector (Part) — ProximityPrompt registration zone
│   │   ├── ShelvingUnits (Models) — flanking desk
│   │   ├── Sofas, Chandelier, RedRug — decor
│   │   ├── PrevGameBoard (SurfaceGui) — last game scores
│   │   ├── AllTimeBoard (SurfaceGui) — top 10 leaderboard
│   │   └── SpectatorSeating — elimination spectator area
│   ├── GameElevator (Model) — persistent elevator at Y = 0
│   │   ├── Walls, Floor, Ceiling (Parts)
│   │   ├── LeftDoor, RightDoor (Parts, Tweened)
│   │   ├── FloorDisplay (Part + SurfaceGui) — reveal screen
│   │   ├── PointLight
│   │   └── SpawnLocation
│   └── Floor (Folder) — cloned each round, destroyed after
│       ├── Wall_* (Parts)
│       ├── Floor_* (Parts)
│       ├── Ceiling_* (Parts)
│       ├── Light_* (Parts)
│       ├── Furniture (Models/Parts)
│       ├── Regions (Folder) — invisible room detection parts (6)
│       └── Anomaly (Folder) — replacement objects
│
├── ServerStorage
│   └── Templates
│       ├── Floor (Folder) — master floor template
│       └── GameElevator (Model) — backup elevator template
│
├── ReplicatedStorage
│   ├── Shared (ModuleScripts)
│   │   ├── AnomalySwapConfig (ModuleScript) — catalog (25 entries), swap coords, roomBounds, categories
│   │   ├── AnomalyBehavior (ModuleScript) — 15 behavior anomaly definitions
│   │   └── CosmeticConfig (ModuleScript) — 8 cosmetics with prices
│   ├── Remotes (Folder)
│   │   ├── LogGuess (RemoteEvent) — Client → Server
│   │   ├── RoundTimerTick (RemoteEvent) — Server → Client
│   │   ├── RoundStart (RemoteEvent) — Server → Client
│   │   ├── RoundEnd (RemoteEvent) — Server → Client
│   │   ├── RevealResults (RemoteEvent) — Server → Client
│   │   ├── FloorReset (RemoteEvent) — Server → Client
│   │   ├── RoundChatStart (RemoteEvent) — Server → Client (deprecated)
│   │   ├── LockInGuess (RemoteEvent) — Client → Server (deprecated)
│   │   ├── QueueUpdate (RemoteEvent) — Server → Client
│   │   ├── QueueExit (RemoteEvent) — Client → Server
│   │   ├── SpectateInfo (RemoteEvent) — Server → Client
│   │   ├── BuyCosmetic (RemoteEvent) — Client → Server
│   │   ├── EquipCosmetic (RemoteEvent) — Client → Server
│   │   ├── GetShopData (RemoteFunction) — Client → Server
│   │   ├── BuyEchoPing (RemoteEvent) — Client → Server
│   │   ├── UseEchoPing (RemoteFunction) — Client → Server
│   │   └── DevGrantCoins (RemoteEvent) — Client → Server
│   └── Tools (Folder) — generator scripts mapped from src/tools/
│
├── ServerScriptService
│   └── Core (Folder)
│       ├── MatchmakingService.server.luau (Script) — bay queue + countdown + teleport
│       ├── RoundRunner (ModuleScript) — endless-floor lifecycle + scoring + remote handlers
│       ├── FloorCloner (Script) — spawns floor template
│       ├── AnomalySwapper (Script) — picks + applies anomaly each floor
│       ├── LeaderboardService (ModuleScript) — stats, echoPings, DataStore
│       ├── LeaderboardDisplays (ModuleScript) — lobby SurfaceGui updates
│       ├── ShopHandler (ModuleScript) — BuyCosmetic, EquipCosmetic, GetShopData, BuyEchoPing
│       ├── ToolSetup (Script) — builds anomaly, No Anomaly, Echo Ping tools in StarterPack
│       └── GameState (ModuleScript) — shared game state
│
├── StarterGui
│   ├── TimerHUD.client.luau (LocalScript in ScreenGui) — timer, phase, minimap, coin HUD, highlightRoomOnMinimap global
│   ├── ToolManager.client.luau (LocalScript) — anomaly tool + room/type bars, mobile-safe
│   ├── ChatMenu.client.luau (LocalScript) — deprecated no-op
│   ├── ShopUI.client.luau (LocalScript in ScreenGui) — tabs (Cosmetics/Consumables), 2-column layout, live coins
│   └── EchoPingClient.client.luau (LocalScript) — Echo Ping tool UI, calls UseEchoPing + minimap highlight
│
├── StarterPack
│   └── Tools built by ToolSetup.server.luau:
│       ├── Anomaly Scanner (Tool) — with Handle, ScreenGlow, SensorTip, welded parts
│       ├── No Anomaly (Tool) — simple tool for NoAnomaly guess
│       └── Echo Ping (Tool) — with Handle, Body, Screen, Antenna, Tip, Ring (red neon accents)
│
└── Players
    └── [Player]
        └── leaderstats (Folder)
            ├── Coins (IntValue)
            ├── GameScore (IntValue)
            ├── Rounds (IntValue)
            └── EchoPings (IntValue)
```

## Service Map (Server-Side)

### MatchmakingService (Script)
- **Responsibility**: Monitors elevator bay ProximityPrompt, manages queue, countdown, teleport
- Calls `RoundRunner.Start(players)` when timer expires

### RoundRunner (ModuleScript)
- **Exports**: `Start(players)`
- Runs the full endless-floor lifecycle:
  1. Clone floor from ServerStorage.Templates.Floor
  2. Call AnomalySwapper to pick and apply anomaly
  3. Timer sequencing: Going Up → Explore (floor 0 only) → Search → Intermission → Reveal → Boarding
  4. Listen for LogGuess, UseEchoPing, DevGrantCoins remotes
  5. Scoring, elimination, coin rewards
- Dev timings: BAY_TIMER=5, GOING_UP=3, EXPLORE=10, SEARCH=15 flat, INTERMISSION=3, REVEAL=4, BOARDING=3

### FloorCloner (Script)
- Clones ServerStorage.Templates.Floor into Workspace
- Note: FloorGenerator saves to `Templates.MasterFloor.Floor` — mismatch exists

### AnomalySwapper (Script)
- Picks from combined pool (10 swap + 15 behavior anomalies)
- Applies/reverts each floor
- Tracks used anomalies per game session

### LeaderboardService (ModuleScript)
- Persistent stats (DataStore): points, correct, wrong, abstained, gamesPlayed, coins, ownedCosmetics, equippedCosmetic, echoPings
- Leaderstats: Coins, GameScore, Rounds, EchoPings
- Functions: addCoins, addEchoPings, useEchoPing, buyEchoPing, buyCosmetic, equipCosmetic
- Dev override: sets data.coins = 1000 on player join

### LeaderboardDisplays (ModuleScript)
- Updates PrevGameBoard and AllTimeBoard SurfaceGuis in lobby

### ShopHandler (ModuleScript)
- Handles BuyCosmetic, EquipCosmetic, BuyEchoPing
- GetShopData returns cosmetics list + owned + equipped + echoPings + coins

### ToolSetup (Script)
- Builds anomaly scanner tool + No Anomaly tool + Echo Ping tool
- Places them in StarterPack for mobile compatibility
- Each tool has welded parts, cosmetic color/material application

### GameState (ModuleScript)
- Shared state: gameInProgress, spectators, currentGamePlayers

## Remote Events (ReplicatedStorage)

| Remote Name | Type | Direction | Purpose |
|---|---|---|---|
| LogGuess | RemoteEvent | Client → Server | Submit room + category guess |
| RoundTimerTick | RemoteEvent | Server → Client | Sync remaining time + phase |
| RoundStart | RemoteEvent | Server → Client | Round begins |
| RoundEnd | RemoteEvent | Server → Client | Round ends |
| RevealResults | RemoteEvent | Server → Client | Correct/wrong + coins per player |
| FloorReset | RemoteEvent | Server → Client | Floor resetting |
| RoundChatStart | RemoteEvent | Server → Client | Deprecated (old chat phase) |
| LockInGuess | RemoteEvent | Client → Server | Deprecated (old chat phase) |
| QueueUpdate | RemoteEvent | Server → Client | Queue count updates |
| QueueExit | RemoteEvent | Client → Server | Leave queue |
| SpectateInfo | RemoteEvent | Server → Client | Spectator info |
| BuyCosmetic | RemoteEvent | Client → Server | Buy a cosmetic |
| EquipCosmetic | RemoteEvent | Client → Server | Equip a cosmetic |
| GetShopData | RemoteFunction | Client → Server | Fetch shop data + inventory |
| BuyEchoPing | RemoteEvent | Client → Server | Buy echo ping consumable |
| UseEchoPing | RemoteFunction | Client → Server | Use echo ping, returns { room, type } |
| DevGrantCoins | RemoteEvent | Client → Server | Dev tool: grant 1000 coins |

## Data Stores

- **PlayerStats** (DataStore): points, correct, wrong, abstained, gamesPlayed, coins, ownedCosmetics, equippedCosmetic, echoPings
- **Leaderboard** (OrderedDataStore): key=UserId, value=points

## Leaderboards

- **PrevGameBoard**: Last game's scores (SurfaceGui in lobby, AlwaysOnTop=true)
- **AllTimeBoard**: All-time top 10 (SurfaceGui in lobby, AlwaysOnTop=true)

## Mobile Support

- Tools placed in StarterPack (not dynamically built in LocalScripts)
- `IgnoreGuiInset = true` on guess GUI ScreenGuis
- Touch-friendly button sizes (120×44 minimum)
- Camera-center raycast for room detection (no mouse cursor)

## Minimap

- Static grid (rooms don't move/rotate), displayed in TimerHUD
- 90° CW rotated (world X → screen Y, world Z → screen X)
- Player dot moves based on world position
- Direction arrow rotates with player facing
- Frame: 205×115 desktop / 380×220 mobile (UIScale 0.35)
- Echo Ping highlights room cell with red pulsing border + glow for 5s

## Echo Ping Consumable

- Price: 35 coins (ECHO_PING_PRICE)
- UseEchoPing RemoteFunction: server validates search phase + anomaly exists + decrements pings
- Returns `{ room, type }` from catalog lookup
- Client calls `_G.highlightRoomOnMinimap(room)`
- 8s cooldown per use (client-side)

## Performance Considerations

- Floor is small (~200 parts total). Cloning is cheap.
- No AI, no pathfinding.
- Lobby and game floor are far apart (Y = 1000 vs Y = 0) — no overlap.
- One game floor at a time per bay.
- Destroy cloned floor immediately after round ends.

## Script Locations Summary

| Script | Location | Runs On |
|---|---|---|
| MatchmakingService | ServerScriptService.Core | Server |
| RoundRunner | ServerScriptService.Core | Server (Module) |
| FloorCloner | ServerScriptService.Core | Server |
| AnomalySwapper | ServerScriptService.Core | Server |
| LeaderboardService | ServerScriptService.Core | Server (Module) |
| LeaderboardDisplays | ServerScriptService.Core | Server (Module) |
| ShopHandler | ServerScriptService.Core | Server (Module) |
| ToolSetup | ServerScriptService.Core | Server |
| GameState | ServerScriptService.Core | Server (Module) |
| AnomalySwapConfig | ReplicatedStorage.Shared | Shared |
| AnomalyBehavior | ReplicatedStorage.Shared | Shared |
| CosmeticConfig | ReplicatedStorage.Shared | Shared |
| TimerHUD | StarterGui | Client |
| ToolManager | StarterGui | Client |
| ChatMenu | StarterGui | Client (deprecated) |
| ShopUI | StarterGui | Client |
| EchoPingClient | StarterGui | Client |

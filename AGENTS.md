# Project Context

## TheEchoFloor — Roblox Solo-Survival Game

### Architecture Overview
- **Lobby (Y=1000)** — hotel lobby with reception, Jeremy ATS NPC (shop), sofas, chandelier, leaderboard boards, elevator bay, spectator seating, shelving units flanking desk
- **Game Floor (Y=0)** — generated 6-room apartment (Hallway, ElevatorLobby, LivingRoom, Kitchen, Bedroom, Bathroom)
- **Elevator** — persistent model at (-46.1, 0, -9), never destroyed between rounds
- **Room + Category HUD** — equip anomaly tool → pick room (left bar, 5 rooms, no ElevatorLobby) + type (right bar, 6 types) → Lock In → server scores against catalog
- **Endless floors** — loop until all players eliminated. Each player has an individual run: wrong guess = out.

### Game Loop
1. **Lobby** — queue via ProximityPrompt on BayDetector (8 studs, no line-of-sight), 15s countdown (3s at 8/8)
2. **Going Up** (5s / Dev: 3s) — doors close, teleport to elevator, anomaly swapped at t=end, ding at t=1
3. **Explore** (60s / Dev: 10s) — **Floor 0 only**: arrive, doors open, players learn the environment. **No anomaly.** Tool does NOT show selection bars. Timer displays "Ground Floor".
4. **Search** (60s scales down per floor / Dev: flat 15s) — doors open, players equip scanner → selection bars appear. Pick room + type, press Lock In.
5. **Intermission** (5s / Dev: 3s) — teleport to elevator lobby, barrier blocks hallway. No discussion, no changing guesses. Wall shows pending status.
6. **Reveal** (8s / Dev: 4s) — wall screen shows per-player results, top-3 podium, anomaly highlight. **Wrong guess = elimination** (teleport to lobby spectator seating).
7. **Board** (5s / Dev: 3s) — doors open, elevator music, surviving players teleport inside
8. **Repeat** floors 1, 2, 3, ... N until 0 survivors
9. **Return to Lobby** — teleport back, update leaderboards

**Doors stay open** from after Explore through Boarding phase. They only close when the next Going Up sequence fires.

### Dev Timings
BAY_TIMER=5, GOING_UP=3, EXPLORE=10, SEARCH=15 (flat, no scaling), INTERMISSION=3, REVEAL=4, BOARDING=3

### Key Production Timings
EXPLORE=60, GOING_UP=5, SEARCH=60 (floor 1) → 50 (4-6) → 40 (7-9) → 35 (10+), INTERMISSION=5, REVEAL=8, BOARDING=5, BAY_TIMER=15, MAX_PLAYERS=8

### Score System (Per Floor)
| Condition | Points | Coins |
|---|---|---|
| Both region + category correct | 10 + speed bonus | 5 + bonus |
| Region correct only | 5 | 3 |
| Category correct only | 3 | 2 |
| Neither (wrong guess) | -3 | 1 |
| NoAnomaly (correctly) | +5 | 3 |
| Abstain | 0 | 0 |

Speed bonus: 1st=+5, 2nd=+3, 3rd=+1 (based on guess time within correct guessers). Bonus also applies coins.

### Endgame
- **Elimination**: wrong guess = immediately out. Teleport to lobby spectator seating.
- **Win condition**: be the last survivor standing. All others eliminated.
- **Leaderboard**: sorted by furthest floor reached, then total points tiebreak.

### Persistent State
- **Leaderstats** (auto-displayed top-right): Coins, GameScore (current game), Rounds, EchoPings
- **DataStore (PlayerStats)**: points, correct, wrong, abstained, gamesPlayed, coins, ownedCosmetics, equippedCosmetic, echoPings
- **OrderedDataStore (Leaderboard)**: key=UserId, value=points
- **Leaderboards in lobby**: "PrevGameBoard" (last game scores) and "AllTimeBoard" (all-time top 10), row-based SurfaceGui
- **Dev override**: PlayerAdded handler forces `data.coins = 1000` — every player starts with 1000 coins for testing

### Cosmetic System
- 8 cosmetics in CosmeticConfig.luau: Classic (free), Gold (100), Neon Blue/Red/Green/Purple (150 each), Ice (300), DiamondPlate (400)
- Shop accessed via **Jeremy ATS NPC** at reception desk (ProximityPrompt "Browse"), not back-left counter
- ShopUI has **tabs**: Cosmetics (left) + Consumables (right). Cosmetics show 2-column scrollable card grid with Buy/Equip/Equipped states. Consumables shows Echo Ping card (35 coins, Buy + quantity display). Live coin display from leaderstats.
- Tool has 8 welded parts; applyCosmeticToTool() sets color+material on structural parts (not SensorTip, ScreenGlow, grip accents)
- EquipCosmetic RemoteEvent on client re-fetches cosmetic and reapplies to tool

### Echo Ping Consumable
- One-use consumable item, costs 35 coins (ECHO_PING_PRICE)
- Purchased in ShopUI Consumables tab via BuyEchoPing RemoteEvent
- Used via equipped "Echo Ping" tool from hotbar (no minimap button)
- **Ping count** displayed in bottom-center UI when tool equipped + "USE" button
- On use: fires UseEchoPing RemoteFunction to server → server validates search phase + anomaly exists + decrements ping → returns anomaly `{ room, type }`
- Client calls `_G.highlightRoomOnMinimap(room)` — red pulsing border + glow on minimap room cell for 5s
- 8s cooldown between uses (client-side)
- Stored in leaderstats EchoPings IntValue, synced via DataStore

### Mobile Support
- Tools come from **StarterPack** (not dynamically built in LocalScript)
- `IgnoreGuiInset = true` on guess GUI
- Touch-friendly button sizes (120×44 minimum)
- Camera-center raycast for room detection (no mouse cursor)

---

# Region + Category Guessing System

### Summary
Two-dimensional guessing: **room region** (where) + **anomaly category** (what kind). Players manually pick a room from a left bar and a type from a right bar using their equipped anomaly tool. Partial credit for getting one of the two right. **No auto-detection** — players decide based on what they observe.

**5 guessable rooms** (ElevatorLobby excluded — it's the intermission holding area).

## Data Model

### AnomalySwapConfig.luau — Returns { swapConfig, catalog, roomBounds, categories }
```lua
return {
    swapConfig = { ... }  -- existing CFrame data for 10 swap targets
    catalog = {
        -- Swap anomalies
        ["Lamp"] = { region = "Bedroom", type = "Object" },
        ["Painting"] = { region = "Bedroom", type = "Object" },
        ["Bed"] = { region = "Bedroom", type = "Object" },
        ["Carpet"] = { region = "Bedroom", type = "Object" },
        ["Sofa"] = { region = "LivingRoom", type = "Object" },
        ["Bookshelf"] = { region = "LivingRoom", type = "Object" },
        ["Recliner Chair"] = { region = "LivingRoom", type = "Object" },
        ["Toilet"] = { region = "Bathroom", type = "Object" },
        ["Microwave"] = { region = "Kitchen", type = "Object" },
        ["Safety"] = { region = "Hallway", type = "Object" },
        -- Behavior anomalies (15 total)
        -- Lighting (5)
        ["LivingRoomStrobe"] = { region = "LivingRoom", type = "Lighting" },
        ["KitchenLights"] = { region = "Kitchen", type = "Lighting" },
        ["BedroomDim"] = { region = "Bedroom", type = "Lighting" },
        ["HallwayFlicker"] = { region = "Hallway", type = "Lighting" },
        ["BathroomBlackout"] = { region = "Bathroom", type = "Lighting" },
        -- Audio (5)
        ["LivingRoomHum"] = { region = "LivingRoom", type = "Audio" },
        ["KitchenDrip"] = { region = "Kitchen", type = "Audio" },
        ["BedroomWhisper"] = { region = "Bedroom", type = "Audio" },
        ["HallwayFootsteps"] = { region = "Hallway", type = "Audio" },
        ["BathroomEcho"] = { region = "Bathroom", type = "Audio" },
        -- Architecture (3)
        ["LivingRoomWallOpen"] = { region = "LivingRoom", type = "Architecture" },
        ["KitchenCounterRaise"] = { region = "Kitchen", type = "Architecture" },
        ["BathroomMirrorFog"] = { region = "Bathroom", type = "Architecture" },
        -- Paranormal/Reality (2)
        ["LivingRoomFloat"] = { region = "LivingRoom", type = "Reality" },
        ["BedroomPaintingEyes"] = { region = "Bedroom", type = "Reality" },
    },
    roomBounds = { ... },  -- Axis-aligned bounding boxes for each room
    categories = { "Object", "Lighting", "Architecture", "Audio", "Living", "Reality" },
}
```

Note: Carpet was fixed from Hallway → Bedroom. roomBounds are after centering offset.

### Anomaly Categories
- **Object** — item replaced/moved/changed (10 swap anomalies)
- **Lighting** — lights changed color, brightness, or position (5 behavior)
- **Audio** — ambient sounds changed or added (5 behavior, all 3D spatial)
- **Architecture** — walls, doors, windows altered (3 behavior)
- **Living** — plants, pets, living things altered (0 implemented yet)
- **Reality** — physics, gravity, time distortions (2 behavior)

### Behavior Anomaly Rules
- All are **deterministic** (no math.random) — consistent patterns so players learn them
- Audio anomalies use 3D spatial sound (EmitterSize=12, RollOffMaxDistance=30), anchored at room center, loop until reverted

## Regions Folder in Floor Model
FloorGenerator creates a `Regions` folder with 6 transparent non-collidable Parts, one per room at Y=0.5. Used by client for room detection.

## Client Guessing Flow

### Step 1: Equip Scanner
Tools are built by `ToolSetup.server.luau` into StarterPack. ToolManager finds them via `Backpack:WaitForChild`.

### Step 2: Tap with Tool
`ToolManager.client.luau` — `scanner.Activated` handler:
1. Get mouse target (desktop) or camera-center raycast (mobile)
2. `detectRegion(target, hitPoint)` — checks position against roomBounds or Floor.Regions parts
3. Returns room name

### Step 3: Show Category Picker
- Top: detected region name
- Middle: 6 category pills, tap to select (green border), Confirm button enables
- Bottom: Confirm + Cancel buttons
- On Confirm: fire `LogGuess({ region = regionName, category = selectedCategory })`

### Step 4: NoAnomaly Path
"No Anomaly" tool fires `LogGuess({ region = nil, category = nil })`.

### Hover Highlight
Camera-center highlight works on objects with `AnomalyTarget` attribute.

## Server Guess Handling

### LogGuess.OnServerEvent (RoundRunner.luau)
Parses `{ region: string?, category: string? }`. Partial credit scoring matrix.

## Intermission Phase
Teleport to elevator lobby, barrier up, 3s (dev) / 5s (prod) of tension. **No discussion, no changing guesses.** ChatMenu client script is deprecated to no-op.

## Reveal Phase
Wall screen shows anomaly name + region · type + per-player results. Coin rewards displayed on second line of each result box. Wrong guess = immediate elimination to lobby spectator seating.

---

# AnomalyBehavior System

## File: src/shared/AnomalyBehavior.luau
15 behavior anomalies across 4 categories:

### Lighting (5)
- **LivingRoomStrobe**: Strobe effect via alternating Tween on all PointLights in LivingRoom
- **KitchenLights**: All Kitcken PointLights turn red, brightness reduced
- **BedroomDim**: All PointLights in Bedroom dim to 0.1 (detected by position vs roomBounds)
- **HallwayFlicker**: Two hallway PointLights alternate on/off every 0.15s via RunService.Heartbeat
- **BathroomBlackout**: Bathroom PointLight disabled entirely

### Audio (5)
- **LivingRoomHum**: Low hum loop anchored at LivingRoom center (3D spatial)
- **KitchenDrip**: Drip sound anchored at Kitchen center (3D spatial)
- **BedroomWhisper**: Whisper loop anchored at Bedroom center (3D spatial)
- **HallwayFootsteps**: Footstep loop anchored at Hallway center (3D spatial)
- **BathroomEcho**: Echo sound anchored at Bathroom center (3D spatial)
All audio: Sound Group=SFX, Volume=0.5, EmitterSize=12, RollOffMaxDistance=30, Looping=true

### Architecture (3)
- **LivingRoomWallOpen**: One wall becomes 0.3 transparency (partial invisible)
- **KitchenCounterRaise**: Counter Part increases Y size by 2 studs
- **BathroomMirrorFog**: Mirror Part transparency increases to 0.4 (foggy)

### Reality (2)
- **LivingRoomFloat**: Furniture Part gains BodyPosition above floor, floats 5 studs up, bobs via RunService.Heartbeat
- **BedroomPaintingEyes**: Painting gets two small SphereParts (black pupils) that track nearest player via Heartbeat CFrame

---

# Remotes

All defined in `default.project.json` under ReplicatedStorage.Remotes:

| Name | Type | Direction | Purpose |
|---|---|---|---|
| LogGuess | RemoteEvent | Client → Server | Submit room + category guess |
| RoundTimerTick | RemoteEvent | Server → Client | Sync remaining time + phase |
| RoundStart | RemoteEvent | Server → Client | Round begins |
| RoundEnd | RemoteEvent | Server → Client | Round ends |
| RevealResults | RemoteEvent | Server → Client | Per-player results + coins |
| FloorReset | RemoteEvent | Server → Client | Floor resetting |
| RoundChatStart | RemoteEvent | Server → Client | Deprecated (kept for compat) |
| LockInGuess | RemoteEvent | Client → Server | Deprecated (kept for compat) |
| QueueUpdate | RemoteEvent | Server → Client | Queue count updates |
| QueueExit | RemoteEvent | Client → Server | Leave queue |
| SpectateInfo | RemoteEvent | Server → Client | Spectator updates |
| BuyCosmetic | RemoteEvent | Client → Server | Buy a cosmetic |
| EquipCosmetic | RemoteEvent | Client → Server | Equip a cosmetic |
| GetShopData | RemoteFunction | Client → Server | Fetch shop data + inventory |
| BuyEchoPing | RemoteEvent | Client → Server | Buy echo ping consumable |
| UseEchoPing | RemoteFunction | Client → Server | Use echo ping, returns { room, type } |
| DevGrantCoins | RemoteEvent | Client → Server | Dev tool: grant 1000 coins |

---

# Relevant Files

### Server
- `src/server/RoundRunner.luau` — endless loop, elimination, intermission, scoring, dev/prod timers, UseEchoPing handler, DevGrantCoins handler
- `src/server/AnomalySwapper.luau` — picks from combined swap+behavior pool, applies/reverts, tracks used
- `src/server/FloorCloner.luau` — clones Floor template (note: looks for Templates.Floor, mismatch with FloorGenerator's Templates.MasterFloor.Floor)
- `src/server/MatchmakingService.server.luau` — bay timer (5s dev), teleport, calls RoundRunner.Start
- `src/server/LeaderboardService.luau` — stats, echoPings field, ECHO_PING_PRICE=35, dev coins override (1000 on join)
- `src/server/LeaderboardDisplays.luau` — lobby SurfaceGui boards
- `src/server/GameState.luau` — module for shared game state
- `src/server/ToolSetup.server.luau` — builds anomaly tool, No Anomaly tool, Echo Ping tool in StarterPack
- `src/server/ShopHandler.luau` — BuyCosmetic, EquipCosmetic, GetShopData, BuyEchoPing handlers

### Shared
- `src/shared/AnomalySwapConfig.luau` — catalog (25 entries), swapConfig coords, roomBounds, categories
- `src/shared/AnomalyBehavior.luau` — 15 behavior anomalies, all deterministic
- `src/shared/CosmeticConfig.luau` — 8 cosmetics with prices

### Client (StarterGui)
- `src/gui/TimerHUD.client.luau` — timer, phase, minimap (static, 90° CW rotated), coin HUD, highlightRoomOnMinimap global
- `src/gui/ToolManager.client.luau` — 5-room + 6-type bars, Lock In, mobile-safe, detects from Backpack
- `src/gui/ChatMenu.client.luau` — deprecated no-op
- `src/gui/ShopUI.client.luau` — tabs (Cosmetics/Consumables), 2-column layout, live coins
- `src/gui/EchoPingClient.client.luau` — tool-based ping UI, calls UseEchoPing + highlightRoomOnMinimap

### Tools (Floor Generators)
- `src/tools/FloorGenerator.luau` — generates floor template with Regions folder
- `src/tools/LobbyGenerator.luau` — D=46, desk at z=-D/2+7, Jeremy ATS NPC at wallZ+3, shelving, spawn at z=0

---

# Build & Verification

- `rojo build --output TheEchoFloor.rbxm` — must succeed with no errors
- All ModuleScripts must `return` a value
- All `.server.luau` files must NOT be ModuleScripts (or rename to `.luau`)
- No `Enum.Material.CarbonFiber` — use DiamondPlate
- Tool welds must exist for all non-Handle tool parts
- SurfaceGui AlwaysOnTop=true for boards to prevent blanking at close range

# Known Issues / Pitfalls

- `FloorCloner.luau` looks for Templates.Floor but FloorGenerator saves to Templates.MasterFloor.Floor — mismatch exists
- `LeaderboardService.luau` reads nonexistent Points/Correct leaderstats children in PlayerRemoving (these fields were removed from leaderstats in favor of DataStore-only tracking)
- Some audio sound IDs (KitchenDrip uses rbxasset://sounds/button.wav) are placeholders — may need replacement
- LivingRoomFloat uses RunService.Heartbeat with CFrame manipulation — needs cleanup if anomalies are swapped frequently
- Room 0 (ElevatorLobby) exists physically for intermission but is NOT a guessable room
- EchoPingClient may have race condition with TimerHUD's `_G.highlightRoomOnMinimap` registration — currently uses `_G.` prefix
- ReturnToLobby remote does not exist in Remotes folder (moved to MatchmakingService logic)
- `rojo serve` must be restarted when adding new instances in default.project.json
- Dev timings active via `ROUNDING_TIME=true` environment variable — revert to production before release

# 04 — Anomalies

## System Design

Each round, the server:
1. Clones the floor template.
2. Picks ONE anomaly from the combined pool (10 swap targets + 15 behavior anomalies).
3. For swap anomalies: hides the original object and shows its replacement.
4. For behavior anomalies: applies a scripted environment change (lights, audio, architecture, reality).
5. Players equip the anomaly scanner and pick a **room** (5 rooms, no ElevatorLobby) + **category** (6 types) to submit their guess.
6. On reveal, the server checks if both room and category match the anomaly's catalog entry.

No anomaly ever modifies source assets. The clone is the only thing that changes.

## Anomaly Catalog

All anomalies are registered in `AnomalySwapConfig.luau` with `region` and `type`:

```lua
catalog = {
    -- Swap anomalies (10)
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
    -- Behavior anomalies (15)
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
    -- Reality (2)
    ["LivingRoomFloat"] = { region = "LivingRoom", type = "Reality" },
    ["BedroomPaintingEyes"] = { region = "Bedroom", type = "Reality" },
}
```

Note: Carpet was originally in Hallway, fixed to Bedroom.

## Anomaly Categories

6 categories total:

| # | Category | Description | Count |
|---|----------|-------------|-------|
| 1 | **Object** | An item was replaced, moved, or changed | 10 (swap) |
| 2 | **Lighting** | Lights changed color, brightness, or position | 5 (behavior) |
| 3 | **Audio** | Ambient sounds changed or added | 5 (behavior) |
| 4 | **Architecture** | Walls, doors, or windows altered | 3 (behavior) |
| 5 | **Living** | Plants, pets, or living things altered | 0 (not yet implemented) |
| 6 | **Reality** | Physics, gravity, time distortions | 2 (behavior) |

## Behavior Anomalies (15 total)

All behavior anomalies are **deterministic** (no math.random) so players learn consistent patterns.

### Lighting (5)

| Name | Region | Effect |
|------|--------|--------|
| LivingRoomStrobe | LivingRoom | Strobe via alternating Tween on all PointLights |
| KitchenLights | Kitchen | All PointLights turn red, brightness reduced |
| BedroomDim | Bedroom | All PointLights dim to 0.1 (detected by position vs roomBounds) |
| HallwayFlicker | Hallway | Two PointLights alternate on/off every 0.15s via Heartbeat |
| BathroomBlackout | Bathroom | PointLight disabled entirely |

### Audio (5)

All audio: 3D spatial sound (EmitterSize=12, RollOffMaxDistance=30), anchored at room center, loop until reverted, Volume=0.5, Sound Group=SFX.

| Name | Region | Effect |
|------|--------|--------|
| LivingRoomHum | LivingRoom | Low hum loop at room center |
| KitchenDrip | Kitchen | Drip sound at room center |
| BedroomWhisper | Bedroom | Whisper loop at room center |
| HallwayFootsteps | Hallway | Footstep loop at room center |
| BathroomEcho | Bathroom | Echo sound at room center |

### Architecture (3)

| Name | Region | Effect |
|------|--------|--------|
| LivingRoomWallOpen | LivingRoom | One wall becomes 0.3 transparency (partially invisible) |
| KitchenCounterRaise | Kitchen | Counter Part increases Y size by 2 studs |
| BathroomMirrorFog | Bathroom | Mirror Part transparency increased to 0.4 (foggy) |

### Reality (2)

| Name | Region | Effect |
|------|--------|--------|
| LivingRoomFloat | LivingRoom | Furniture Part floats 5 studs up with BodyPosition, bobs via Heartbeat |
| BedroomPaintingEyes | Bedroom | Painting grows two black SphereParts (pupils) that track nearest player |

## Room + Category Guessing

Players do NOT click on individual objects. Instead:

1. **Equip the anomaly scanner** — selection bars appear at bottom of screen.
2. **Left bar: pick a room** — **5 rooms** (ElevatorLobby excluded): Hallway, LivingRoom, Kitchen, Bedroom, Bathroom.
3. **Right bar: pick a category** — Object, Lighting, Architecture, Audio, Living, Reality.
4. **Press Lock In** — guess submitted to server.
5. Partial credit for getting one of the two right.

## Swap Anomaly Mechanics

1. Original objects tagged with `AnomalyTarget = true`.
2. Replacements stored in `Floor.Anomaly` folder with attribute `Replaces = "OriginalName"`.
3. On swap: original moved to hide position (Y = -200), replacement moved to show position.
4. On revert: original restored, replacement hidden.

## Behavior Anomaly Mechanics

1. Defined in `AnomalyBehavior.luau` — each has `apply(floor)` / `revert(floor)`.
2. On swap: `apply()` modifies the floor environment deterministically.
3. On revert: `revert()` restores original state.
4. AnomalySwapper picks from BOTH swap and behavior pools using the same `usedAnomalies` tracker.

## No Anomaly Tool

A separate "No Anomaly" tool lets players submit `{ region = nil, category = nil }` for floors where nothing appears to have changed. Awards +5 points / 3 coins if correct.

## Echo Ping Consumable

- One-use item (35 coins) purchased in ShopUI Consumables tab.
- When equipped, shows ping count + USE button.
- On use: server validates search phase + anomaly exists, decrements ping count, returns anomaly `{ room, type }`.
- Client highlights the room on the minimap with a red pulsing border + glow for 5s.
- 8s cooldown between uses.

## Object Tag System

- **Original**: Attribute `AnomalyTarget = true`
- **Replacement**: Attribute `Replaces = "ExactOriginalName"`

## Future Anomalies (Planned)

- Floor tile pattern changes
- Wrong room layout (wall moved)
- Statue that turns its head when unobserved
- Door that opens to a brick wall
- Photograph where a person is facing the wrong way
- Temperature shift (breath visible in one room)
- Sound swap between rooms
- More Living and Reality category anomalies

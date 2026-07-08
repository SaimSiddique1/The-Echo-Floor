# 03 — Environment

## The Hotel Lobby (Matchmaking Hub)

Located high in the sky (Y = 1000). Players spawn here and return here between rounds.

### Layout (Top-Down)
```
                      ┌──────────────┐
                      │   Elevator   │
                      │     Bay      │
                      └──────┬───────┘
                             │
                ┌────────────┴────────────┐
                │         Desk            │
                │  [Jeremy ATS NPC]       │
                ├───┬─────────────────┬───┤
                │   │                 │   │  ← shelving units
                │   │   Red rug       │   │
                │   │   (spawn)       │   │
                │   │                 │   │
                └───┴─────────────────┴───┘
```

### Dimensions
- Room depth (Z): **46 studs** (D)
- Room width (X): variable, centered at X=0
- Desk: at z = -D/2 + 7 = **-16** (reception desk, moved forward from back wall)
- Jeremy ATS NPC: at back wall + 3 studs (wallZ + 3), behind desk
- Spawn: at **z = 0** (centered on red area rug)
- Shelving units flanking desk: 3×8×4 studs each, with 3 internal divider boards

### Visual
- Luxury hotel lobby aesthetic — marble floors, tall ceilings, warm lighting
- Open layout with seating areas, sofas, chandeliers
- Red area rug at spawn point
- Leaderboard boards on walls ("PrevGameBoard", "AllTimeBoard")
- Spectator seating for eliminated players

### Jeremy ATS NPC (Shop)
- Positioned behind the reception desk at the back wall
- Built from Torso + Head + Arms parts (taller: torso 2.4, head at Y+4.6, arms 2.0)
- BillboardGui with "Jeremy ATS" + "Browse" label, BillboardOffset=6
- ProximityPrompt "Browse" triggers ShopUI

### Elevator Bay
- Physical 3D area marked by a door frame and floor decals
- BayDetector part with ProximityPrompt (8 studs, no line-of-sight)
- SurfaceGui displays countdown
- Logic:
  - No players inside: displays "Waiting"
  - 1+ players inside: 15-second countdown begins (Dev: 5s)
  - 8/8 players: countdown drops to 3 seconds
  - Timer hits 0: doors close, players teleport to game floor

---

## The Game Elevator

Located at game level (Y = 0). Persistent — never destroyed between rounds.

### Position
- **Center**: (-46.1, 0, -9)
- Connected to ElevatorLobby on the floor template

### Dimensions
- **18 × 22 × 15 studs** (interior: roomy for 8 players)

### Visual
- Warm wood paneling on side walls (brown Wood material)
- Brass handrails (CylinderParts, gold, along both side walls at waist height)
- Dark carpet floor (dark brown, Fabric material)
- White ceiling panels with a single recessed light (Plastic, white)

### Lighting
- Dim yellow PointLight in center of ceiling
- Shadows enabled (soft, low resolution)

### Floor Display
- SurfaceGui on the back wall
- Shows round results after the search phase
- Displays: correct guessers, wrong guessers, abstainers, coins earned

### Doors
- Two metal slabs, one per side
- Animate via TweenService (slide apart, slide closed)
- Open duration: ~1.5 seconds
- **Doors stay open** from after Explore through Boarding phase
- Only close when the next Going Up sequence fires

---

## The Floor Template

One master model, duplicated every round. Never modify the source — clone it.

### Room Layout

```
                    ┌───────────┐
                    │  Bedroom  │
                    │           │
┌──────────┬────────┤           ├────────┐
│ Bathroom │        └───────────┘        │
│          │                              │
│          │         Hallway              │
├──────────┴──────────┬──────────────────┤
│  Elevator Lobby     │   Living Room    │
│                     │                  │
│                     ├──────────────────┤
│                     │    Kitchen       │
│                     │                  │
└─────────────────────┴──────────────────┘
```

### Room Details

| Room | Dimensions (Z×X) | Connected To |
|------|-----------------|--------------|
| Hallway | 24×72 | ElevatorLobby, LivingRoom, Bedroom, Bathroom |
| ElevatorLobby | 36×30 | Hallway, Elevator opening (xMin wall) |
| LivingRoom | 60×42 | Hallway, Kitchen |
| Kitchen | 48×36 | LivingRoom |
| Bedroom | 30×36 | Hallway |
| Bathroom | 24×30 | Hallway |

### Construction
- Floor height: 15 studs
- Wall thickness: 1 stud, tinted per room
- Per-room floor materials (carpet, wood, slate, granite)
- Baseboards (1 stud tall), crown molding
- Ceiling lights with PointLights in each room
- Window at hallway dead end (extrudes 0.5 studs too far — always present, never an anomaly)
- All parts: Locked = false, Anchored = true

### Regions Folder
FloorGenerator creates a `Regions` folder with 6 transparent non-collidable Parts, one per room at Y=0.5. Used by client for room detection.

### Anomaly Folder
Contains replacement objects for swap anomalies, each tagged with `Replaces = "OriginalName"`.

---

## Minimap

- Static grid showing 6 room cells in actual floor shape
- 90° CW rotated (world X → screen Y, world Z → screen X)
- Player dot moves based on world position
- Direction arrow rotates with player facing
- Map never rotates — rooms are fixed
- Room cells pulse red when Echo Ping is used
- Frame size: 205×115 (desktop) / 380×220 (mobile with UIScale 0.35)

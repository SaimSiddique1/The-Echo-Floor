# 02 — Round Structure

## Phase 0: Lobby

1. Players join and spawn in a **luxury hotel lobby** high in the sky (Y = 1000).
2. One elevator bay is visible — marked with "Max 8 Players" signs.
3. Players walk freely around the lobby. No timer. No pressure.
4. When a player steps into an elevator bay (ProximityPrompt on BayDetector, 8 studs, no line-of-sight), they are registered for the next game.
5. The bay's countdown starts at **15 seconds** (Dev: 5s) once the first player enters.
6. Other players can walk in to join before the timer ends.
7. If the bay reaches **8/8 players**, the timer instantly drops to **3 seconds**.
8. When the timer hits 0, the elevator doors close.

## Phase 1: Going Up (5s / Dev: 3s)

1. Doors close via TweenService animation (~1.5s).
2. All players inside the bay are teleported to the **game elevator** (at Y = 0).
3. Anomaly swap happens at t=end (during the ascent).
4. Floor display shows "Ground Floor" for floor 0, then floor number thereafter.
5. Ding sound at t=1 — doors open to the first floor.

## Phase 2: Explore (60s / Dev: 10s — Floor 0 only)

1. Elevator doors slide open. Players step out into the **Elevator Lobby**.
2. Floor contains **6 rooms**: Hallway, ElevatorLobby, LivingRoom, Kitchen, Bedroom, Bathroom.
3. A timer begins.
4. **No anomaly on floor 0** — this is a learn-the-layout round. Timer displays "Ground Floor".
5. Players explore freely. No restrictions.
6. The anomaly tool can be equipped but the **selection bars do not appear** (no choosing yet).

## Phase 3: Search (60s scales / Dev: flat 15s)

1. Elevator doors open. Players equip their handheld anomaly scanner.
2. **Room + Category selection bars** appear at the bottom of the screen.
3. Players choose a **room** (left bar, 5 rooms — ElevatorLobby excluded) and **type** (right bar, 6 types), then press **Lock In**.
4. Once locked in, the guess is sent to the server.
5. Players CAN change their guess before locking in (re-select room or type).
6. Round ends when **all surviving players have locked in** OR **timer expires**.
7. Players who didn't lock in are marked as **abstained**.

### Search Timer by Floor (Production)

| Floors | Search Time |
|--------|------------|
| 1–3 | 60s |
| 4–6 | 50s |
| 7–9 | 40s |
| 10+ | 35s |

### Dev Override
With `ROUNDING_TIME=true`, search timer is flat **15s** regardless of floor. All other timers also use dev values.

## Phase 4: Intermission (5s / Dev: 3s)

1. All surviving players are teleported to the **elevator lobby**.
2. A **barrier** blocks the hallway.
3. Wall screen shows each player's name with a pending/reveal status indicator.
4. **No discussion, no changing guesses.** ChatMenu is deprecated to no-op.
5. Timer counts down.

## Phase 5: Reveal (8s / Dev: 4s)

1. Wall screen shows results:
   - Anomaly name + region · type
   - Per-player results with coin rewards on second line
   - Who was correct (green), partial (yellow), wrong (red), abstained (grey)
2. The anomaly is highlighted briefly.
3. Points awarded:

| Condition | Points | Coins |
|---|---|---|
| Both region + category correct | 10 + speed bonus | 5 + bonus |
| Region correct only | 5 | 3 |
| Category correct only | 3 | 2 |
| Neither (wrong guess) | -3 | 1 |
| NoAnomaly (correctly) | +5 | 3 |
| Abstain | 0 | 0 |

Speed bonus: 1st=+5, 2nd=+3, 3rd=+1 (based on lock-in time within correct guessers).

4. **Wrong guess = elimination.** Teleport to lobby spectator seating immediately.
5. If all players are eliminated, the game ends.

## Phase 6: Boarding (5s / Dev: 3s)

1. Elevator doors open. Elevator music plays.
2. **Surviving players** step back into the elevator.
3. Doors close.
4. Loop back to **Phase 1 (Going Up)** for the next floor.

**Doors stay open** from after Explore through Boarding phase. They only close when the next Going Up sequence fires.

## Echo Ping Consumable

- One-use item (35 coins) purchased from ShopUI Consumables tab.
- When equipped as tool from hotbar, shows ping count + USE button at bottom-center.
- On use: reveals anomaly's room on the minimap with a red pulsing border for 5s.
- 8s cooldown between uses.
- Only usable during Search phase.

## Edge Cases

- **Player eliminated mid-floor**: Teleported to spectator area on wrong guess.
- **Player disconnects**: Treated as abstained — no elimination penalty.
- **All players eliminated**: Game ends immediately, teleport to lobby.
- **Last surviving player**: They keep going solo until wrong or quit.
- **Bay timer expires with only 1 player**: Game proceeds with 1 player.

## Timing Constants

### Production
| Event | Duration |
|-------|----------|
| Lobby wait (unlimited) | — |
| Bay countdown (starts on 1st player) | 15s (drops to 3s at 8/8) |
| Going Up animation | 5s |
| Explore (floor 0 only) | 60s |
| Search (varies by floor) | 60s–35s |
| Intermission | 5s |
| Reveal | 8s |
| Boarding | 5s |

### Dev (ROUNDING_TIME=true)
| Event | Duration |
|-------|----------|
| Bay countdown | 5s |
| Going Up | 3s |
| Explore | 10s |
| Search | 15s (flat) |
| Intermission | 3s |
| Reveal | 4s |
| Boarding | 3s |

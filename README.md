# dps-traintools

Rider tools for GTA V trains: board with E, sit on the carriage, get off at a stop, and see ambient NPC passengers.

## Features

- **Boarding with E.** Stand within 5.5 m of a train carriage and within 60 m of a listed station. A "[E] Board Train" prompt appears. Press E to board.
- **No standstill needed.** The only condition is being at a station. The train may be moving, so late players can catch a train that is leaving.
- **Native seat first.** Boarding tries a free native vehicle seat on the carriage. If the carriage has none, the player is attached to the carriage at an offset picked for that car type, and plays a seated animation.
- **Seat offsets per car type.** Position along the car is random.

  | Car type | Where the player sits |
  |---|---|
  | Locomotive (`sd70mac`, `gevo`, `streak*` models that are not coaches or cab cars) | In the cab, near the rear |
  | Caboose / cab car (`freightcaboose`, any model name containing `cab`) | Centre deck |
  | `freightflatlogs` | On the logs |
  | `freightgraincar`, `freightcoal` | In the hopper well |
  | `freighttanklong` | On the tank |
  | `freightcont` | On the container |
  | `freightboxlarge` | On the boxcar roof |
  | `freightstack` | On the double stack |
  | Anything else (coaches) | Either side, spread along the car |

  There is no occupancy check. Two players can land on the same spot.
- **Getting off.** While riding, the prompt changes with train speed:
  - Train slower than 1.5 m/s: "[E] Disembark". The player gets off at once.
  - Train moving: "[E] Disembark at next stop". Press E to queue it. The prompt becomes "Disembarking at next stop...". The player is stepped off when the train slows below 1.5 m/s. Press E again to cancel.
  - Attached riders are moved 2.5 m beside the carriage. Seated riders leave the vehicle normally.
- **Enter-vehicle block.** While a prompt is showing, the game's enter-vehicle (control 23) and exit-vehicle (control 75) actions are disabled. This stops the game from running its own enter behaviour on E, which can put players on the roof instead of boarding.
- **Ambient riders.** Each client fills trains it can see with local, non-networked NPCs. These are invincible and ignore events.
  - Passenger coaches (`streakc`, `streakcoasterc`) get 2 to 4 riders each.
  - The caboose (`freightcaboose`) has a 20% chance of one rider.
  - The locomotive never gets riders.
  - Riders are deleted when their train no longer exists, and when the resource stops.
- **Door diagnostics.** `/traindoors` prints how many door components each carriage exposes, and can open or close the doors.
- **Seat tuning.** `/seatmark` prints the model name and offset where you stand, and logs it to the server console.
- **Cleanup on stop.** Spawned riders are deleted, the player is detached, and any preview blip is removed.

## Prerequisites

- `ox_lib` (declared in `fxmanifest.lua`). It is used for the text prompt, animation dictionary loading and model loading.
- A train in the world. The resource works on any entity of vehicle class 21 (trains), including vanilla trains. It does not call any other train resource.
- Lua 5.4 (`lua54 'yes'` in the manifest).

Seat offsets and rider models use these model names: `streakc`, `streakcoasterc`, `sd70mac`, `gevo`, `freightcaboose`, `freightflatlogs`, `freightgraincar`, `freightcoal`, `freighttanklong`, `freightcont`, `freightboxlarge`, `freightstack`. Other models fall back to the default coach offset.

## Installation

1. Copy the `dps-traintools` folder into your `resources` folder.
2. Make sure `ox_lib` starts before it. In `server.cfg`:

   ```
   ensure ox_lib
   ensure dps-traintools
   ```
3. Start or restart the server.

No ACE permissions are checked. Any player can use every command.

## Configuration

There is no config file. Edit the constants at the top of `client.lua` sections and restart the resource.

| Setting | Where | Default | Meaning |
|---|---|---|---|
| `STATIONS` | `client.lua`, station list | 18 `vec3` coordinates | Positions where the E boarding prompt is offered. Add or remove entries to match your stations. |
| Station radius | `atStation` | `60.0` | Distance in metres from a station in which boarding is offered. |
| Prompt range | main prompt loop, `nearestCarriage(5.5)` | `5.5` | How close to a carriage you must be to see the board prompt. |
| Board range | `doBoard`, `nearestCarriage(8.0)` | `8.0` | Carriage search distance when boarding runs. |
| Stopped speed | main prompt loop | `1.5` | Speed in m/s under which the train counts as stopped for getting off. |
| `FREIGHT_SEATS` | `doBoard` | see table above | Per freight model: `z` height, `spread` length range along the car, `lateral` side offset. |
| `RIDERS.minPerCoach` | `RIDERS` | `2` | Fewest NPC riders per passenger coach. |
| `RIDERS.maxPerCoach` | `RIDERS` | `4` | Most NPC riders per passenger coach. |
| `RIDERS.hoboChance` | `RIDERS` | `20` | Percent chance the caboose carries one rider. |
| `RIDERS.models` | `RIDERS` | 10 ped models | Ped models used for riders. |
| Coach model names | `dressTrain` | `streakc`, `streakcoasterc` | Models that receive riders. |
| Prompt colours | `lib.showTextUI` calls | navy `#1b2340`, cream `#f4f1ea`, accent `#ff7a45` | Style of the prompt. |

## Commands and keys

| Command / key | What it does |
|---|---|
| `E` | Board near a train at a station. Disembark, or queue disembark at the next stop, while riding. |
| `/board` | Board the nearest carriage within 8 m. Does not check for a station. |
| `/disembark` | Get off now, whatever the train speed. |
| `/seatmark` | Needs a carriage within 30 m. Logs the carriage model, your offset from it and your relative heading. Printed to your client console and the server console. Use it to tune seat offsets. |
| `/traindoors` | Needs a carriage within 60 m. Prints each carriage in the consist with its door count. Changes nothing. |
| `/traindoors 0` | Open one side of every carriage (odd door indexes). |
| `/traindoors 1` | Open the other side (even door indexes). |
| `/traindoors 2` | Open both sides. |
| `/traindoors off` | Close all doors. |
| `/blippreview <id>` | Place a map blip with that sprite id at your position. With no number, remove it. |

## Troubleshooting

- **No boarding prompt.** You must be within 60 m of a position in `STATIONS` and within 5.5 m of a carriage, and you must not be in a vehicle. If your stations are elsewhere, edit `STATIONS`. `/board` works anywhere within 8 m of a carriage.
- **Nothing happens when boarding with `/board` or E.** Boarding does nothing if you are already seated, or if no carriage is within range.
- **The game climbs onto the roof instead of boarding.** The resource disables controls 23 and 75 while its prompt is up. If another script re-enables them, boarding conflicts.
- **Doors do not open (`/traindoors` shows `doors=0`).** The train model exposes no door components. The command ends with a message saying so. No script change will open them. Check the model's vehicle layouts.
- **`/traindoors` says no carriage within 60m.** Stand next to the train and try again.
- **`/seatmark` says no carriage in 30m.** Stand on or next to a carriage.
- **No NPC riders.** Riders only appear on trains with at least two carriages, on the models `streakc` and `streakcoasterc` (and the caboose by chance). Trains are checked every 5 seconds. Other coach models need to be added in `dressTrain`.
- **Riders sit on the lower deck of bi-level coaches.** They use the same height as players. Raise `z` in the coach offset, found with `/seatmark`.
- **Two players share one seat.** Seat position is random and no occupancy is tracked.
- **Prompt text or icons look wrong.** `ox_lib` must be started first and up to date, because the prompt uses `lib.showTextUI`.

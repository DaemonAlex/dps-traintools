# dps-traintools

Rider tools for GTA V trains: board with E, sit on the carriage, get off at a stop, and see ambient NPC passengers.

## What it is for

A GTA train does not let a player on board in FiveM. Pressing E next to one does nothing, or puts you on the roof. Trains also run empty, which looks dead. This script gives players a clear prompt to board at a station, a seat, a way to get off at the next stop, and other passengers to look at.

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

## On its own, and with other scripts

**On its own.** With only `ox_lib` it works on any train in the world, vanilla trains included. You get the boarding prompt, seating, getting off, and NPC riders. It calls no other train resource.

**With a paid train pack (BigDaddy Trains Overhauled).** The seat positions are fitted to that pack's models: coaches, locomotives, the caboose and the freight wagons each have their own spot. NPC riders fill its `streakc` coaches. The script only reads the model name of the carriage in front of you. A pack update does not break it. A model it does not know gets the default coach seat.

**With dps-trains.** dps-trains stops the trains at stations and opens the doors. This script gets the player on and off. The two do not call each other. That is on purpose: you can restart dps-traintools without sending every train back to its start. The station list in `client.lua` is kept by hand and must match the stops dps-trains uses. It does not yet have Downtown LS or Market Square, which dps-trains added on 29 September 2026. Use `/boardtrain` at those two.

**With dps-trains-stock.** That resource streams the carriages named in the seat table.

**With dps-traintracks and dps-transitapp.** No direct link. dps-traintracks adds track for dps-trains. dps-transitapp shows arrival times on the phone, so a player knows when to be on the platform.

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
| `/boardtrain` | Board the nearest carriage within 8 m. Does not check for a station. (Was `/board`, retired so it no longer clashes with the airline's boarding.) |
| `/disembark` | Get off now, whatever the train speed. |
| `/seatmark` | Needs a carriage within 30 m. Logs the carriage model, your offset from it and your relative heading. Printed to your client console and the server console. Use it to tune seat offsets. |
| `/traindoors` | Needs a carriage within 60 m. Prints each carriage in the consist with its door count. Changes nothing. |
| `/traindoors 0` | Open one side of every carriage (odd door indexes). |
| `/traindoors 1` | Open the other side (even door indexes). |
| `/traindoors 2` | Open both sides. |
| `/traindoors off` | Close all doors. |
| `/blippreview <id>` | Place a map blip with that sprite id at your position. With no number, remove it. |

## Troubleshooting

- **No boarding prompt.** You must be within 60 m of a position in `STATIONS` and within 5.5 m of a carriage, and you must not be in a vehicle. If your stations are elsewhere, edit `STATIONS`. `/boardtrain` works anywhere within 8 m of a carriage.
- **Nothing happens when boarding with `/boardtrain` or E.** Boarding does nothing if you are already seated, or if no carriage is within range.
- **The game climbs onto the roof instead of boarding.** The resource disables controls 23 and 75 while its prompt is up. If another script re-enables them, boarding conflicts.
- **Doors do not open (`/traindoors` shows `doors=0`).** The train model exposes no door components. The command ends with a message saying so. No script change will open them. Check the model's vehicle layouts.
- **`/traindoors` says no carriage within 60m.** Stand next to the train and try again.
- **`/seatmark` says no carriage in 30m.** Stand on or next to a carriage.
- **No NPC riders.** Riders only appear on trains with at least two carriages, on the models `streakc` and `streakcoasterc` (and the caboose by chance). Trains are checked every 5 seconds. Other coach models need to be added in `dressTrain`.
- **Riders sit on the lower deck of bi-level coaches.** They use the same height as players. Raise `z` in the coach offset, found with `/seatmark`.
- **Two players share one seat.** Seat position is random and no occupancy is tracked.
- **Prompt text or icons look wrong.** `ox_lib` must be started first and up to date, because the prompt uses `lib.showTextUI`.

## Recent changes

- **12 November 2026.** README: what it is for, how it works alone and with paid scripts, other DPS scripts.
- **24 October 2026.** `/board` renamed to `/boardtrain`. The old name clashed with the airline's boarding command.
- **4 October 2026.** The game's enter and exit keys are blocked while the prompt is up, so E seats you and does not put you on the roof.

## Author

Made by [DaemonAlex](https://github.com/DaemonAlex) for DelPerroSands.

## Other DPS scripts

All of these are made for DelPerroSands and run together on one Qbox server. Each one works on
its own. The ones marked "pairs with" do more when both are running.

| Script | What it does |
|---|---|
| [dps-inventory](https://github.com/DaemonAlex/dps-inventory) | The inventory: ox_inventory with equipment slots, backpacks, armour plates and a self status panel, in the DelPerroSands colours. |
| [dps-medical](https://github.com/DaemonAlex/dps-medical) | Patient records, illness and diagnostic tests. A companion to wasabi_ambulance. Pairs with dps-inventory: symptoms and diagnoses show on the status panel. |
| [dps-insurance](https://github.com/DaemonAlex/dps-insurance) | Ties m-Insurance into the MDT, impound, hospital and medical chart. Pairs with dps-medical. |
| [dps-studio](https://github.com/DaemonAlex/dps-studio) | Build rooms, doors and portals in game from one panel (`/studio`), with owners and managers so staff do not have to support them. |
| [dps-shops](https://github.com/DaemonAlex/dps-shops) | Shop clerks who greet and react to a robbery, then player-owned shops. |
| [dps-fleet](https://github.com/DaemonAlex/dps-fleet) | Vehicle browser and workshop on one panel: extras, liveries and mods for emergency vehicles. |
| [dps-parking](https://github.com/DaemonAlex/dps-parking) | Parking with valet, impound, violations and reserved spots. |
| [dps-vehiclepersistence](https://github.com/DaemonAlex/dps-vehiclepersistence) | Vehicles stay where they were parked. Pairs with dps-parking. |
| [dps-towjob](https://github.com/DaemonAlex/dps-towjob) | Queue-based tow job with jg-mechanic integration. |
| [dps-services](https://github.com/DaemonAlex/dps-services) | Request a tow and follow it live on the lb-phone and lb-tablet. Pairs with dps-towjob. |
| [dps-autoshops](https://github.com/DaemonAlex/dps-autoshops) | Self-service repair shops when no mechanic is on duty. |
| [dps-cityworker](https://github.com/DaemonAlex/dps-cityworker) | City infrastructure job and career. |
| [dps-ainpcs](https://github.com/DaemonAlex/dps-ainpcs) | NPCs you can talk to, with trust, quests and intel. |
| [dps-badpeds](https://github.com/DaemonAlex/dps-badpeds) | Police interaction with NPCs: stops, arrests, intel and jail records. |
| [dps-gangwars](https://github.com/DaemonAlex/dps-gangwars) | Ambient gang NPCs, territory population and war reinforcements. |
| [dps-rotations](https://github.com/DaemonAlex/dps-rotations) | Moves dealers, harvests and other spots on a fixed schedule. |
| [dps-trains](https://github.com/DaemonAlex/dps-trains) | The train system. Pairs with dps-trains-stock, dps-traintools and dps-transitapp. |
| [dps-transitapp](https://github.com/DaemonAlex/dps-transitapp) | Live train arrival boards on the lb-phone. |
| [dps-faceplant](https://github.com/DaemonAlex/dps-faceplant) | City help, reports and staff tools on the lb-phone and lb-tablet. |
| [dps-chat](https://github.com/DaemonAlex/dps-chat) | A command box for voice-only servers. No chat feed. |
| [dps-filmmode](https://github.com/DaemonAlex/dps-filmmode) | One key hides every HUD layer and gives a smooth free camera for recording. |

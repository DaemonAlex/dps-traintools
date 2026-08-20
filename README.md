# dps-traintools

Everything a **person** does with a train: getting on, sitting down, getting
off — plus the ambient passengers that make a carriage look occupied.

`dps-trains` runs the railway. This resource is the bit players touch.

## Boarding

Stand at a station with a train alongside and press **E**.

The only condition is **being at a station** — not the train being stopped. That
is deliberate: with a 30-second dwell, requiring a standstill made trains
uncatchable, and it means someone who arrives late can chase one that is already
pulling out. Trains crawl from 180 m out on approach, so anything at a platform
is slow by the time you reach it.

Boarding tries a native vehicle seat first. The stock in use has no usable seat
bones, so in practice it falls through to **attach-seating**: the player is
attached at an offset chosen for that carriage type.

## Seating

Offsets are per model, because a boxcar, a hopper and a coach are all different
shapes:

| Car type | Where you end up |
|---|---|
| Locomotive | in the cab, high floor toward the rear |
| Coach | spread along the car, either side |
| Caboose | on the centre deck |
| Flat / log flat | on the deck |
| Hopper | down in the well |
| Tanker / container / boxcar | on top |

Position along the car is **randomised**, so several players do not stack in one
spot — but there is **no occupancy check**, so two people can still land on the
same place in a busy carriage. It only bites at high passenger volume; the fix
would be a per-carriage table of taken slots.

Use **`/seatmark`** to tune any of these: stand where a rider should sit and it
prints the model name and the offset to paste into `client.lua`.

## Ambient riders

Carriages are populated with NPCs so a train does not look abandoned. They spawn
in coach models only — never the locomotive, which is why the lead car is always
empty.

Riders sit at the same height as players, which on a bi-level coach puts
everyone on the **lower deck**. Upstairs would need a higher offset, confirmed
with `/seatmark` rather than guessed.

## Commands

| | |
|---|---|
| `/traindoors` | door diagnostics — see below |
| `/traindoors 0 \| 1 \| 2 \| off` | open left, right, both, or close |
| `/seatmark` | print the model and offset where you are standing |

### Why `/traindoors` exists

`dps-trains` opens doors by calling `GetTrainDoorCount` on each carriage, then
`SetTrainDoorOpenRatio` on the even or odd indices to pick a side. **When a model
exposes no door components the count is zero, the index list is empty, and the
doors silently do nothing** — no error, no log line. A model without doors and a
broken script look identical.

`/traindoors` reports the count the natives actually see, per carriage, and can
drive the doors directly. Zero across a whole consist means the model has no door
components and no script change will ever open them.

## Requires

| | |
|---|---|
| `ox_lib` | text UI and utilities |
| `dps-trains` | not a hard dependency — this works on any train entity, including vanilla ones |

## Sharp edges

**Do not invent natives.** `GetTrainCarriageEngine` does not exist; using it
killed the rider-dressing thread silently. Walk the consist with
`GetTrainCarriage(train, i)` instead.

**Trains are class 21.** That is how carriages are found — `GetVehicleClass(veh) == 21`
over `GetGamePool('CVehicle')`.

**Job restrictions are not implemented.** Anyone can currently ride anywhere,
including the locomotive cab. That was a deliberate "later" decision, not an
oversight.

## Related

| | |
|---|---|
| `dps-trains` | scheduling, movement, station stops |
| `dps-trains-stock` | rolling stock and consists |
| `dps-transitapp` | live arrivals on the phone |

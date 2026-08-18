# dps-traintools

Rider experience for the DPS railway. Kept separate from `dps-trains` on
purpose: **restarting dps-trains resets every train to its spawn**, so rider
UX iterates here where deploys are free.

## Features
- **Proximity boarding**: within ~5m of a stopped train at a station, an
  ox_lib TextUI prompt offers `[E] Board Train`. Boarding is station-only by
  design - no hopping moving trains, no mid-desert pickups.
- **Transit-style disembark**: while riding, `[E]` disembarks instantly when
  stopped; while moving it *requests the stop* ("Disembarking at next
  stop...") and steps you off automatically at the next halt. Press again to
  cancel.
- **Seating**: coaches have no native seat bones, so riders are attach-seated
  inside the car with a sit animation. Engines seat you in the cab, the
  caboose on its deck (open to everyone now; job-gating planned).
- **NPC riders**: passenger coaches carry 2-4 local (non-networked) civilian
  riders per coach - pure atmosphere at zero network cost. The caboose has a
  20% chance of a stowaway.
- **Authoring tools**: `/seatmark` logs your position as a seat offset for
  the current carriage (server console output); `/blippreview <id>` previews
  map blip sprites in-world.

Depends on ox_lib. Slash commands `/board` and `/disembark` remain as
fallbacks behind the prompts.

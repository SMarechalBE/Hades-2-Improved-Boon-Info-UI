# Improved Boon Info UI – Hades II Mod

This mod refines how boon information is displayed on all Olympian boon givers page during a run.

## Explicit boon categories

Boons are split into categories based on their availability to the player:
- **Picked**: already acquired (and not sold/sacrificed).
- **Unavailable – Sacrifice Required**: takes a slot that is already occupied and thus requires a sacrifice offering.
- **Unavailable – Keepsake Required**: requires forcing an out-of-pool god via keepsake.
- **Available**: any other boon not in the above categories.

This approach makes it immediately obvious:
- Which boons you *already have*,
- Which ones you *can pick up next*,
- Which ones are *locked behind sacrifice*,
- Which ones require *forcing a god* with a keepsake.

*It avoids guesswork and reduces UI ambiguity without touching gameplay logic.*

## Boon button

Default            |  Modded
-|-
![Boon button default](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/BoonColorBefore.jpg)  |  ![Boon button modded](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/BoonColor.jpg)

### Default

All boons are shown, with title coloring based on their rarity (white/blue/purple/orange/green).

### Modded

Titles coloring now follows the logic:
- *light green*: it is currently picked.
- *dark blue*: it (or one of its unfulfilled requirements) requires a god keepsake
- *dark red*: it (or one of its unfulfilled requirements) requires a sacrifice offering.
- *white/blue/purple/orange/green*: same as before for all available boons

Boons that require a sacrifice also display the boon that would be exchanged in the process, reusing the existing behaviour. 

## Requirements listing

Default            |  Modded
-|-
![Requirements default - sacrifice](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/SacrificeReqBefore.jpg)  |  ![Requirements modded - sacrifice](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/SacrificeReq.jpg)
![Requirements default - keepsake](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/KeepsakeReqBefore.jpg)  |  ![Requirements modded - keepsake](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/KeepsakeReq.jpg)

### Default

When looking at requirements for a given boon, the only information we get is:
- a boon in the requirements is picked: boon name colored in *white* instead of *grey*
- a requirement is fulfilled: heading colored in *light green* instead of *white*

### With Mod

Boons of the **NeedsSacrifice** category are colored in *dark red*.

Those of the **NeedsKeepsake** take *dark blue* coloring

Headings coloring is now changed as well, based on the availability of the required boons:
- *light green*: same as before, a required boon is picked
- *white*: at least one boon is available
- *dark blue*: no available boon and at least one requires adding a new god to the maxed out pool
- *dark red*: all boons require a sacrifice.


## Future updates

- Add the possibility to choose the coloring to apply to categories
- Perhaps a fifth category (both requiring keepsake AND sacrifice)

## Compatibility

- Should be safe with all mods that don't interact with Boon info listing.
- Language independant

## Feedback

Any feedback is welcome
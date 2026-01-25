# Improved Boon Info UI – Hades II Mod

This mod refines how boon information is displayed for all Olympian boon givers page during a run.

## Motivation

In the vanilla game, finding information for boons availability during an ongoing run is very complicated, 
it even gets worse when you add banned boons in the equation.  

This mod tries to make it immediately obvious:
- Which boons you *already have*,
- Which ones you *can pick up next*,
- Which ones are *locked behind a sacrifice*,
- Which ones require *forcing a god* with a keepsake,
- Which ones you have no chance of seeing.

*It avoids guesswork and reduces UI ambiguity without touching gameplay logic.*

## Explicit boon categories

Boons are split into categories based on their current availability.

For boons without requirements:
- **Picked**: currently owned,
- **Available**: any boon that could appear in your next offering,
- **Sacrifice**: any available boon that take an occupied slot, 
- **Unavailable – Keepsake Required**: requires forcing an out-of-pool god using a keepsake,
- **Denied**: any boons not picked when playing with *Vow of Denial*.

For boons with requirements:
- **Unfulfilled**: boon requirements are still fulfillable but are not yet fulfilled,
- **Unavailable – Keepsake Required**: any duo boon with one of the god out of the pool,
- **Denied**: when all required boons for a given category are banned, those boons are thus implicitly banned as well.

## Boon button

![Boon picked](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/BoonPicked.png)
![Boon sacrifice](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/BoonSacrifice.png)
![Boon unfulfilled](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/BoonUnfulfilled.png)
![Boon unavailable](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/BoonUnavailable.png)


Boon buttons have been changed in Codex pages to give more information on their current availability state:
- **picked**: title is colored in *light green*, the same color as when a requirement is fulfilled,
- **available**: unchanged, uses classic rarity color,
- **sacrifice**: title is colored in *dark red* and the current boon using the slot is shown in a similar way as if it appeared in an offering,
- **unfulfilled**: same color as available boons but with half transparency (see screenshot above),
- **unavailable**: title is colored in *dark blue* as long as the god pool is full and that the god is out of it,
- **banned**: the full banned is still using the same style with chains, only difference is the title has the same behaviour than unfulfilled ones.

### Inherited state

If a boon has requirements that are unavailable/banned and thus make it impossible to pick it up is now explicitly shown. 

![Boon inherited ban](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/InheritedBannedReq.png)

In this example, both Apollo's attack and special boons are banned, making it impossible to pick up the legendary. 


## Requirements listing

### Default

![Requirements default](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/InheritedBannedReqBefore.png)

When looking at requirements for a given boon, the only information we get is:
- a boon in the requirements is picked: boon name colored in *white* instead of *grey*,
- a requirement is fulfilled: heading colored in *light green* instead of *white*.

### Modded

![Requirements - sac](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/Requirements.png)

Headings coloring is now changed as well, based on the availability of the required boons:
- *light green*: same as before, a required boon is picked,
- *white*: same as before, except now it ensures that at least one boon is available,
- *dark blue*: no available boon and at least one requires adding a new god to the maxed out pool,
- *dark red*: all boons require a sacrifice,
- *black*: all boons are banned (vow of denial).

Boons inside listing follow the same coloring scheme as default for available and picked ones. 
Then for the others, the coloring applies the same logic as above. *Unfulfilled boons also have even more transparency than unpicked ones*.

![Requirements - pinned and banned](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/RequirementsPinnedBanned.png)

Icons for pinned and banned boons are also displayed at the beginning of each line if elligible.

## Page filtering

![Filter buttons](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/FilterButtons.png)

For even more granularity on the displayed information, extra controls (LB/RB, left/right arrows) have been added to the offering pages allowing to filter boons displayed
based on their current category.

![Filter available](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/FilterAvailable.png)

Current filter pages are the following in this order: 
- **AVAILABLE**: only show available boons,
- **UNFULFILLED**: adds boons with unfulfilled (but still possible) requirements,
- **UNAVAILABLE**: adds boons from gods out of current pool and sacrifice boons,
- **ALL**: adds picked and banned boons.

## Setup
- This mod uses the mod loader [Hell2Modding](https://thunderstore.io/c/hades-ii/p/Hell2Modding/Hell2Modding/). 
- Go to the mod manager [r2modman](https://thunderstore.io/c/hades-ii/p/ebkr/r2modman/) page and follow the installation procedure.
- Launch the game & Enjoy

## Configuration

Multiple parameters can be configured if you desire extra customization:
- `sacrificeBoonsAlwaysAsAvailable` (Default = **false**) : controls whether sacrifice/replacement boons are always considered as available. This can be useful if you often use vow of denial as those will appear more often,
- `unreplaceableSacrificeBoonsAsBanned` (Default = **true**) : controls whether to always consider sacrifice/replacement boons for Heroic boons as banned. It can be useful to set this to false in case you play with mods changing the default behaviour (like adding more rarity options or stackable boons).
### IconInRequirements
- `Pinned` (Default = **true**) : controls whether pin icon is displayed next to pinned/tracked boons in the requirements list,
- `Banned` (Default = **true**) : controls whether locked icon is displayed next to banned boons in the requirements list,
### Filtering
- `DefaultLandingPage`: Enables setting a default filter landing page override. Set the override value to true then choose one of the available options from *Available*, *Unfulfilled*, *Unavailable* or *All*
### AvailabilityStyle
Options in this section gives more customization possibilities on the colors used to display the different informations in codex page. All of those are divided into subsections: *Picked*, *Available*, *Unfulfilled*, *SlotUnavailable*, *GodUnavailable* and *Banned*.
![Style - requirements](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/ConfigStyleReqs.png)
![Style - button](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI/raw/main/img/ConfigStyleButton.png)
All of those give the following to be separately enabled, and then separate overrides can be specified from `ButtonTitle`, `BulletList` and `Header` (except for *Picked* since it doesn't make any sense).
Specifying a color can be done in 2 ways:
1. RGBA hexadecimal value: use any color picker and set the required value (note: unspecifying alpha value will default it to max [FF]).
2. In-game color definitions: those are defined inside `<PathToGameFiles>/Content/Scripts/ColorData.lua`. Simply specify one of those like `Color.White` for example.

## Mod suggestions
Check out my others *QoL* mods, those are all cross-compatible and meant to be used together:
- [Run Boon Overview](https://thunderstore.io/c/hades-ii/p/SMarBe/Run_Boon_Overview/): aggregates all your currently available boons into Melinoë's Codex page.
- [Random Starting Keepsake](https://thunderstore.io/c/hades-ii/p/SMarBe/Random_Starting_Keepsake/): gives the possibility to set multiple keepsakes as favorite, a random one gets drawn when starting the run.
- [Weapon Loadouts](https://thunderstore.io/c/hades-ii/p/SMarBe/Weapon_Loadouts/): saves loadouts (arcanas, familiar, keepsakes and pinned boons) for each weapon aspects.

## Issues and Feedback

Feel free to reach out to me on the official Hades modding [Discord](https://discord.com/invite/KuMbyrN) and/or add an issue on the [repository](https://github.com/SMarechalBE/Hades-2-Improved-Boon-Info-UI) for any encountered bugs or suggested improvements.

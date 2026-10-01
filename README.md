# Nap Mode — Road to Vostok mod

Adds a short **nap** next to vanilla sleep. Like sleep, the duration is random, not chosen:

| | Duration | Energy / Hydration / Mental |
|---|---|---|
| Sleep (vanilla) | random 6–12h | −20 / −20 / +20 |
| Nap | random 1–3h | scaled by `hours / 9` (e.g. 2h → −4.4 / −4.4 / +4.4) |

**Beds:** tap interact = Sleep, **hold interact (0.5s)** = Nap. Tooltip: `Sleep (Random sleep: 6-12h) [Hold: Nap 1-3h]`.
A nap uses up the bed just like a sleep does. Each bed rolls its nap length once, the same way vanilla rolls its sleep length.

**Sleep items** (Sleeping Bag, Mattress, Blanket, Pillow, Melatonin): the inventory right-click menu gets a **Nap** button next to **Sleep**. It consumes the item like Sleep does. The item's temperature effect is scaled the same way as the stats.

## Requirements

- [Metro Mod Loader](https://modworkshop.net/mod/55623) (`modloader.gd` + `override.cfg` in the game folder)

## Install

Download `NapMode.vmz` from the [latest release](../../releases/latest) and drop it into `<game>\mods\`.

## Releasing

GitHub Actions (`.github/workflows/build.yml`) packages `src/` into `NapMode.vmz` on every push and PR (downloadable from the run's artifacts).

To publish a release, bump `version=` in `src/mod.txt` following [SemVer](https://semver.org), then tag that commit:

```sh
git commit -am "Release 1.1.0"
git tag v1.1.0
git push origin master v1.1.0
```

The tag must match `mod.txt` (`v` + version), or the build fails. Versions with a suffix such as `1.2.0-beta.1` are published as prereleases.

## How it works

Built on Metro Mod Loader **hooks** (`src/NapMode/Main.gd`). Metro rewrites the vanilla scripts with dispatch wrappers.
- `bed-interact` (replace): times how long interact is held. A tap lets vanilla run; a hold calls `skip_super()` and naps instead.
- `bed-updatetooltip-post`: adds the `[Hold: Nap 1-3h]` line.
- `context-_ready-post` / `context-update-post`: clone the Sleep button as "Nap" and show it whenever Sleep is shown.
- `src/NapMode/Nap.gd`: shared nap rules (`MIN_HOURS`, `MAX_HOURS`, `SLEEP_AVERAGE`).

Why not `take_over_path`: `Database.gd` preloads the bed scenes at startup, before any mod autoload runs, so those beds keep the vanilla script (see Metro wiki, *Limitations → Scene-preload deferred compile*).

See [MODDING_RESOURCES.md](MODDING_RESOURCES.md) for general modding notes.

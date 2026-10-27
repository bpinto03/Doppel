# Doppel documentation

| Document | Content |
|----------|---------|
| [architecture.md](architecture.md) | Modules, responsibilities, data flow |
| [game_rules.md](game_rules.md) | Rules as implemented (source of truth) |
| [balancing.md](balancing.md) | Tunable values and what they control |
| [playtest_phase1.md](playtest_phase1.md) | Gate 1 playtest protocol and results sheet |
| [release_checklist.md](release_checklist.md) | Package ID, signing and store submission notes |
| [decisions/](decisions/) | Decision records |

Decision records:
- [0001 — Test framework and pinned Godot version](decisions/0001-test-framework-and-godot-version.md)
- [0002 — Save format](decisions/0002-save-format.md)
- [0003 — Art direction](decisions/0003-art-direction.md)

Product spec and roadmap (French): [`../CAHIER_DES_CHARGES.md`](../CAHIER_DES_CHARGES.md), [`../STEPS.md`](../STEPS.md).

## Commands

Run the tests (Godot 4.7 binary in `GODOT`):

```sh
GODOT=/path/to/godot ./run_tests.sh
```

Export a debug APK and install it on a USB-connected phone:

```sh
mkdir -p build
godot --headless --path . --export-debug "Android" build/doppel-prototype.apk
adb install -r build/doppel-prototype.apk
```

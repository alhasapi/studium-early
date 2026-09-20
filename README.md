# Studium

Child-friendly Luanti activities for arithmetic, English, and visual logic.

Studium is a collection of Luanti mods and does not include Luanti or Minetest Game.
Install Luanti separately, then run the platform installer or copy the `mods/edu_*` directories into your Luanti mods directory.

Open the activity toolbox with `/edu_menu`.

## Modules

| Mod | What it is |
| --- | --- |
| `edu_core` | The toolbox, block picker, content registry, task blocks, and progress storage. Every other module depends on it. |
| `edu_number_blocks` | Physical arithmetic: place number and operation blocks to complete an equation. |
| `edu_english_blocks` | Physical spelling: build the word for a picture from letter blocks. |
| `edu_logic_blocks` | Physical patterns: place the colour block that comes next. |
| `edu_arithmetic` | A reading-and-typing arithmetic kiosk, reached with `/edu_kiosk`. Kept for older children and teachers; it is deliberately not in the child toolbox. |

Only `edu_arithmetic` needs Minetest Game. The rest depend only on `edu_core`
and run on any game.

Exercises come from versioned content packs validated at load time, so adding
words, equations, and patterns is a data change rather than a code change. See
[docs/localization.md](docs/localization.md) for how content locales and
translations work.

## Development tests

From Linux/macOS:

```sh
./tests/run.sh
```

See [Linux installation](docs/install-linux.md), [Windows installation](docs/install-windows.md), [testing](docs/testing.md), and [localization](docs/localization.md).

## License

Studium is released under the [MIT License](LICENSE), covering its Lua code, content data, and original assets.

Each `mods/edu_*` directory ships its own copy of the license as `license.txt`, so a mod stays licensed when it is copied into a Luanti `mods` folder on its own.

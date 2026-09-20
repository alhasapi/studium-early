# Localization

Studium is English-first, but nothing that a child or teacher reads should be
hard-coded outside the translation system. Only English content exists today;
the point of the scaffolding below is that adding a language is a content job,
not a code change.

## Marking strings

Wrap every user-facing string in the mod's translator:

```lua
local S = minetest.get_translator("edu_number_blocks")

minetest.chat_send_player(name, S("Not yet. Try a different number block."))
```

Strings that end up inside a formspec are wrapped at the text, not at the whole
formspec element, so the layout stays in code:

```lua
"button[1,4.1;2.5,0.8;check;" .. S("Check answer") .. "]"
```

Placeholders use Luanti's `@1`, `@2` form:

```lua
S("Solved: @1   Attempts: @2", progress.solved, progress.attempts)
```

Do **not** translate:

- `minetest.log` messages, which are for server operators.
- Node names, item names, and formspec field names, which are identifiers.
- Content data. A content pack declares its own `locale` field; translated
  exercise text belongs in a separate pack for that locale rather than in the
  code.

`tests/run.sh` fails if a mod's template is out of date, so a string that is
added without regenerating the template is caught rather than silently missed.

## Regenerating templates

Each mod ships `locale/template.pot`, generated from its `S()` calls:

```sh
./tools/update-locale.sh
```

This requires `xgettext` from the `gettext` package. The output is generated
with `--no-location` and a pinned creation date so that regenerating produces an
identical file: a diff means the translatable strings actually changed.

## Adding a language

1. Copy the mod's template:

   ```sh
   cp mods/edu_number_blocks/locale/template.pot mods/edu_number_blocks/locale/de.po
   ```

2. Fill in the header — at minimum `Language:` and `Content-Type` with
   `charset=UTF-8`, and remove the `fuzzy` flag if it is present.

3. Translate every `msgstr`. Leave `msgid` untouched.

4. Run `./tests/run.sh` to confirm nothing is stale, then set the Luanti
   `language` setting to the new code and check the toolbox in game.

Luanti loads `locale/<language>.po` at startup and applies it to `S()` calls in
that mod. A `.po` file that fails to parse is reported in the server log at
startup, which `./tests/live_smoke.sh` surfaces as a failure.

## Content

Exercise text is not extracted from code. The `early_en` pack under
`mods/edu_core/content/` is English, and a pack declares the locale it is
written in:

```lua
return {id = "early_en_foundations", version = 1, locale = "en", items = { ... }}
```

Task types are deliberately picture-led and low-reading, so most of what a child
needs is an image and a sound rather than a sentence. Picture cues are resolved
against the mod's own textures, and a cue with no texture is reported in the
server log at startup with the exact file name to add.

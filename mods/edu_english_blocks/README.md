# edu_english_blocks

Physical spelling puzzles. The board shows a picture and the child builds the
word from letter blocks; the word is checked automatically once every slot is
filled. Right-click the board to check again.

Use `/edu_english` (or `/edu_english_blocks`) while testing to receive the board
and A-Z letter blocks.

The mod ships a picture and a texture for each of 26 words. Content packs extend
that vocabulary rather than replacing it: an `english` / `word_spelling` item
supplies the word and a picture cue, and the mod only ever publishes a picture
node for a cue it has a texture for. A cue with no texture is reported in the
server log at startup with the exact file name to add.

Placement is deliberately forgiving: a letter is accepted anywhere in a small
window around its slot, and the window is shared by reading, clearing and the
automatic check so they cannot disagree.

## Automated tests

```sh
mods/edu_english_blocks/tests/run.sh
```

Covers word matching, the automatic check, picture-cue resolution, that every
built-in word survives a content pack, that no immediate repeat is served, and
that a dug board takes its letters and picture with it.

# edu_logic_blocks

Physical pattern puzzles. The board lays out a colour sequence with one blank
slot, and the child places the colour block that comes next.

Use `/edu_logic` while testing to receive the board and the four colour blocks.

Patterns come from the `logic` / `visual_pattern` items of the loaded content
packs; when no pack supplies any, three built-in patterns are used. The answer
slot follows the pattern, so patterns of any accepted length between 2 and
`content.MAX_PATTERN_SEQUENCE` are laid out correctly.

The board accepts a colour placed slightly off the slot, but skips the pattern's
own row, and never mistakes the question marker for an answer.

## Automated tests

```sh
mods/edu_logic_blocks/tests/run.sh
```

Covers answer checking including off-slot placement, the question marker not
counting as an answer, and layouts for both a two-item and a four-item pattern.

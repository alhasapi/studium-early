# edu_number_blocks

Physical arithmetic puzzles. Place a board, then assemble the missing number
from number and operation blocks beside it. The board checks the answer
automatically once a block is placed, and rotates to a new equation when it is
right.

Use `/edu_blocks` while testing to receive a board and the blocks.

Equations come from the `math` items of the loaded content packs. When no pack
supplies any, the mod generates addition and subtraction within 10 instead.
Solving an equation counts against that equation's `skill`, so progress is
tracked per skill as well as overall.

## Automated tests

Run from the repository root:

```sh
mods/edu_number_blocks/tests/run.sh
```

The suite covers deterministic addition/subtraction generation, non-negative
subtraction, two-digit answers, node parsing, wrong answers, 500 random
puzzles, content selection, and board cleanup when a board is dug.

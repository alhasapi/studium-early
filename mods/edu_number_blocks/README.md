# edu_number_blocks

Physical arithmetic puzzle prototype. Place a puzzle board, then assemble an
expression from number and operation blocks beside it.

Use `/edu_blocks` while testing to receive a board and all required blocks.

## Automated tests

Run the pure logic regression suite from the repository root:

```sh
mods/edu_number_blocks/tests/run.sh
```

The suite covers deterministic addition/subtraction generation, non-negative
subtraction, two-digit answers, node parsing, wrong answers, and 500 random
puzzles.

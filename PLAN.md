# Studium early-learning content expansion plan

## Summary
Expand Studium from three narrow prototypes into a data-driven, English-first learning platform for ages 4–8. Use broadly shared international foundations rather than one national curriculum, and use the textbooks as private references for extracting and curating original exercise data. Do not commit scans, OCR text, or copied textbook pages to the public repository.

The child-facing experience remains physical-block-first, picture-led, low-reading, and adaptive rather than exposing age labels or requiring menu navigation.

## Current findings
- `edu_number_blocks` currently generates only addition/subtraction with operands 0–10 and has limited answer composition support.
- `edu_english_blocks` currently supports fixed whole-word spelling from a small A–Z word list.
- `edu_logic_blocks` currently supports only a few three-item color patterns.
- Each module owns much of its content and progression logic; shared `edu_core` already handles the toolbox, palette, persistence primitives, and inventory behavior.
- Existing pure logic and integration tests provide a good boundary for moving content into data files.

## Target learning coverage

### Math
Add a progression of manipulable activities covering:
1. Counting objects and matching quantities to numerals.
2. Number recognition, ordering, comparison, greater/less/equal.
3. One-to-one correspondence and composing/decomposing numbers.
4. Addition and subtraction within 5, 10, 20, then larger values.
5. Missing-number equations and number bonds.
6. Place value and two-digit numbers.
7. Repeating patterns and skip counting.
8. Shapes, sorting, symmetry, position, size, and spatial language.
9. Informal measurement, calendars/time, and simple money recognition as later content.

The existing arithmetic board should become one activity type among several rather than the entire math module.

### English
Keep English as the first language, while making the content layer localization-ready:
1. Picture-to-word vocabulary for familiar objects, animals, actions, colors, and places.
2. Letter recognition and uppercase/lowercase matching.
3. Initial sounds and phoneme awareness.
4. CVC word construction and blending.
5. Word families and rhyming.
6. High-frequency/sight words.
7. Plurals, opposites, categories, and simple descriptive words.
8. Sentence ordering with picture support.
9. Basic punctuation and short picture-based comprehension.

Activities should distinguish a child recognizing a word, hearing a sound, spelling with blocks, and understanding meaning; these should not all be represented as the current exact-spelling board.

### Visual logic
Expand beyond the current color patterns with:
1. Sorting by color, shape, size, and category.
2. AB, AAB, ABB, ABC, and growing/repeating patterns.
3. Missing item in a sequence.
4. Matching and visual analogy.
5. Ordering by size, length, or position.
6. Spatial relations and simple rotations/mirroring.
7. Rule-following and “which one does not belong?” tasks.
8. Beginner sequencing and cause/effect tasks represented visually, not as text or code.

## Content/data architecture

1. Introduce a shared, versioned content schema under a dedicated content directory, keeping educational content separate from Luanti Game and from activity implementation.
2. Represent each exercise with fields equivalent to:
   - stable ID and domain/skill;
   - difficulty/progression band;
   - prompt type and picture/sound cues;
   - board layout and accepted physical answers;
   - distractors;
   - success/failure feedback assets;
   - optional prerequisite and accessibility metadata;
   - provenance/reviewer notes that identify the private source without copying it.
3. Keep the initial runtime format simple and Lua-loadable; define a conversion path from reviewed CSV/JSON if textbook extraction later becomes large.
4. Add validation that rejects malformed IDs, duplicate items, missing assets, invalid answers, impossible arithmetic, and unsupported node names before runtime.
5. Make locale a content-pack field even though only English is implemented initially. Avoid embedding English strings into generic activity logic.

## Textbook extraction workflow

1. Keep scans/OCR outside the repository.
2. Use OCR only as an extraction aid; manually review every exercise and rewrite it into Studium’s own child-facing form.
3. Extract concepts and difficulty, not page layout or copyrighted illustrations.
4. Prefer original pictures, icons, sounds, and generated layouts for the public game.
5. Store a lightweight provenance record such as source book identifier, topic, and review status without redistributing protected material.
6. Start with a small reviewed sample per skill, run it in-game, then expand batches once the schema and interaction patterns are stable.

## Runtime changes

1. Add a shared activity/content registry so the toolbox can launch a domain activity without resetting an existing board/task.
2. Refactor each module to select from validated content records instead of hard-coded arrays or random formulas.
3. Give each activity a common interface for:
   - creating a task;
   - rendering its physical board;
   - recognizing tolerant placements;
   - checking answers;
   - choosing the next task;
   - reporting attempts and solved skills.
4. Preserve current physical behavior: boards first, blocks in inventory/hotbar, automatic checks when appropriate, forgiving placement, and visual/audio feedback.
5. Keep the current-task toolbox shortcut and make its block palette reflect the active task’s allowed block categories where possible.
6. Add adaptive selection internally: begin with the easiest eligible task, promote after repeated success, retry with a simpler or visually clearer variant after failure, and avoid repeating the same task immediately.
7. Persist progress by player and skill, not only a global solved count. Keep unknown/old progress data backward compatible.

## Suggested implementation phases

### Phase 1: content foundation
- Define the content schema and validator.
- Add a small hand-curated sample pack for each existing module.
- Add loader and deterministic content selection.
- Add schema/unit tests and retain current regression tests.

### Phase 2: math breadth
- Add counting, comparison, number bonds, missing-number, and shape/sorting task types.
- Extend arithmetic to configurable ranges and multi-digit answers.
- Add adaptive skill progression and per-skill persistence.

### Phase 3: English breadth
- Split vocabulary, phonics, spelling, and sentence activities.
- Add sound/picture metadata and tolerant accepted answers where appropriate.
- Add CVC, rhyming, categories, and simple sentence ordering.

### Phase 4: logic breadth
- Generalize pattern records and add classification, missing-item, ordering, and spatial task types.
- Add generated pattern families plus curated examples and distractors.

### Phase 5: authoring and release workflow
- Add a documented spreadsheet/JSON-to-Lua conversion workflow.
- Add batch validation and content reports.
- Add CI for schema validation, syntax, unit/integration/regression tests, and live smoke testing.
- Package reviewed content separately from private source material.

## Testing and acceptance criteria

- Every new task type has pure logic tests for correct, incorrect, incomplete, malformed, and boundary answers.
- Every physical activity has integration tests for board creation, tolerant placement, automatic checking, feedback, and task transition.
- Content validation runs over every content pack and reports the exact item ID for failures.
- Deterministic seeds test adaptive promotion, retry/demotion, no immediate repetition, and saved progress across reconnects.
- Live smoke testing confirms all mods load with a temporary SQLite world and no runtime errors.
- Manual acceptance checks confirm a non-reader can understand the task from blocks, icons, sounds, and particles without commands, inventory searching, or mandatory right-click use.
- Existing arithmetic, English, logic, toolbox, and current-task behavior remain regression-covered.

## Explicit assumptions

- “General” means broadly shared international early-primary foundations, not strict compliance with one country’s standards.
- Textbook scans and OCR are private working material; only original curated data and original assets enter the public repository.
- English remains the first fully implemented language, but the schema and UI boundaries avoid making future localization expensive.
- Adaptive progression is primarily internal; children should see concrete visual tasks rather than curriculum labels.
- The first content migration should be small and reviewed before building a large importer or attempting full-book extraction.

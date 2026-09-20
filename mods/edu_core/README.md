# edu_core

Shared foundation for Studium. Every activity mod depends on this one.

It provides:

- **The toolbox** (`/edu_menu` or the `edu_core:toolbox` item), the child's entry
  point, with one button per activity domain.
- **The block picker**, which mirrors a page of blocks into the hotbar.
- **Task blocks**: activities publish the blocks their current task calls for
  with `edu.set_task_blocks(name, nodes)`, and the picker offers that small
  deliberate set instead of the whole category until the task changes.
- **The content registry** in `content.lua`, a validator plus `find`, `pick`,
  `task_blocks` and `choose` helpers shared by every activity.
- **Progress storage**: `edu.record_result(name, skill, correct)` advances both
  the player's overall counter and a per-skill one; `edu.get_progress` and
  `edu.get_skill_progress` read them.

`content.lua` deliberately uses no Luanti API so content packs and the selection
rules can be tested in plain Lua.

The starter content pack lives in `content/early_en.lua`. See
[docs/localization.md](../../docs/localization.md) for how locale and
translation work.

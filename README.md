# Overflow

Overflow is a SMODS + Lovely Balatro mod that adds stack-aware consumeable behavior.
Duplicate consumeables can merge into quantity stacks, with UI actions for split/merge/bulk use.

## Features

- Stack duplicate consumeables with quantity tracking (`card.qty`)
- Slot-aware stack limits (`fix_slots`) and synced consumeable count label
- Bulk use and mass use flows for supported consumeables
- Stack badge UI and stack actions (split one, split half, merge, merge all)
- Vanilla ownership integrations: `j_perkeo`, `observatory`, `j_constellation`

## Current Architecture

- Entry/runtime files: `main.lua`, `Overflow.lua`, `lovely/modules.toml`, `lovely/fixes.toml`
- Runtime modules: `src/core/*`, `src/hooks/*`, `src/ui/*`, `src/integrations/*`

Legacy `modules/*` files are removed.

## Config

Saved at `config/Overflow.lua` with keys:
- `only_stack_negatives`
- `fix_slots`
- `require_sellvalue`
- `indicator_pos`
- `sorting_mode` (mapped to `{1,2,6,7,11}`)

`require_edition` is not part of the config.

## Compatibility Hooks Kept

Overflow intentionally keeps optional integration hooks when those mods/APIs exist:
- MP lobby behavior checks
- `cry_multiuse` handling
- Talisman/Handy animation-skip checks
- DebugPlus key-handler patch path
- External bulk-use extension points: `Overflow.blacklist`, `Overflow.mass_use_sets`, `Overflow.bulk_use_caps`, center callbacks (`bulk_use`, `can_bulk_use`, `bulk_use_cap`)

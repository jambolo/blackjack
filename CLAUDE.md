# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Blackjack analysis tools written in Julia. Simulates card dealing from multi-deck shoes to compute probabilities (card densities by count, next-card outcome distributions, dealer outcomes, etc.). Results are written to JSON files under `data/` and summarized to the console.

## Common Commands

All commands are run from the repository root. Julia ≥ 1.6.7 is required (see [Project.toml](Project.toml)).

Install/resolve dependencies:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Run a script (example):

```bash
julia --project=. scripts/generate-card-density-by-count.jl
```

Run the test suite:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Architecture

The `Blackjack` package is one top-level module composed of four submodules. All submodules `include("Cards.jl")` independently — `Cards` is deliberately a leaf module with no dependencies and is safe to include multiple times because Julia resolves each `.Cards` reference within its own enclosing module.

- **[src/Blackjack.jl](src/Blackjack.jl)** — top-level module. Exposes `Configuration`, `DEFAULT_CONFIGURATION` (6 decks, 1.5-deck penetration, a standard H17/DAS rule set), and `BUST = 22` (arbitrary bust sentinel chosen to simplify array indexing).
- **[src/Cards.jl](src/Cards.jl)** — card constants. Cards are represented as `Int` values `1..13` where `1 = ACE`, `11 = JACK`, `12 = QUEEN`, `13 = KING`. `DECK_SIZE = 52`.
- **[src/Rules.jl](src/Rules.jl)** — `RuleSet` struct, blackjack `value(card)` and `value(hand) → (soft, total)`, and `dealer_must_hit`. In this module `value` collapses J/Q/K to 10 and treats Ace as 1 or 11 depending on hand total.
- **[src/HiLo.jl](src/HiLo.jl)** — Hi-Lo counting system. `LOW_CARDS = [2..6]` (+1), `NEUTRAL_CARDS = [7..9]` (0), `HIGH_CARDS = [ACE, 10, J, Q, K]` (−1). `value(card)` here returns the *count* value, not the blackjack value — be careful not to confuse with `Rules.value`.
- **[src/Shoes.jl](src/Shoes.jl)** — mutable `Shoe` struct tracking cards, dealt index, penetration `limit`, and `running_count`. Core operations: `shuffle!`, `deal!`, `deal_value!`, `remaining`, `true_count`, `done`. `true_count` divides running count by *remaining decks* (remaining cards / 52).

### Scripts

Scripts in `scripts/` are executable analyses, not library code. They typically:

1. Use `Blackjack.DEFAULT_CONFIGURATION`.
2. Run a large Monte Carlo simulation (e.g. 10M or 100M shoes).
3. Write raw results to `data/*.json`.
4. Print a human-readable summary table (via `DataFrames` and `PrettyTables`) to the console.

When adding a new script, follow this pattern and keep the JSON output key set aligned with the existing files in `data/`.

### Script conventions

Each script follows a consistent structure and output pattern:

1. **Header docstring** — open with `println("""...""")` briefly describing what the script computes and where output goes.
2. **Rules printout** — if the script uses `configuration.RULES`, print them immediately after: `println(Blackjack.Rules.deconstruct(configuration.RULES))`.
3. **Progress logging** — report progress every 10% of shoes: `if s % (NUMBER_OF_SHOES ÷ 10) == 0; println("$(round(Int, s / NUMBER_OF_SHOES * 100))% of $NUMBER_OF_SHOES_STR shoes."); end`.
4. **JSON output** — write raw results to `data/<kebab-case>.json` via `open(...) do io; JSON.print(io, ...); end`. Top-level JSON objects include `number_of_shoes` and `configuration` alongside the data payload.
5. **Console summary** — print a human-readable table using `DataFrame` + `println(df)` after writing JSON.

Shared local helpers used across scripts (define inline, not in the library):

- `to_percent(x, digits=0) = round(x * 100, digits=digits)` — convert a fraction to a display percentage.
- `count_index(c) = c + COUNT_RANGE + 1` — map a signed count value to a 1-based array index.

## Conventions

- Julia version compat is pinned in [Project.toml](Project.toml). Don't bump it casually — the codebase targets Julia 1.6.7+.
- Docstrings on exported functions/types follow the `"""` + `### Arguments` / `### Returns` style already in use. Match it for new additions.
- The `BUST` constant is `22` by design (acts as a valid array index for outcome tables 2..22). Preserve this when porting outcome-distribution logic.

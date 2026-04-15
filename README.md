# Blackjack

Tools for the analysis of Blackjack, written in Julia.

![CI](https://github.com/jambolo/blackjack/actions/workflows/CI.yml/badge.svg)
[![codecov](https://codecov.io/gh/jambolo/blackjack/branch/master/graph/badge.svg)](https://codecov.io/gh/jambolo/blackjack)
[![Julia](https://img.shields.io/badge/julia-%3E%3D1.12-blue)](https://julialang.org)

## Executables

### generate-card-density-by-count.jl

Dealing each card from a 6-deck shoe up to the penetration limit is simulated 10,000,000 times. For each count, the
average density of each card (1-13) in the remaining shoe is computed. Results are written to the file
`data/card-densities-by-count.json`. A summary is written to the console.

### generate-next-card-outcome-distribution.jl

Computes the probabilities of each outcome for each possible hand after taking one card. Hands with a score of 6 through 10 treat and Ace as 11, while the rest treat it as a 1. Specific card combinations are not considered. The shoe is assumed to have an infinite number of decks.

### generate-dealer-outcome-distribution.jl

Simulates many shoes and records the dealer's final score for each possible up-card. Dealer blackjacks are excluded when `DEALER_CHECKS_FOR_BLACKJACK` is enabled. Results are written to the file `data/dealer-outcome-distribution.json`. A summary is written to the console as percentages by up-card (Ace through 10) and outcome (17–21, Bust).

### generate-count-probability-data.jl

Simulates many shoes and records the true count at the midpoint of each shoe (after dealing half the cards). The resulting probability distribution is written to `data/count-probabilities.json`. A summary table of counts with non-zero frequency is printed to the console.

### generate-true-count-distribution.jl

Simulates many shoes and records the true count after every card dealt up to the penetration limit. The distribution is normalized by the total number of cards dealt and written to `data/true-count-distribution.json`. A summary table for counts −20 to +20 is printed to the console.

### generate-dealer-blackjack-probabilities.jl

Computes the probability of a dealer blackjack for each count without simulation, by summing the 10-value card densities from `data/card-densities-by-count.json`. Results are written to `data/dealer-blackjack-probabilities-by-count.json` and summarized to the console.

## Data

All generated JSON files include a shared `configuration` object:

```text
configuration.DECKS_PER_SHOE                       Int
configuration.PENETRATION                          Float
configuration.RULES.DEALER_MUST_HIT_SOFT_17        Bool
configuration.RULES.DEALER_CHECKS_FOR_BLACKJACK    Bool
configuration.RULES.DOUBLE_AFTER_SPLIT_ALLOWED     Bool
configuration.RULES.RESPLIT_ACES_ALLOWED           Bool
configuration.RULES.HIT_SPLIT_ACES_ALLOWED         Bool
configuration.RULES.SURRENDER_ALLOWED              Bool
configuration.RULES.MAX_SPLIT_HANDS                Int
configuration.RULES.BLACKJACK_PAYOFF               Float
```

**Count indexing** (shared by all count-indexed arrays): array length is `2 × COUNT_RANGE + 1`
where `COUNT_RANGE = COUNT_RANGE_PER_DECK × DECKS_PER_SHOE = 20 × 6 = 120` for the default
6-deck shoe, giving 241 elements. Convert a signed true count `c` to a 1-based array index
with `i = c + COUNT_RANGE + 1`.

### card-densities-by-count.json

```text
number_of_shoes                        Int
configuration                          (see above)
card_densities_by_count[r][i]          Float64
```

- Outer index `r` (1–13): card rank (1=Ace, 2–10=pip, 11=Jack, 12=Queen, 13=King)
- Inner index `i` (1–241): true-count index (see count indexing above)
- Value: average fraction of the remaining shoe that is rank `r` at that count

### count-probabilities.json

```text
number_of_shoes                        Int
configuration                          (see above)
count_probabilities[i]                 Float64
```

- Index `i` (1–241): true-count index
- Value: probability of that true count at the midpoint (half-deck penetration) of a shoe

### dealer-blackjack-probabilities-by-count.json

```text
configuration                          (see above)
dealer_blackjack_probabilities_by_count[i]   Float64
```

- Index `i` (1–241): true-count index
- Value: probability of a dealer blackjack at that count, computed analytically from
  `card-densities-by-count.json` (not simulated)

### dealer-outcome-distribution.json

```text
number_of_shoes                        Int
configuration                          (see above)
dealer_outcome_distribution[s][u]      Float64
```

- Outer index `s` (1–22): dealer final score (1–21 = point total; 22 = BUST sentinel,
  matching the `BUST` constant in the library)
- Inner index `u` (1–10): dealer upcard value (1=Ace, 2–10=pip/ten; J/Q/K collapse to 10)
- Value: `P(dealer ends at score s | upcard u)`, aggregated over all counts;
  sums to 1.0 over `s` for each `u`
- Note: dealer blackjacks are excluded when `DEALER_CHECKS_FOR_BLACKJACK` is enabled

### next-card-outcome-distribution.json

```text
number_of_shoes                        Int
configuration                          (see above)
next_card_outcome_distribution[s][h]   Float64
```

- Outer index `s` (1–22): outcome score after drawing one card (1–21 = point total; 22 = BUST)
- Inner index `h` (1–20): starting hand score before drawing (1–20); starting scores 6–10
  treat the Ace as 11, all others treat it as 1
- Value: `P(outcome=s | starting hand score=h)`; sums to 1.0 over `s` for each valid `h`
  (index 1 is unused — no valid two-card hand has score 1)

### true-count-distribution.json

```text
number_of_shoes                        Int
configuration                          (see above)
true_count_distribution[i]             Float64
```

- Index `i` (1–241): true-count index
- Value: fraction of all cards dealt at that true count, normalized by the total number of
  cards dealt across all shoes up to the penetration limit

### kings-bounty-analysis.json

```text
number_of_shoes                        Int
number_of_hands                        Int
configuration                          (see above)
payouts                                Dict<outcome_name, Int>
frequencies                            Dict<outcome_name, Int>
frequencies_by_count[i]                Dict<outcome_name, Int>   (length 241)
frequencies_by_ten_count[t]            Dict<outcome_name, Int>   (length 97)
frequencies_by_king_count[k]           Dict<outcome_name, Int>   (length 25)
count_frequencies[i]                   Int                       (length 241)
ten_count_frequencies[t]               Int                       (length 97)
king_count_frequencies[k]              Int                       (length 25)
```

- `payouts` / `frequencies` / `frequencies_by_*`: keyed by outcome name:
  `"Kings of Spades"`, `"Kings of Spades + BJ"`, `"Suited 20"`, `"Suited Kings"`,
  `"Suited Q/J/10"`, `"Unsuited 20"`, `"Unsuited Kings"`, `"Other"`
- `frequencies_by_count[i]`: indexed by true-count (same scheme as above)
- `frequencies_by_ten_count[t]`: indexed by true ten-count `t` (1-based, range 0–96;
  `TEN_COUNT_RANGE = 4 × NUMBER_OF_SUITS × DECKS_PER_SHOE = 96`)
- `frequencies_by_king_count[k]`: indexed by true king-count `k` (1-based, range 0–24;
  `KING_COUNT_RANGE = NUMBER_OF_SUITS × DECKS_PER_SHOE = 24`)
- `*_frequencies` arrays: hand count at each index (denominator for computing probabilities)

### Strategy Files

Four files encode basic strategy for different rule combinations (4–8 decks, American style,
double-after-split always allowed):

|       File        | Dealer soft 17 | Surrender |
|:------------------|:---------------|:----------|
| `H17-DAS-LS.json` | Hits           | Late      |
| `H17-DAS-NS.json` | Hits           | None      |
| `S17-DAS-LS.json` | Stands         | Late      |
| `S17-DAS-NS.json` | Stands         | None      |

```text
meta.decks                             String  ("4-8")
meta.style                             String  ("American")
meta.dealer_stands_on_soft_17          Bool
meta.double_after_split_allowed        Bool
meta.surrender_allowed                 Bool
meta.surrender_type                    String  (only present when surrender_allowed)
dealer_upcards                         Array[10] of String  ["2","3","4","5","6","7","8","9","10","A"]
actions.hard[total][upcard]            String  action code; total keys "5"–"21"
actions.soft[total][upcard]            String  action code; total keys "13"–"21"
actions.pair[card][upcard]             String  action code; card keys "2"–"10","A"
legend                                 Dict<action_code, description>
```

Upcard keys in all action tables: `"2"`, `"3"`, `"4"`, `"5"`, `"6"`, `"7"`, `"8"`, `"9"`,
`"10"`, `"A"`.

Action codes:

| Code |                Meaning                 |
|------|:---------------------------------------|
| `H`  | Hit                                    |
| `S`  | Stand                                  |
| `P`  | Split                                  |
| `Dh` | Double if possible, otherwise Hit      |
| `Ds` | Double if possible, otherwise Stand    |
| `Rh` | Surrender if possible, otherwise Hit   |
| `Rs` | Surrender if possible, otherwise Stand |
| `Rp` | Surrender if possible, otherwise Split |

## Summaries

Analysis result summaries and tables are in [summaries.md](summaries.md).

## King's Bounty Analysis

King's Bounty Analysis is here: [King's Bounty Analysis](kings-bounty-analysis.md)

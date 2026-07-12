# SPDX-License-Identifier: MIT

module Strategy

using JSON

include("Cards.jl")
using .Cards
include("Rules.jl")
using .Rules

# The hand-authored strategy tables live in the repository's data/ directory (see README.md).
const DATA_DIR = normpath(joinpath(@__DIR__, "..", "data"))

"""
    load_table(path::AbstractString)

Loads a basic-strategy table from a JSON file. The schema is documented in README.md.

### Arguments
- `path::AbstractString`: The path of a strategy table file (e.g. `data/H17-DAS-NS.json`).

### Returns
- The parsed strategy table.
"""
load_table(path::AbstractString) = JSON.parsefile(path)

"""
    table_for(rules; dir=DATA_DIR)

Loads the basic-strategy table matching the given rules. Tables are provided for every combination
of dealer-hits-soft-17 and surrender-allowed; all of them assume double-after-split is allowed.

### Arguments
- `rules`: The rules of the Blackjack game (a `Rules.RuleSet`). Untyped because each module includes
  its own instance of `Rules`, making `RuleSet` a different type in each (see CLAUDE.md).
- `dir`: The directory containing the strategy tables. Defaults to the repository's `data/` directory.

### Returns
- The parsed strategy table matching the rules.
"""
function table_for(rules; dir::AbstractString = DATA_DIR)
    if !rules.DOUBLE_AFTER_SPLIT_ALLOWED
        throw(ArgumentError("all strategy tables assume double-after-split is allowed"))
    end
    soft17 = rules.DEALER_MUST_HIT_SOFT_17 ? "H17" : "S17"
    surrender = rules.SURRENDER_ALLOWED ? "LS" : "NS"
    return load_table(joinpath(dir, "$(soft17)-DAS-$(surrender).json"))
end

# Maps a card value to its key in a strategy table's action maps.
value_key(v::Int) = v == ACE ? "A" : string(v)

"""
    player_action(table, hand::Vector{Int}, upcard::Int)

Looks up the basic-strategy action for a player's hand against a dealer's upcard. A two-card pair is
looked up in the pair table (splitting is assumed to be available), a soft hand in the soft table,
and any other hand in the hard table.

### Arguments
- `table`: A strategy table returned by `load_table` or `table_for`.
- `hand::Vector{Int}`: The player's hand as cards in the range ACE:KING (Jack through King count as 10).
- `upcard::Int`: The dealer's upcard as a card in the range ACE:KING.

### Returns
- The action code as a `String`: `"H"` (hit), `"S"` (stand), `"P"` (split), `"Dh"`/`"Ds"` (double if
  possible, otherwise hit/stand), or `"Rh"`/`"Rs"`/`"Rp"` (surrender if possible, otherwise
  hit/stand/split). The table's `legend` describes each code.
"""
function player_action(table, hand::Vector{Int}, upcard::Int)
    if length(hand) < 2
        throw(ArgumentError("hand must contain at least 2 cards"))
    end
    if !all(c -> ACE ≤ c ≤ KING, hand)
        throw(ArgumentError("hand cards must be in the range ACE:KING"))
    end
    if !(ACE ≤ upcard ≤ KING)
        throw(ArgumentError("upcard must be in the range ACE:KING"))
    end

    actions = table["actions"]
    up = value_key(Rules.value(upcard))

    if length(hand) == 2 && Rules.value(hand[1]) == Rules.value(hand[2])
        return actions["pair"][value_key(Rules.value(hand[1]))][up]
    end

    soft, total = Rules.value(hand)
    if total > 21
        throw(ArgumentError("hand is busted"))
    end
    return actions[soft ? "soft" : "hard"][string(total)][up]
end

end # module Strategy

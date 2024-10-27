# SPDX-License-Identifier: MIT


module Blackjack

export COUNT_RANGE_PER_DECK, BUST, LOW_CARDS, UNCOUNTED_CARDS, HIGH_CARDS
export NUMBER_OF_SUITS, NUMBER_OF_CARDS_PER_SUIT, DECK_SIZE, ACE, JACK, QUEEN, KING

include("Cards.jl")
using .Cards
include("Rules.jl")
using .Rules
include("HiLo.jl")
using .HiLo
include("Shoes.jl")
using .Shoes

"""
    BUST

An arbitrary value that represents a bust. 22 is chosen because it makes array indexing easier.
"""
const BUST = 22

"""
    Configuration

A struct representing the configuration of a Blackjack game.

### Fields
- `DECKS_PER_SHOE::Int`: The number of decks used in a shoe.
- `PENETRATION::Float64`: The penetration level, indicating how many decks are not dealt.
- `RULES::Rules`: An instance of the `Rules` struct that defines the rules of the game.
"""
struct Configuration
    DECKS_PER_SHOE::Int
    PENETRATION::Float64
    RULES::Rules.RuleSet
end

"""
    DEFAULT_CONFIGURATION

A typical configuration.

### Fields
- `DECKS_PER_SHOE`: The number of decks used in a shoe is 6.
- `PENETRATION`: The penetration level is 1.5.
- `RULES`: The rules of the game with the following settings:
    - `DEALER_MUST_HIT_SOFT_17`: true
    - `DEALER_CHECKS_FOR_BLACKJACK`: true
    - `DOUBLE_AFTER_SPLIT_ALLOWED`: true
    - `RESPLIT_ACES_ALLOWED`: false
    - `HIT_SPLIT_ACES_ALLOWED`: false
    - `SURRENDER_ALLOWED`: false
    - `MAX_SPLIT_HANDS`: 4
    - `BLACKJACK_PAYOFF`: 1.5
"""
const DEFAULT_CONFIGURATION = Configuration(6, 1.5, Rules.RuleSet(true, true, true, false, false, false, 4, 1.5))

end # module Blackjack

# SPDX-License-Identifier: MIT

module Rules

include("Cards.jl")
using .Cards

"""
    struct RuleSet

A struct representing the rules of a Blackjack game.

### Fields
- `DEALER_MUST_HIT_SOFT_17::Bool`: Indicates if the dealer must hit on a soft 17.
- `DEALER_CHECKS_FOR_BLACKJACK::Bool`: Indicates if the dealer checks for Blackjack when a 10 is showing.
- `DOUBLE_AFTER_SPLIT_ALLOWED::Bool`: Indicates if doubling down after a split is allowed.
- `RESPLIT_ACES_ALLOWED::Bool`: Indicates if resplitting aces is allowed.
- `HIT_SPLIT_ACES_ALLOWED::Bool`: Indicates if hitting split aces is allowed.
- `SURRENDER_ALLOWED::Bool`: Indicates if surrendering is allowed.
- `MAX_SPLIT_HANDS::Int`: The maximum times a hand can be split.
- `BLACKJACK_PAYOFF::Float64`: The payoff for a Blackjack.
"""
struct RuleSet
    DEALER_MUST_HIT_SOFT_17::Bool
    DEALER_CHECKS_FOR_BLACKJACK::Bool
    DOUBLE_AFTER_SPLIT_ALLOWED::Bool
    RESPLIT_ACES_ALLOWED::Bool
    HIT_SPLIT_ACES_ALLOWED::Bool
    SURRENDER_ALLOWED::Bool
    MAX_SPLIT_HANDS::Int
    BLACKJACK_PAYOFF::Float64
end

"""
    deconstruct(rules::RuleSet)

### Arguments
- `rules::RuleSet`: The rules of the Blackjack game.

### Returns
- A string deconstructing the given set of rules.
"""
function deconstruct(rules::RuleSet)
    return """
    Dealer must hit soft 17: $(rules.DEALER_MUST_HIT_SOFT_17)
    Dealer checks for blackjack when 10 is showing: $(rules.DEALER_CHECKS_FOR_BLACKJACK)
    Doubling after split is allowed: $(rules.DOUBLE_AFTER_SPLIT_ALLOWED)
    Resplitting aces is allowed: $(rules.RESPLIT_ACES_ALLOWED)
    Hitting split aces is allowed: $(rules.HIT_SPLIT_ACES_ALLOWED)
    Surrender is allowed: $(rules.SURRENDER_ALLOWED)
    Maximum number of split hands: $(rules.MAX_SPLIT_HANDS)
    Blackjack payoff: $(rules.BLACKJACK_PAYOFF)
    """
end

"""
    value(card::Int)

### Arguments
- `card::Int`: A card represented as an integer.

### Returns
- An integer representing the value of the card:
    - 1 for Ace
    - The card for 2-10
    - 10 for Jack, Queen, King
"""
function value(card::Int)
    min(card, 10)
end

"""
    value(hand)

### Arguments
- `hand::Vector{Int}`: A hand represented as an array of cards.

### Returns
- A tuple containing:
    - A boolean indicating if the hand is soft (contains an Ace and the sum of the cards is 11 or less).
    - The value of the hand. If the hand is soft, the ace is given a value of 11.
"""
function value(hand::Vector{Int})
    s = sum(map(value, hand))
    if s ≤ 11 && in(ACE, hand)
        soft = true
        s += 10
    else
        soft = false
    end
    (soft, s)
end

"""
    dealer_must_hit(hand, rules::RuleSet)

### Arguments
- `hand`: The dealer's hand.
- `rules::RuleSet`: The rules of the Blackjack game.

### Returns
- A boolean indicating if the dealer must hit based on the hand and rules.
"""
function dealer_must_hit(hand, rules::RuleSet)
    soft, v = value(hand)
    if v < 17
        must = true
    else 
        must = soft && v == 17 && rules.DEALER_MUST_HIT_SOFT_17
    end
    return must
end

end # module Rules

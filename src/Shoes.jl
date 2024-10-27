# SPDX-License-Identifier: MIT

module Shoes

using Random

include("Cards.jl")
using .Cards
include("HiLo.jl")
using .HiLo
include("Rules.jl")
using .Rules

"""
    Shoe

A mutable struct representing a shoe in a Blackjack game. The shoe contains multiple decks of cards, manages the
dealing of cards, and it tracks the running count.

# Fields
- `cards::Vector{Int}`: The cards in the shoe.
- `limit::Int`: The number of cards to deal before reshuffling.
- `index::Int`: The index of the next card to be dealt.
- `running_count::Int`: The current running count of the shoe.

### Constructor
    Shoe(decks::Int, penetration::Float64)

Creates a new `Shoe` with the specified number of decks and penetration level. The cards are shuffled, and the limit
is set based on the penetration level.

- `decks::Int`: The number of decks in the shoe.
- `penetration::Float64`: The penetration level, indicating how many decks of the shoe are not dealt.
"""
mutable struct Shoe
    cards::Vector{Int}
    limit::Int
    index::Int
    running_count::Int

    function Shoe(decks::Int, penetration::Float64)
        cards = repeat(1:13, decks * NUMBER_OF_SUITS)
        Random.shuffle!(cards)
        limit = ceil(Int, (decks - penetration) * DECK_SIZE)
        return new(cards, limit, 1, 0)
    end
end

"""
    shuffle!(shoe::Shoe)

Shuffles the shoe, resetting the index and running count.

### Arguments
- `shoe::Shoe`: The shoe to shuffle.

### Returns
- The shuffled shoe.
"""
function shuffle!(shoe::Shoe)
    Random.shuffle!(shoe.cards)
    shoe.index = 1
    shoe.running_count = 0
    return shoe
end

"""
    deal(shoe::Shoe)

Deals the next card from the shoe, updating the running count.

### Arguments
- `shoe::Shoe`: The shoe to deal from.

### Returns
- The card dealt.
"""
function deal!(shoe::Shoe)
    card = shoe.cards[shoe.index]
    shoe.index += 1
    shoe.running_count += HiLo.value(card)
    return card
end

"""
    deal_value!(shoe::Shoe)

Deals the next card from the shoe, returning the value of the card instead of the card itself.

### Arguments
- `shoe::Shoe`: The shoe to deal from.

### Returns
- The value of the card dealt (Jack through King have a value of 10).
"""
deal_value!(shoe::Shoe) = Rules.value(deal!(shoe))

# 
"""
    remaining(shoe::Shoe)

### Arguments
- `shoe::Shoe`: The shoe to check.

### Returns
- The number of cards remaining in the shoe, ignoring the penetration limit.
"""
remaining(shoe::Shoe) = length(shoe.cards) - shoe.index + 1

"""
    true_count(shoe::Shoe)

### Arguments
- `shoe::Shoe`: The shoe to check.

### Returns
- The true count of the shoe, calculated as the running count divided by the number of remaining decks. Use round() to
  get an integer value.
"""
true_count(shoe::Shoe) = shoe.running_count / (remaining(shoe) / DECK_SIZE)

"""
    done(shoe::Shoe)

### Arguments
- `shoe::Shoe`: The shoe to check.

### Returns
- A boolean indicating whether the shoe has reached its penetration limit.
"""
done(shoe::Shoe) = shoe.index > shoe.limit

"""
    running_count_after(shoe::Shoe, i)

### Arguments
- `shoe::Shoe`: The shoe to check.
- `i::Int`: The number of cards to consider.

### Returns
- The running count after the first i cards.
"""
running_count_after(shoe::Shoe, i) = sum(HiLo.value(shoe.cards[j]) for j in 1:i)

"""
    true_count_after(shoe::Shoe, i)

### Arguments
- `shoe::Shoe`: The shoe to check.
- `i::Int`: The number of cards to consider.

### Returns
- The true count after the first i cards are dealt, calculated as the running count for the first i cards divided by
  the number of remaining decks. Use round() to get an integer value.
"""
true_count_after(shoe::Shoe, i) = running_count_after(shoe, i) / ((length(shoe.cards) - i) / DECK_SIZE)

end # module Shoes

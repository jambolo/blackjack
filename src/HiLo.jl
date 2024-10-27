# SPDX-License-Identifier: MIT

module HiLo

include("Cards.jl")
using .Cards

export COUNT_RANGE_PER_DECK, LOW_CARDS, UNCOUNTED_CARDS, HIGH_CARDS

"""
    COUNT_RANGE_PER_DECK

The range of possible +/- counts per deck.
"""
const COUNT_RANGE_PER_DECK = 20

"""
    LOW_CARDS

An array of values representing low cards (2 through 6).
"""
const LOW_CARDS = [2, 3, 4, 5, 6]

"""
    UNCOUNTED_CARDS

An array of values representing uncounted cards (7 through 9).
"""
const UNCOUNTED_CARDS = [7, 8, 9]

"""
    HIGH_CARDS

An array of values representing high cards (10, Jack, Queen, King, Ace).
"""
const HIGH_CARDS = [ACE, 10, JACK, QUEEN, KING]

"""
    count_value(card::Int)

### Arguments
- `card::Int`: A card (1-13).

### Returns
- An integer representing the count value for the card:
    - -1 for high cards (10, Jack, Queen, King, Ace)
    - 0 for uncounted cards (7, 8, 9)
    - 1 for low cards (2, 3, 4, 5, 6)
"""
function value(card::Int)
    if card == ACE || card ≥ 10
        value = -1
    elseif card ≤ 6
        value = 1
    else
        value = 0
    end
    return value
end

end # module HiLo
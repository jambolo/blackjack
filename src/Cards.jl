# SPDX-License-Identifier: MIT

module Cards

export NUMBER_OF_SUITS, NUMBER_OF_CARDS_PER_SUIT, DECK_SIZE, ACE, JACK, QUEEN, KING

"""
    NUMBER_OF_SUITS

The number of suits in a standard deck.
"""
const NUMBER_OF_SUITS = 4

"""
    NUMBER_OF_CARDS_PER_SUIT

The number of cards in each suit.
"""
const NUMBER_OF_CARDS_PER_SUIT = 13

"""
    DECK_SIZE

The number of cards in a standard deck.
"""
const DECK_SIZE = NUMBER_OF_CARDS_PER_SUIT * NUMBER_OF_SUITS

"""
    ACE

The value representing an Ace.
"""
const ACE = 1

"""
    JACK

The value representing a Jack.
"""
const JACK = 11

"""
    QUEEN

The value representing a Queen.
"""
const QUEEN = 12

"""
    KING

The value representing a King.
"""
const KING = 13

end # module Cards

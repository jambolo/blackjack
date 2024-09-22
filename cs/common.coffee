# Common constants and functions

DECK_SIZE = 52
COUNT_RANGE_PER_DECK = 20
ACE = 1
JACK = 11
QUEEN = 12
KING = 13
LOW_CARDS = [2, 3, 4, 5, 6]
UNCOUNTED_CARDS = [7, 8, 9]
HIGH_CARDS = [ACE, 10, JACK, QUEEN, KING]

DEFAULT_CONFIGURATION =
  NUMBER_OF_DECKS_PER_SHOE: 6
  NUMBER_OF_SHOES: 100000000
  PENETRATION: 1.0

# Shuffles an array in place.
shuffle = (a) ->
  i = a.length
  while --i > 0
    j = ~~(Math.random() * (i + 1))
    [a[i], a[j]] = [a[j], a[i]]
  return

# Generates a single unshuffled deck of cards.
newUnshuffledDeck = ->
  deck = []
  deck = deck.concat [1..13] for [1..4]
  return deck

# Generates an unshuffled shoe.
newUnshuffledShoe = (size) ->
  shoe = []
  shoe = shoe.concat newUnshuffledDeck() for [0 ... size]
  return shoe

# Generates a shuffled deck of cards.
newDeck = ->
  deck = newUnshuffledDeck()
  shuffle deck
  return deck

# Generates a shuffled shoe.
newShoe = (size) ->
  shoe = newUnshuffledShoe(size)
  shuffle shoe
  return shoe

# Returns the count for the given range of a shoe.
countOf = (shoe, start, n) ->
  count = 0
  for card in shoe[start ... start + n]
    count += if HIGH_CARDS.indexOf(card) != -1 then 1 else if LOW_CARDS.indexOf(card) != -1 then -1 else 0
  return count

module.exports = {
  DECK_SIZE
  COUNT_RANGE_PER_DECK
  ACE
  JACK
  QUEEN
  KING
  LOW_CARDS
  UNCOUNTED_CARDS
  HIGH_CARDS
  DEFAULT_CONFIGURATION
  shuffle
  newUnshuffledDeck
  newUnshuffledShoe
  newDeck
  newShoe
  countOf
}

# compute_dealer_blackjack_probabilities.coffee
#
# Computes the probability of a dealer blackjack when an ace is showing for each count.

fs = require 'fs'
{
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
} = require './common'

# Load the density data
cardDensitiesByCount = JSON.parse(fs.readFileSync('data/cardDensitiesByCount.json'))

COUNT_RANGE = (cardDensitiesByCount.length - 1) / 2

countIndex = (c) -> c + COUNT_RANGE

# Compute table of Ace and 10-King for each count
table = []
for count in [-20..20]
  densities = cardDensitiesByCount[countIndex(count)]
  entry =
    'Count': count
    '%': parseFloat(((densities[10] + densities[JACK] + densities[QUEEN] + densities[KING]) * 100).toFixed(1))

  table.push entry

# Display table
console.table(table)

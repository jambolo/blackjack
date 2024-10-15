# generate-dealer-blackjack-probabilities.coffee
#
# Computes the probability of a dealer blackjack when an ace is showing for each count.
#
# Since an ace showing is a prerequisite for a dealer blackjack, we only need to consider the
# probability of the other card being a 10, jack, queen, or king.

fs = require 'fs'
{
  ACE
  JACK
  QUEEN
  KING
} = require './common'

# Load the density data
cardDensitiesByCount = JSON.parse(fs.readFileSync('data/cardDensitiesByCount.json'))

COUNT_RANGE = (cardDensitiesByCount.length - 1) / 2

countIndex = (c) -> c + COUNT_RANGE

# Compute the probablity of a ten for each count between +/- 20
probabilitiesByCount = []
for c in [-COUNT_RANGE..COUNT_RANGE]
  densities = cardDensitiesByCount[countIndex(c)]
  probabilitiesByCount.push densities[10] + densities[JACK] + densities[QUEEN] + densities[KING]

# Output the results.
fs.writeFileSync  'data/dealerBlackjackProbabilitiesByCount.json', JSON.stringify(probabilitiesByCount)

# Display table
table = []
for count in [-20..20]
  densities = cardDensitiesByCount[countIndex(count)]
  table.push
    'Count': count
    '%': parseFloat(((densities[10] + densities[JACK] + densities[QUEEN] + densities[KING]) * 100).toFixed(2))

console.table(table)

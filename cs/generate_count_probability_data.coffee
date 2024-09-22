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

DECKS_PER_SHOE = DEFAULT_CONFIGURATION.NUMBER_OF_DECKS_PER_SHOE
NUMBER_OF_SHOES = DEFAULT_CONFIGURATION.NUMBER_OF_SHOES
COUNT_RANGE = COUNT_RANGE_PER_DECK * DECKS_PER_SHOE  # The -/+ range of possible counts

countIndex = (c) -> c + COUNT_RANGE

# For a huge number of rounds:
#   1. Shuffle the shoe.
#   2. Compute the count after dealing all but the last deck.
#
# Note some cleverness: Because the count for a whole deck is 0, the count for any portion of a shoe is just the
# negative of the count for the rest of the shoe.

countFrequencies = (0 for [-COUNT_RANGE .. COUNT_RANGE])
shoe = newUnshuffledShoe(DECKS_PER_SHOE)

for i in [0 ... NUMBER_OF_SHOES]
  console.log "#{(i / NUMBER_OF_SHOES * 100).toFixed(0)}% of #{NUMBER_OF_SHOES}" if i % (NUMBER_OF_SHOES / 10) == 0

  # Shuffle
  shuffle shoe

  # Accumulate the count for all but the last deck (as if the first deck is the remaining deck).
  count = -countOf(shoe, 0, DECK_SIZE)
  countFrequencies[countIndex(count)] += 1

# Compute the probability of each count.
countProbabilities = countFrequencies.map (f) -> f / NUMBER_OF_SHOES

# Output the results.
fs.writeFileSync 'data/countProbabilities.json', JSON.stringify(countProbabilities)

# Summarize count frequencies

countFrequenciesTable = []
for c in [-COUNT_RANGE .. COUNT_RANGE] when countFrequencies[c + COUNT_RANGE] > 0
  countFrequenciesTable.push
    count: c
    N: countFrequencies[c + COUNT_RANGE]
    '%': parseFloat((countProbabilities[c + COUNT_RANGE] * 100).toFixed(2))

console.table(countFrequenciesTable)

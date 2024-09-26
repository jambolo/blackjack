# cs\generate_count_probability_data.coffee
#
# Noting the count after dealing half of a 6-deck shoe is simulated 100,000,000 times and the probability of
# each possible count is written to the file `data/countProbabilities.json`. A summary is written to the console.

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

DECKS_PER_SHOE = DEFAULT_CONFIGURATION.DECKS_PER_SHOE
CARDS_PER_SHOE = DECK_SIZE * DECKS_PER_SHOE
NUMBER_OF_SHOES = 100000000
COUNT_RANGE = COUNT_RANGE_PER_DECK * DECKS_PER_SHOE + 1  # The maximum -/+ range of possible counts
DEALT_CARDS = Math.round(CARDS_PER_SHOE / 2) # Half the shoe is dealt
REMAINING_DECKS = (CARDS_PER_SHOE - DEALT_CARDS) / DECK_SIZE # The number of decks remaining (for true count)

countIndex = (c) -> c + COUNT_RANGE

# For a huge number of rounds:
#   1. Shuffle the shoe.
#   2. Compute the true count after dealing half of the shoe.
#

countFrequencies = (0 for [-COUNT_RANGE .. COUNT_RANGE])
shoe = newUnshuffledShoe(DECKS_PER_SHOE)

for i in [0 ... NUMBER_OF_SHOES]
  console.log "#{(i / NUMBER_OF_SHOES * 100).toFixed(0)}% of #{NUMBER_OF_SHOES}" if i % (NUMBER_OF_SHOES / 10) == 0

  # Shuffle
  shuffle shoe

  # Accumulate the true count at the middle of the shoe.
  trueCount = Math.round(countOf(shoe, 0, DEALT_CARDS) / REMAINING_DECKS)
  countFrequencies[countIndex(trueCount)] += 1

# Compute the probability of each count.
countProbabilities = countFrequencies.map (f) -> f / NUMBER_OF_SHOES

# Output the results.
fs.writeFileSync  'data/countProbabilities.json', JSON.stringify(countProbabilities)

# Summarize count frequencies

countFrequenciesTable = []
for c in [-20 .. 20] when countFrequencies[countIndex(c)] > 0
  countFrequenciesTable.push
    count: c
    N: countFrequencies[countIndex(c)]
    '%': parseFloat((countProbabilities[countIndex(c)] * 100).toFixed(2))

console.table(countFrequenciesTable)

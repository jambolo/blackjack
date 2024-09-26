# compute_true_count_shoe_distribution.coffee
#
# Computes the distribution of true counts in a shoe as each card in the shoe is dealt to the deck penetration limit.
# The results are written to `data/trueCountDistribution.json`. A summary is written to the console.

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
NUMBER_OF_SHOES = 100000000
PENETRATION = DEFAULT_CONFIGURATION.PENETRATION
COUNT_RANGE = COUNT_RANGE_PER_DECK * DECKS_PER_SHOE + 1  # The -/+ range of possible counts
CARDS_PLAYED_PER_SHOE = Math.floor((DECKS_PER_SHOE - PENETRATION) * DECK_SIZE)

# Returns the index of the count in the countFrequencies array.
countIndex = (c) -> c + COUNT_RANGE

# Returns the true count given the running count and the number of cards remaining.
trueCount = (runningCount, cardsRemaining) -> Math.round(runningCount / (cardsRemaining / DECK_SIZE))

countFrequencies = (0 for [-COUNT_RANGE .. COUNT_RANGE])
shoe = newUnshuffledShoe(DECKS_PER_SHOE)

console.log "Simulating #{NUMBER_OF_SHOES} shoes..."

for i in [0 ... NUMBER_OF_SHOES]
  console.log "#{(i / NUMBER_OF_SHOES * 100).toFixed(0)}% of #{NUMBER_OF_SHOES}" if i % (NUMBER_OF_SHOES / 10) == 0

  # Shuffle
  shuffle shoe

  runningCount = 0
  cardsRemaining = shoe.length
  for card in shoe[0...CARDS_PLAYED_PER_SHOE]
    cardsRemaining -= 1
    runningCount += if card >= 2 and card <= 6 then 1 else if card == 1 or card >= 10 then -1 else 0
    countFrequencies[countIndex(trueCount(runningCount, cardsRemaining))] += 1

# Compute the probability of each count.
trueCountDistribution = countFrequencies.map (f) -> f / (CARDS_PLAYED_PER_SHOE * NUMBER_OF_SHOES)

# Output the results.
fs.writeFileSync  'data/trueCountDistribution.json', JSON.stringify(trueCountDistribution)

# Output a summary
countDistibutionTable = []
for c in [-20 .. 20]
  countDistibutionTable.push
    count: c
    '%': parseFloat((trueCountDistribution[countIndex(c)] * 100).toFixed(2))

console.table(countDistibutionTable)

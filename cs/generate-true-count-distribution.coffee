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
  BUST
  LOW_CARDS
  UNCOUNTED_CARDS
  HIGH_CARDS
  DEFAULT_CONFIGURATION
  Shoe
} = require './common'

DECKS_PER_SHOE = DEFAULT_CONFIGURATION.DECKS_PER_SHOE
NUMBER_OF_SHOES = 100000000
PENETRATION = DEFAULT_CONFIGURATION.PENETRATION
COUNT_RANGE = COUNT_RANGE_PER_DECK * DECKS_PER_SHOE  # The -/+ range of possible counts
CARDS_PLAYED_PER_SHOE = Math.floor((DECKS_PER_SHOE - PENETRATION) * DECK_SIZE)

# Returns the index of the count in the countFrequencies array.
countIndex = (c) -> c + COUNT_RANGE

countFrequencies = (0 for [-COUNT_RANGE .. COUNT_RANGE])
shoe = new Shoe(DECKS_PER_SHOE, 0)#PENETRATION)

console.log "Simulating #{NUMBER_OF_SHOES} shoes..."

for i in [0 ... NUMBER_OF_SHOES]
  console.log "#{(i / NUMBER_OF_SHOES * 100).toFixed(0)}% of #{NUMBER_OF_SHOES}" if i % (NUMBER_OF_SHOES / 10) == 0

  # Shuffle
  shoe.shuffle()

  while not shoe.done()
    shoe.nextCard()
    countFrequencies[countIndex(shoe.trueCount())] += 1

# Compute the probability of each count.
trueCountDistribution = countFrequencies.map (f) -> f / (CARDS_PLAYED_PER_SHOE * NUMBER_OF_SHOES)

# Output the results.
fs.writeFileSync  'data/trueCountDistribution.json', JSON.stringify(trueCountDistribution)

# Output a summary
countDistibutionTable = []
for count in [-20 .. 20]
  countDistibutionTable.push
    'Count': count
    '%': parseFloat((trueCountDistribution[countIndex(count)] * 100).toFixed(2))

console.table(countDistibutionTable)

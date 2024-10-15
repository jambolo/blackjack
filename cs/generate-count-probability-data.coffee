# cs\generate_count_probability_data.coffee
#
# Noting the count after dealing half of a 6-deck shoe is simulated many times and the probability of
# each possible count is written to the file `data/countProbabilities.json`. A summary is written to the console.

fs = require 'fs'
{
  DECK_SIZE
  COUNT_RANGE_PER_DECK
  DEFAULT_CONFIGURATION
  Shoe
} = require './common'

DECKS_PER_SHOE = 1#DEFAULT_CONFIGURATION.DECKS_PER_SHOE
CARDS_PER_SHOE = DECK_SIZE * DECKS_PER_SHOE
NUMBER_OF_SHOES = 100000#000
COUNT_RANGE = COUNT_RANGE_PER_DECK * DECKS_PER_SHOE  # The maximum -/+ range of possible counts

countIndex = (c) -> c + COUNT_RANGE

# For a huge number of rounds:
#   1. Shuffle the shoe.
#   2. Compute the true count after dealing half of the shoe.

countFrequencies = (0 for [-COUNT_RANGE .. COUNT_RANGE])
shoe = new Shoe(DECKS_PER_SHOE, 0)

DEALT_CARDS = Math.round(CARDS_PER_SHOE / 2) # Half the shoe is dealt

for i in [0 ... NUMBER_OF_SHOES]
  console.log "#{(i / NUMBER_OF_SHOES * 100).toFixed(0)}% of #{NUMBER_OF_SHOES}" if i % (NUMBER_OF_SHOES / 10) == 0

  # Shuffle
  shoe.shuffle()

  # Accumulate the true count at the middle of the shoe.
  runningCount = shoe.runningCountAt(DEALT_CARDS)
  trueCount = shoe.trueCountAt(DEALT_CARDS)
  countFrequencies[countIndex(trueCount)] += 1

  # check
  for i in [0...DEALT_CARDS]
    shoe.nextCard()
  if shoe.runningCount != runningCount
    console.log "Error: shoe.runningCount = #{shoe.runningCount}, runningCount = #{runningCount}"
    break
  if shoe.trueCount() != trueCount
    console.log "Error: shoe.trueCount = #{shoe.trueCount()}, trueCount = #{trueCount}"
    break

# Compute the probability of each count.
countProbabilities = countFrequencies.map (f) -> f / NUMBER_OF_SHOES

# Output the results.
fs.writeFileSync  'data/countProbabilities.json', JSON.stringify(countProbabilities)

# Summarize count frequencies

countFrequenciesTable = []
for count in [-20 .. 20]
  c = countIndex(count)
  if countFrequencies[c] > 0
    countFrequenciesTable.push
      'Count': count
      'N': countFrequencies[c]
      '%': parseFloat((countProbabilities[c] * 100).toFixed(2))

console.table(countFrequenciesTable)

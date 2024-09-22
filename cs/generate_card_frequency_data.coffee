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

NUMBER_OF_SHOES = DEFAULT_CONFIGURATION.NUMBER_OF_SHOES
DECKS_PER_SHOE = DEFAULT_CONFIGURATION.NUMBER_OF_DECKS_PER_SHOE
NUMBER_OF_DECKS = NUMBER_OF_SHOES * DECKS_PER_SHOE
COUNT_RANGE = COUNT_RANGE_PER_DECK * DECKS_PER_SHOE  # The -/+ range of possible counts

# Accumulates the frequency of each card in the given range of the shoe.
accumulateCardFrequencies = (frequencies, shoe, start, n) ->
  frequencies[i] += 1 for i in shoe[start ... start + n]
  return

# Sums the frequencies of low, high, and uncounted cards.
frequenciesByType = (f) ->
  low = 0
  low += f[c] for c in LOW_CARDS
  uncounted = 0
  uncounted += f[c] for c in UNCOUNTED_CARDS
  high = 0
  high += f[c] for c in HIGH_CARDS
  return [low, uncounted, high]

# Returns the index of the count in the count frequencies array.
countIndex = (c) -> c + COUNT_RANGE

# For a huge number of rounds:
#   1. Shuffle the shoe.
#   2. For each deck in the shoe, accumulate the frequencies of the cards by the count.

cardFrequenciesByCount = ((0 for [0..13]) for [-COUNT_RANGE .. COUNT_RANGE])
countFrequencies = (0 for [-COUNT_RANGE .. COUNT_RANGE])
shoe = newUnshuffledShoe(DECKS_PER_SHOE)

for i in [0 ... NUMBER_OF_SHOES]
  console.log "#{(i / NUMBER_OF_SHOES * 100).toFixed(0)}% of #{NUMBER_OF_SHOES}" if i % (NUMBER_OF_SHOES / 10) == 0

  # Shuffle
  shuffle shoe

  # Accumulate the frequencies for the cards in the first deck by the count (as if it is the remaining deck)
  # Note some cleverness: Since the count of an entire deck is always 0, the count for all decks but one is just the
  # negative of its count.
  count = -countOf(shoe, 0, DECK_SIZE)
  countFrequencies[countIndex(count)] += 1
  accumulateCardFrequencies(cardFrequenciesByCount[countIndex(count)], shoe, 0, DECK_SIZE)

# Compute the average frequency of each card for each count.

for c in [-COUNT_RANGE .. COUNT_RANGE] when countFrequencies[countIndex(c)] > 0
  for card in [1..13]
    cardFrequenciesByCount[countIndex(c)][card] /= countFrequencies[countIndex(c)]

# Output the results.

fs.writeFileSync 'data/cardFrequenciesByCount.json', JSON.stringify(cardFrequenciesByCount)

# Summarize card frequencies by count

table = []
for c in [-COUNT_RANGE .. COUNT_RANGE] when countFrequencies[countIndex(c)] > 0
  [low, uncounted, high] = frequenciesByType(cardFrequenciesByCount[countIndex(c)])
  table.push
    count: c
    low: parseFloat(low.toFixed(1))
    uncounted: parseFloat(uncounted.toFixed(1))
    high: parseFloat(high.toFixed(1))

console.table(table)

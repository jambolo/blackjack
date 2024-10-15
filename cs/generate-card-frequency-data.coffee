# generate_card_frequency_data.coffee
#
# Computes the average frequency of each card for each count after each card is dealt up to the deck penetration
# limit. Results are written to the file `data/cardDensitiesByCount.json`. A summary is written to the console.

fs = require 'fs'
{
  DECK_SIZE
  COUNT_RANGE_PER_DECK
  ACE
  KING
  LOW_CARDS
  UNCOUNTED_CARDS
  HIGH_CARDS
  NUMBER_OF_SUITS
  DEFAULT_CONFIGURATION
  Shoe
} = require './common'

NUMBER_OF_SHOES = 10000000
DECKS_PER_SHOE = DEFAULT_CONFIGURATION.DECKS_PER_SHOE
PENETRATION = DEFAULT_CONFIGURATION.PENETRATION
COUNT_RANGE = COUNT_RANGE_PER_DECK * DECKS_PER_SHOE  # The -/+ range of possible running counts
NUMBER_OF_CARDS_DEALT = Math.floor((DECKS_PER_SHOE - PENETRATION) * DECK_SIZE)

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
#   2. For each card in the shoe, up to the penetration limit,
#       a. For the true count, accumulate the density of each card in the remaining cards.

# Accumulated densities of each card for each count.
# Note: card 0 is not used, but including 0 lets us index by card value.
cardDensitiesByCount = ((0 for [0 .. KING]) for [-COUNT_RANGE .. COUNT_RANGE])

# Number of occurences for each count.
countOccurrences = (0 for [-COUNT_RANGE .. COUNT_RANGE])

# The shoe
shoe = new Shoe(DECKS_PER_SHOE, PENETRATION)

for i in [0 ... NUMBER_OF_SHOES]
  console.log "#{(i / NUMBER_OF_SHOES * 100).toFixed(0)}% of #{NUMBER_OF_SHOES}" if i % (NUMBER_OF_SHOES / 10) == 0

  # Shuffle
  shoe.shuffle()

  # For each card, the number remaining in the shoe.
  # Note: card 0 is not used, but including it lets us index by card value.
  remaining = (NUMBER_OF_SUITS * DECKS_PER_SHOE for [0 .. KING])

# Deal each card in the shoe up to the penetration limit. After each card is dealt, accumulate the density of each
# card in the remaining shoe.
  while not shoe.done()
    # Deal the next card.
    card = shoe.nextCard()
    trueCount = shoe.trueCount()
    i = countIndex(trueCount)

    # Update the number of occurences for this count.
    countOccurrences[i] += 1

    # Decrement the number of this card remaining in the shoe.
    remaining[card] -= 1

    # Accumulate the densities of each remaining card for this count.
    totalRemaining = shoe.remaining()
    for c in [ACE .. KING]
      cardDensitiesByCount[i][c] += remaining[c] / totalRemaining

# Compute the average density of each card for each count.
for c in [-COUNT_RANGE .. COUNT_RANGE]
  i = countIndex(c)
  f = countOccurrences[i]
  if f > 0
    cardDensitiesByCount[i] = cardDensitiesByCount[i].map (d) -> d / f
  else
    cardDensitiesByCount[i] = (0 for [0 .. KING])

# Output the results.

fs.writeFileSync 'data/cardDensitiesByCount.json', JSON.stringify(cardDensitiesByCount)

# Summarize card density by count
table = []
for c in [-20 .. 20] when countOccurrences[countIndex(c)] > 0
  [low, uncounted, high] = frequenciesByType(cardDensitiesByCount[countIndex(c)])
  table.push
    'Count': c
    'Low (%)': parseFloat((low * 100).toFixed(1))
    'Uncounted (%)': parseFloat((uncounted * 100).toFixed(1))
    'High (%)': parseFloat((high * 100).toFixed(1))

console.table(table)

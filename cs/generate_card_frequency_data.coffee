# generate_card_frequency_data.coffee
#
# Computes the average frequency of each card for each count after each card is dealt up to the deck penetration
# limit. Results are written to the file `data/cardDensitiesByCount.json`. A summary is written to the console.

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

NUMBER_OF_SHOES = 10000000
DECKS_PER_SHOE = DEFAULT_CONFIGURATION.NUMBER_OF_DECKS_PER_SHOE
PENETRATION = DEFAULT_CONFIGURATION.PENETRATION
COUNT_RANGE = COUNT_RANGE_PER_DECK * DECKS_PER_SHOE  # The -/+ range of possible running counts
NUMBER_OF_CARDS_DEALT = Math.floor((DECKS_PER_SHOE - PENETRATION) * DECK_SIZE)

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
#   2. For each card in the shoe, up to the penetration limit,
#       a. Compute the count.
#       b. For that count, accumulate the density of each card in the remaining cards.

# Accumulated densities of each card for each count. Note: card 0 is not used.
cardDensitiesByCount = ((0 for [0..13]) for [-COUNT_RANGE .. COUNT_RANGE])

# Frequencies of each count.
countFrequencies = (0 for [-COUNT_RANGE .. COUNT_RANGE])

# The shoe
shoe = newUnshuffledShoe(DECKS_PER_SHOE)

for i in [0 ... NUMBER_OF_SHOES]
  console.log "#{(i / NUMBER_OF_SHOES * 100).toFixed(0)}% of #{NUMBER_OF_SHOES}" if i % (NUMBER_OF_SHOES / 10) == 0

  # Shuffle
  shuffle shoe

  # Number of cards remaining in the shoe for each card.
  remaining = (DECKS_PER_SHOE * 4 for [0..13]) # Note: card 0 is not used

  # Running count
  runningCount = 0

  # Number of cards remaining in the shoe
  cardsRemaining = DECKS_PER_SHOE * DECK_SIZE

# Deal each card in the shoe up to the penetration limit, accumulating the densities of the remaining cards.
  for card in shoe[0...NUMBER_OF_CARDS_DEALT]
    cardsRemaining -= 1

    # Compute the count
    runningCount += if card >= 2 and card <= 6 then 1 else if card == 1 or card >= 10 then -1 else 0
    trueCount = Math.round(runningCount / (cardsRemaining / DECK_SIZE))
    countFrequencies[countIndex(trueCount)] += 1

    # Remove the card from the remaining cards and accumulate the densities for the count.
    remaining[card] -= 1
    cardDensitiesByCount[countIndex(trueCount)][c] += remaining[c] / cardsRemaining for c in [1..13]

# Compute the average density of each card for each count.
for c in [-COUNT_RANGE .. COUNT_RANGE] when countFrequencies[countIndex(c)] > 0
  for card in [1..13]
    cardDensitiesByCount[countIndex(c)][card] /= countFrequencies[countIndex(c)]

# Output the results.

fs.writeFileSync 'data/cardDensitiesByCount.json', JSON.stringify(cardDensitiesByCount)

# Summarize card density by count

table = []
for c in [-COUNT_RANGE .. COUNT_RANGE] when countFrequencies[countIndex(c)] > 0
  [low, uncounted, high] = frequenciesByType(cardDensitiesByCount[countIndex(c)])
  table.push
    count: c
    low: parseFloat((low * 100).toFixed(1))
    uncounted: parseFloat((uncounted * 100).toFixed(1))
    high: parseFloat((high * 100).toFixed(1))

console.table(table)

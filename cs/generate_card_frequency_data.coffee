fs = require 'fs'

NUMBER_OF_SHOES = 100000000
DECKS_PER_SHOE = 6
NUMBER_OF_DECKS = NUMBER_OF_SHOES # * DECKS_PER_SHOE
DECK_SIZE = 52
COUNT_RANGE = 52
LOW_CARDS = [2, 3, 4, 5, 6]
UNCOUNTED_CARDS = [7, 8, 9]
HIGH_CARDS = [1, 10, 11, 12, 13]

# Shuffles an array in place.
shuffle = (a) ->
  i = a.length
  while --i > 0
      j = ~~(Math.random() * (i + 1))
      t = a[j]
      a[j] = a[i]
      a[i] = t
  return

# Generates a single deck of cards unshuffled.
newDeck = ->
  deck = []
  for [1..4]
    deck = deck.concat [1..13]
  return deck

# Generates a shoe unshuffled.
newShoe = (size) ->
  shoe = []
  for [0 ... size]
      deck = newDeck()
      shoe = shoe.concat(deck)
  return shoe

# Returns the count for one or more decks of a shoe.
countOf = (shoe, start, n) ->
  count = 0
  for card in shoe[start * DECK_SIZE ... (start + n) * DECK_SIZE]
    if HIGH_CARDS.indexOf(card) != -1
      count -= 1
    else if LOW_CARDS.indexOf(card) != -1
      count += 1
  return count

# Computes the frequency of each card for the given count.
accumulateCardFrequencies = (frequencies, count, shoe, start, n) ->
  f = frequencies[count + COUNT_RANGE]
  for i in shoe[start * DECK_SIZE ... (start + n) * DECK_SIZE]
    f[i] += 1
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

# For a huge number of rounds:
#   1. Shuffle the shoe.
#   2. For each deck in the shoe, accumulate the frequencies of the cards by the count.
#
# Note some cleverness: the count for all but one deck is just the negative of its count.

cardFrequenciesByCount = ((0 for [0..13]) for [-COUNT_RANGE .. COUNT_RANGE])
countFrequencies = (0 for [-COUNT_RANGE .. COUNT_RANGE])
shoe = newShoe(DECKS_PER_SHOE)

for i in [0 ... NUMBER_OF_SHOES]
  console.log "#{(i / NUMBER_OF_SHOES * 100).toFixed(0)}% of #{NUMBER_OF_SHOES}" if i % (NUMBER_OF_SHOES / 10) == 0

  # Shuffle
  shuffle shoe

  # Accumulate the frequencies for the cards in each deck by the count (as if it is the remaining deck)
  for d in [0 ... DECKS_PER_SHOE]
    count = -countOf(shoe, d, 1)
    countFrequencies[count + COUNT_RANGE] += 1
    accumulateCardFrequencies(cardFrequenciesByCount, count, shoe, d, 1)

# Compute the average frequency of each card for each count.

for c in [-COUNT_RANGE .. COUNT_RANGE] when countFrequencies[c + COUNT_RANGE] > 0
  for card in [1..13]
    cardFrequenciesByCount[c + COUNT_RANGE][card] /= countFrequencies[c + COUNT_RANGE]

# Output the results.

fs.writeFileSync 'data/cardFrequenciesByCount.json', JSON.stringify(cardFrequenciesByCount)

# Summarize card frequencies by count

table = []
for c in [-COUNT_RANGE .. COUNT_RANGE] when countFrequencies[c + COUNT_RANGE] > 0
  [low, uncounted, high] = frequenciesByType(cardFrequenciesByCount[c + COUNT_RANGE])
  table.push
    count: c
    low: parseFloat(low.toFixed(1))
    uncounted: parseFloat(uncounted.toFixed(1))
    high: parseFloat(high.toFixed(1))

console.table(table)

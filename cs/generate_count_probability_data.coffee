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
  for i in [1..4]
    deck = deck.concat [1..13]
  return deck

# Generates a shoe unshuffled.
newShoe = (size) ->
  shoe = []
  for i in [1 .. size]
      deck = newDeck()
      shoe = shoe.concat(deck)
  return shoe

# Returns the count for one or more decks of a shoe.
countOf = (shoe, start, n) ->
  deck = shoe[start * DECK_SIZE ... (start + n) * DECK_SIZE]
  count = 0
  for card in deck
    if HIGH_CARDS.indexOf(card) != -1
      count -= 1
    else if LOW_CARDS.indexOf(card) != -1
      count += 1
  return count

# For a huge number of rounds:
#   1. Shuffle the shoe.
#   2. Compute the count after dealing all but the last deck.
#
# Note some cleverness: the count for all but one deck is just the negative of its count.

countFrequencies = (0 for [-COUNT_RANGE .. COUNT_RANGE])
shoe = newShoe(DECKS_PER_SHOE)

for i in [0 ... NUMBER_OF_SHOES]
  console.log "#{(i / NUMBER_OF_SHOES * 100).toFixed(0)}% of #{NUMBER_OF_SHOES}" if i % (NUMBER_OF_SHOES / 10) == 0

  # Shuffle
  shuffle shoe

  # Accumulate the count for all but the last deck.
  count = -countOf(shoe, DECKS_PER_SHOE - 1, 1)
  countFrequencies[count + COUNT_RANGE] += 1

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

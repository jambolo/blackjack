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
shuffle =  (a) ->
  i = a.length
  while --i > 0
      j = ~~(Math.random() * (i + 1))
      t = a[j]
      a[j] = a[i]
      a[i] = t
  return

# Generates a single deck of cards (unshuffled).
newDeck = ->
  deck = []
  for i in [1..4]
    deck = deck.concat [1..13]
  return deck

# Generates a shoe of 6 decks unshuffled.
newShoe = (size) ->
  shoe = []
  for i in [1 .. size]
      deck = newDeck()
      shoe = shoe.concat(deck)
  return shoe

# Partitions a shoe into decks.
partitionedShoe = (shoe) ->
  decks = []
  for i in [0...DECKS_PER_SHOE]
    decks.push shoe[i * DECK_SIZE ... (i + 1) * DECK_SIZE]
  return decks

# Returns the count of a deck.
countOf = (deck) ->
  count = 0
  for card in deck
    if HIGH_CARDS.indexOf(card) != -1
      count += 1
    else if LOW_CARDS.indexOf(card) != -1
      count -= 1
  return count

# Computes the frequency of each card for each count.
accumulateCardFrequencies = (frequencies, counts, deck) ->
  count = countOf(deck)
  counts[count + COUNT_RANGE] += 1
  for card in deck
    frequencies[count + COUNT_RANGE][card] += 1
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

# Run 1000000 rounds of generating a shoe, partitioning it, and computing card frequencies.
cardFrequenciesByCount = ((0 for [0..13]) for [-COUNT_RANGE .. COUNT_RANGE])
counts = (0 for i in [-COUNT_RANGE .. COUNT_RANGE])

shoe = newShoe(DECKS_PER_SHOE)
for i in [1..NUMBER_OF_SHOES]
  shuffle(shoe)
  console.log "#{((i - 1) / NUMBER_OF_SHOES * 100).toFixed(0)}% of #{NUMBER_OF_SHOES}" if i % (NUMBER_OF_SHOES / 10) == 1
#  decks = partitionedShoe(shoe)
#  for deck in decks
#    accumulateCardFrequencies(cardFrequenciesByCount, counts, deck)
  accumulateCardFrequencies(cardFrequenciesByCount, counts, shoe[0...DECK_SIZE])


# Compute the average quanitity of each card for each count.
for c in [-COUNT_RANGE .. COUNT_RANGE] when counts[c + COUNT_RANGE] > 0
  for card in [1..13]
    cardFrequenciesByCount[c + COUNT_RANGE][card] /= counts[c + COUNT_RANGE]

# Compute the probability of each count.
countProbabilities = (counts[c + COUNT_RANGE] / NUMBER_OF_DECKS for c in [-COUNT_RANGE .. COUNT_RANGE])

# Output the results.
fs.writeFileSync 'data/cardFrequenciesByCount.json', JSON.stringify(cardFrequenciesByCount)
fs.writeFileSync 'data/countProbabilities.json', JSON.stringify(countProbabilities)

# Summarize
table = []
for c in [-COUNT_RANGE .. COUNT_RANGE] when counts[c + COUNT_RANGE] > 0
  [low, uncounted, high] = frequenciesByType(cardFrequenciesByCount[c + COUNT_RANGE])
  table.push
    count: c
    N: counts[c + COUNT_RANGE]
    '%': parseFloat((countProbabilities[c + COUNT_RANGE] * 100).toFixed(2))
    low: parseFloat(low.toFixed(1))
    uncounted: parseFloat(uncounted.toFixed(1))
    high: parseFloat(high.toFixed(1))

console.table(table)

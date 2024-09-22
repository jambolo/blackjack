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

NUMBER_OF_DECKS_PER_SHOE: DEFAULT_CONFIGURATION.NUMBER_OF_DECKS_PER_SHOE
NUMBER_OF_SHOES: DEFAULT_CONFIGURATION.NUMBER_OF_SHOES
NUMBER_OF_DECKS = 1
COUNT_RANGE = COUNT_RANGE_PER_DECK * NUMBER_OF_DECKS

countIndex = (c) -> c + COUNT_RANGE

# Load the frequency data
cardFrequenciesByCount = JSON.parse(fs.readFileSync('data/cardFrequenciesByCount.json'))

# Compute probabilities of Ace and 10-King for each count
probabilities = []
for count in [-COUNT_RANGE..COUNT_RANGE]
  f = cardFrequenciesByCount[count + COUNT_RANGE]
  prob = {}
  prob['Count'] = count
  prob['Ace (%)'] = parseFloat((f[ACE] / DECK_SIZE * 100).toFixed(1))
  prob['Ten (%)'] = parseFloat(((f[10] + f[JACK] + f[QUEEN] + f[KING]) / DECK_SIZE * 100).toFixed(1))
  probabilities.push prob

# Display table
console.table(probabilities)

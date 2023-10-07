fs = require 'fs'

COUNT_RANGE = 52
DECK_SIZE = 52
ACE = 1
JACK = 11
QUEEN = 12
KING = 13

# Load the frequency data
cardFrequenciesByCount = JSON.parse(fs.readFileSync('data/cardFrequenciesByCount.json'))

# Compute probabilities of Ace and 10-King for each count
probabilities = []
for count in [-20..20]
  f = cardFrequenciesByCount[count + COUNT_RANGE]
  prob = {}
  prob['Count'] = count
  prob['Ace (%)'] = parseFloat((f[ACE] / DECK_SIZE * 100).toFixed(1))
  prob['Ten (%)'] = parseFloat(((f[10] + f[JACK] + f[QUEEN] + f[KING]) / DECK_SIZE * 100).toFixed(1))
  probabilities.push prob

# Display table
console.table(probabilities)

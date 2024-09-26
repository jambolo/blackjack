# generate-dealer-outcome-distribution.coffee
#
# Generates the distribution of the dealer's outcomes by the card showing and the count.

fs = require 'fs'
{
  DECK_SIZE
  COUNT_RANGE_PER_DECK
  ACE
  DEFAULT_CONFIGURATION
  valueOf
  Shoe
  Rules
} = require './common'

DECKS_PER_SHOE = DEFAULT_CONFIGURATION.DECKS_PER_SHOE
PENETRATION = DEFAULT_CONFIGURATION.PENETRATION
NUMBER_OF_SHOES = 100000 # The number of shoes to simulate
COUNT_RANGE = COUNT_RANGE_PER_DECK * DECKS_PER_SHOE + 1 # The maximum -/+ range of possible counts
BUST = 22 # An outcome of 22 represents a bust.

rules = new Rules(DEFAULT_CONFIGURATION.RULES)
rules.log()

shoe = new Shoe(DECKS_PER_SHOE, PENETRATION)

# Dealer's outcome frequencies by card showing and count.
outcomes = (0 for [0 .. BUST] for [0 .. 10])
countIndex = (count) -> count + COUNT_RANGE

console.log "Simulating #{NUMBER_OF_SHOES} shoes..."

for i in [0 ... NUMBER_OF_SHOES]
  console.log "#{(i / NUMBER_OF_SHOES * 100).toFixed(0)}% of #{NUMBER_OF_SHOES}" if i % (NUMBER_OF_SHOES / 10) == 0

  # Shuffle the shoe.
  shoe.shuffle()

  # Deal the dealers hands until the penetration limit is reached, accumulating the outcomes by count and card showing
  while !shoe.done()
    # Deal the dealer's initial hand.
    under = shoe.nextCardValue()
    showing = shoe.nextCardValue()
    hand = [under, showing]

    # If the dealer checks for blackjack, the hand ends if the dealer has blackjack, and the results are ignored
    # because the dealer wins immediately.
    continue if rules.dealerChecksForBlackjack and (under == ACE and showing == 10 or under == 10 and showing == ACE)

    # Deal to the dealer.
    while rules.dealerMustHit(hand)
      hand.push shoe.nextCardValue()

    # Record the outcome.
    value = valueOf(hand)
    if value > 21
      outcomes[showing][BUST] += 1
    else
      outcomes[showing][value] += 1

# Compute the probability of each outcome by card showing.
for s in  [1 .. 10]
  total = outcomes[s].reduce((a, b) -> a + b)
  outcomes[s] = outcomes[s].map((n) -> n / total)

# Summarize the probabilities of each outcome by card showing.
console.log "Dealer outcome distribution by card showing:"
outcomesByShowingTable = []
for s in  [1 .. 10]
  outcomesByShowingTable.push {
    'Showing': if s == ACE then 'Ace' else if s >= 10 then 'Ten' else s
    '17 (%)': parseFloat((outcomes[s][17] * 100).toFixed(1))
    '18 (%)': parseFloat((outcomes[s][18] * 100).toFixed(1))
    '19 (%)': parseFloat((outcomes[s][19] * 100).toFixed(1))
    '20 (%)': parseFloat((outcomes[s][20] * 100).toFixed(1))
    '21 (%)': parseFloat((outcomes[s][21] * 100).toFixed(1))
    'Bust (%)': parseFloat((outcomes[s][BUST] * 100).toFixed(1))
  }
console.table(outcomesByShowingTable)

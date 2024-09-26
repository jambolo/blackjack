# Common constants and functions

# Constants.
DECK_SIZE = 52
COUNT_RANGE_PER_DECK = 20
ACE = 1
JACK = 11
QUEEN = 12
KING = 13
LOW_CARDS = [2, 3, 4, 5, 6]
UNCOUNTED_CARDS = [7, 8, 9]
HIGH_CARDS = [ACE, 10, JACK, QUEEN, KING]

# Default configuration.
DEFAULT_CONFIGURATION =
  DECKS_PER_SHOE: 6
  PENETRATION: 1.0
  RULES: {
    DEALER_MUST_HIT_SOFT_17: true
    DEALER_CHECKS_FOR_BLACKJACK: true
    DOUBLE_AFTER_SPLIT_ALLOWED: true
    RESPLIT_ACES_ALLOWED: false
    HIT_SPLIT_ACES_ALLOWED: false
    SURRENDER_ALLOWED: false
    MAX_SPLIT_HANDS: 4
    BLACKJACK_PAYOFF: 1.5
  }

# Shuffles an array in place.
shuffle = (a) ->
  i = a.length
  while --i > 0
    j = ~~(Math.random() * (i + 1))
    [a[i], a[j]] = [a[j], a[i]]
  return

# Generates a single unshuffled deck of cards.
newUnshuffledDeck = ->
  deck = []
  deck = deck.concat [1..13] for [1..4]
  return deck

# Generates an unshuffled shoe.
newUnshuffledShoe = (size) ->
  shoe = []
  shoe = shoe.concat newUnshuffledDeck() for [0 ... size]
  return shoe

# Generates a shuffled deck of cards.
newDeck = ->
  deck = newUnshuffledDeck()
  shuffle deck
  return deck

# Generates a shuffled shoe.
newShoe = (size) ->
  shoe = newUnshuffledShoe(size)
  shuffle shoe
  return shoe

# Returns the count for the given range of a shoe.
countOf = (shoe, start, n) ->
  count = 0
  for card in shoe[start ... start + n]
    count += if card == ACE or card >= 10 then -1 else if card <= 6 then 1 else 0
  return count

# Returns the value of a hand.
valueOf = (hand) ->
  sum = hand.reduce((a, b) -> a + b)
  sum += 10 if hand.includes(ACE) and sum <= 11
  return sum

class Shoe
  constructor: (decks, penetration) ->
    @cards = []
    @cards = @cards.concat [1 .. 13] for [0 ... 4] for [0 ... decks]
    @cardsToDeal = Math.ceil((decks - penetration) * DECK_SIZE)
    @index = 0
    @runningCount = 0
    return
  shuffle: ->
    i = @cards.length
    while --i > 0
      j = ~~(Math.random() * (i + 1))
      [@cards[i], @cards[j]] = [@cards[j], @cards[i]]
    @index = 0
    @runningCount = 0
    return
  nextCard: ->
    card = @cards[@index++]
    @runningCount += if card == ACE or card >= 10 then -1 else if card <= 6 then 1 else 0
    return card
  nextCardValue: ->
    card = @nextCard()
    card = 10 if card > 10
    return card
  remaining: -> @cards.length - @index
  trueCount: -> Math.round(@runningCount / (@remaining() / DECK_SIZE))
  done: -> @index > @cardsToDeal

class Rules
  constructor: (configuration) ->
    @dealerMustHitSoft17 = configuration.DEALER_MUST_HIT_SOFT_17
    @dealerChecksForBlackjack = configuration.DEALER_CHECKS_FOR_BLACKJACK
    #@doubleAfterSplitAllowed = configuration.DOUBLE_AFTER_SPLIT_ALLOWED
    #@resplitAcesAllowed = configuration.RESPLIT_ACES_ALLOWED
    #@hitSplitAcesAllowed = configuration.HIT_SPLIT_ACES_ALLOWED
    #@surrenderAllowed = configuration.SURRENDER_ALLOWED
    #@maxSplitHands = configuration.MAX_SPLIT_HANDS
    #@blackJackPayoff = configuration.BLACKJACK_PAYOFF
    return
  dealerMustHit: (hand) ->
    sum = hand.reduce((a, b) -> a + b)
    soft = hand.includes(ACE) and sum <= 11
    if soft
      return sum < 7 or sum == 7 and @dealerMustHitSoft17
    else
      return sum < 17
  log: ->
    console.log "Rules:"
    console.log "  Dealer must hit soft 17: #{@dealerMustHitSoft17}"
    console.log "  Dealer checks for blackjack: #{@dealerChecksForBlackjack}"
    #console.log "  Double after split allowed: #{@doubleAfterSplitAllowed}"
    #console.log "  Resplit aces allowed: #{@resplitAcesAllowed}"
    #console.log "  Hit split aces allowed: #{@hitSplitAcesAllowed}"
    #console.log "  Surrender allowed: #{@surrenderAllowed}"
    #console.log "  Max split hands: #{@maxSplitHands}"
    #console.log "  Blackjack payoff: #{@blackJackPayoff}"
    return

module.exports = {
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
  valueOf
  Shoe
  Rules
}

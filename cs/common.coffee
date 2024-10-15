# Commonly used constants, functions, and classes.

# Constants.
DECK_SIZE = 52
COUNT_RANGE_PER_DECK = 20 # The range of possible +/- counts per deck.
ACE = 1
JACK = 11
QUEEN = 12
KING = 13
BUST = 22   # Arbitrary value that represents a bust
LOW_CARDS = [2, 3, 4, 5, 6]
UNCOUNTED_CARDS = [7, 8, 9]
HIGH_CARDS = [ACE, 10, JACK, QUEEN, KING]
NUMBER_OF_SUITS = 4

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

# Returns the count for a card.
countValueOf = (card) -> if card == ACE or card >= 10 then -1 else if card <= 6 then 1 else 0

# Returns the value of a hand.
valueOf = (hand) ->
  values = hand.map (card) -> if card > 10 then 10 else card
  sum = values.reduce((a, b) -> a + b)
  sum += 10 if hand.includes(ACE) and sum <= 11
  return sum

class Shoe
  constructor: (decks, penetration) ->
    @cards = []
    @cards = @cards.concat [ACE .. KING] for [0 ... NUMBER_OF_SUITS] for [0 ... decks]
    @cardsToDeal = Math.ceil((decks - penetration) * DECK_SIZE)
    @index = 0  # Index of the next card to deal.
    @runningCount = 0
    @shuffle()
    return

  # Shuffles the shoe, resetting the index and running count. (Fisher-Yates shuffle)
  shuffle: ->
    i = @cards.length
    while --i > 0
      j = ~~(Math.random() * (i + 1))
      [@cards[i], @cards[j]] = [@cards[j], @cards[i]]
    @index = 0
    @runningCount = 0
    return

  # Deals the next card from the shoe, updating the running count.
  nextCard: ->
    card = @cards[@index++]
    @runningCount += countValueOf(card)
    return card

  # Deals the next card from the shoe, returning the value of the card instead of the card itself.
  nextCardValue: ->
    card = @nextCard()
    card = 10 if card > 10
    return card

  # Returns the number of cards remaining in the shoe, ignoring the penetration limit.
  remaining: -> @cards.length - @index

  # Returns the true count for the current state of the shoe.
  trueCount: -> Math.round(@runningCount / (@remaining() / DECK_SIZE))

  # Returns true if the penetration limit has been reached. Does not affect the state of the shoe.
  done: -> @index > @cardsToDeal

  # Returns the running count for the first i cards.
  runningCountAt: (i) ->
    @cards[0 ... i].reduce (a, b) ->
      a + countValueOf(b)
    , 0

  # Returns the true count for the first i cards. Does not affect the state of the shoe.
  trueCountAt: (i) ->
    Math.round(@runningCountAt(i) / ((@cards.length - i) / DECK_SIZE))

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
  NUMBER_OF_SUITS
  DEFAULT_CONFIGURATION
  countValueOf
  valueOf
  Shoe
  Rules
}

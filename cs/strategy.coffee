CONFIGURATION =
  numberOfDecks:      6
  hitOnSoft17:        true
  doubleOnly1011:     false
  doubleAfterSplit:   true

NTRIALS = 1000

class Shoe
  constructor: () ->
    @cards = []
    for i in [0...CONFIGURATION.numberOfDecks*52]
      @cards.push Math.max(i % 13 + 1, 10)
    shuffle()
    @i = 0
    return

  next: () ->
    @cards[@i++]

  isDone: () ->
    @i > @cards.Length() / 2

  shuffle: () ->
    i = @cards.length
    while --i > 0
        j = ~~(Math.random() * (i + 1))
        t = @cards[j]
        @cards[j] = @cards[i]
        @cards[i] = t
    return

strategy =
  pair:
    #        A         2         3         4         5         6         7         8         9        10
    [] # 0
    [] # 1
    [null, "split",  "split",  "split",  "split",  "split",  "split",  "split",  "split",  "split",  "split" ] # AA
    [] # 3
    [null, "hit",    "hit",    "hit",    "hit",    "split",  "split",  "hit",    "hit",    "hit",    "hit"   ] # 22
    [] # 5
    [null, "hit",    "hit",    "hit",    "hit",    "split",  "split",  "hit",    "hit",    "hit",    "hit"   ] # 33
    [] # 7
    [null, "hit",    "hit",    "hit",    "split",  "split",  "split",  "hit",    "hit",    "hit",    "hit"   ] # 44
    [] # 9
    [null, "hit",    "double", "double", "double", "double", "double", "double", "double", "double", "hit"   ] # 55
    [] # 11
    [null, "hit",    "split",  "split",  "split",  "split",  "split",  "hit",    "hit",    "hit",    "hit"   ] # 66
    [] # 13
    [null, "hit",    "split",  "split",  "split",  "split",  "split",  "split",  "hit",    "hit",    "hit"   ] # 77
    [] # 15
    [null, "split",  "split",  "split",  "split",  "split",  "split",  "split",  "split",  "split",  "split" ] # 88
    [] # 17
    [null, "stand",  "split",  "split",  "split",  "split",  "split",  "stand",  "split",  "split",  "stand" ] # 99
    [] # 19
    [null, "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand" ] # TT
  soft:
    #        A         2         3         4         5         6         7         8         9        10
    [] # 0
    [] # 1
    [] # 2
    [null, "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit"   ] # A2
    [null, "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit"   ] # A3
    [null, "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit"   ] # A4
    [null, "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit"   ] # A5
    [null, "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit"   ] # A6
    [null, "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit"   ] # A7
    [null, "hit",    "hit",    "double", "double", "double", "double", "hit",    "hit",    "hit",    "hit"   ] # A8
    [null, "hit",    "double", "double", "double", "double", "double", "double", "double", "double", "hit"   ] # A9
    [null, "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"] # A10
    [] # 12
    [] # 13
    [] # 14
    [] # 15
    [] # 16
    [] # 17
    [] # 18
    [] # 19
  hard:
    #        A         2         3         4         5         6         7         8         9        10
    [] # 0
    [] # 1
    [] # 2
    [] # 3
    [] # 4
    [null, "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit"   ] # 5
    [null, "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit"   ] # 6
    [null, "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit"   ] # 7
    [null, "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit",    "hit"   ] # 8
    [null, "hit",    "hit",    "double", "double", "double", "double", "hit",    "hit",    "hit",    "hit"   ] # 9
    [null, "hit",    "double", "double", "double", "double", "double", "double", "double", "double", "hit"   ] # 10
    [null, "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"] # 11
    [null, "hit",    "hit",    "stand",  "stand",  "stand",  "stand",  "hit",    "hit",    "hit",    "hit"   ] # 12
    [null, "hit",    "stand",  "stand",  "stand",  "stand",  "stand",  "hit",    "hit",    "hit",    "hit"   ] # 13
    [null, "hit",    "stand",  "stand",  "stand",  "stand",  "stand",  "hit",    "hit",    "hit",    "hit"   ] # 14
    [null, "hit",    "stand",  "stand",  "stand",  "stand",  "stand",  "hit",    "hit",    "hit",    "hit"   ] # 15
    [null, "hit",    "stand",  "stand",  "stand",  "stand",  "stand",  "hit",    "hit",    "hit",    "hit"   ] # 16
    [null, "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand" ] # 17
    [null, "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand" ] # 18
    [null, "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand",  "stand" ] # 19

playerAction = (playerCards, dealerShowing) ->
  total = 0
  total = total + p for p in playerCards

  # check for paired
  if playerCards.length == 2 and playerCards[0] == playerCards[1]
    return strategy.pair[total][dealerShowing]

  # check for soft
  soft = false
  if total <= 11
    for p in player
      soft = true if p is 1
  if soft
    return strategy.soft[total][dealerShowing]

  # only hard is left now
  return strategy.hard[total][dealerShowing]

dealerAction = (cards) ->
  total = 0
  total = total + c for c in cards

  # check for soft
  soft = false
  if total <= 11
    for c in cards
      soft = true if c is 1

  if (soft and total > 7) or total > 16
    return "hit"
  else
    return "stand"


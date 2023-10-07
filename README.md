# BlackJack

Tools for the analysis of BlackJack, written primarily in CoffeeScript.

## Executables

### generate_card_frequency_data.coffee
Dealing the first deck from a 6-deck shoe was simulated 600,000,000 times. Decks were grouped by count from -52 to +52, and then for each count, the average quantity of each card (1-13) in a deck is computed.

### compute_dealer_blackjack_probabilities.coffee
Computes the probability of a dealer blackjack if an ace is showing for each count.

## Generated data

### cardFrequenciesByCount.json
A two-dimensional array -- the average quantity of each card in a deck for each count value from -52 to +52. Generated by generateCardFrequencyData.coffee

### countProbabilites.json
The probability of a particular count after dealing 1 deck from a 6-deck shoe.

## Summaries
Summaries of analysis results.

### Frequencies of counts after dealing one deck from a 6-deck shoe, from -20 to +20 (100000000 samples)
| Count |    N    |  %   |
|-------|---------|------|
|  -20  |  15753  | 0.02 |
|  -19  |  29412  | 0.03 |
|  -18  |  52399  | 0.05 |
|  -17  |  88875  | 0.09 |
|  -16  | 148137  | 0.15 |
|  -15  | 237344  | 0.24 |
|  -14  | 367332  | 0.37 |
|  -13  | 552108  | 0.55 |
|  -12  | 804788  | 0.8  |
|  -11  | 1137524 | 1.14 |
|  -10  | 1558056 | 1.56 |
|  -9   | 2066320 | 2.07 |
|  -8   | 2664424 | 2.66 |
|  -7   | 3329093 | 3.33 |
|  -6   | 4038319 | 4.04 |
|  -5   | 4749215 | 4.75 |
|  -4   | 5428459 | 5.43 |
|  -3   | 6020424 | 6.02 |
|  -2   | 6478159 | 6.48 |
|  -1   | 6777442 | 6.78 |
|   0   | 6879852 | 6.88 |
|   1   | 6775674 | 6.78 |
|   2   | 6481322 | 6.48 |
|   3   | 6021216 | 6.02 |
|   4   | 5428135 | 5.43 |
|   5   | 4750903 | 4.75 |
|   6   | 4034959 | 4.03 |
|   7   | 3328884 | 3.33 |
|   8   | 2662048 | 2.66 |
|   9   | 2067088 | 2.07 |
|  10   | 1557672 | 1.56 |
|  11   | 1138329 | 1.14 |
|  12   | 806018  | 0.81 |
|  13   | 551893  | 0.55 |
|  14   | 368270  | 0.37 |
|  15   | 236492  | 0.24 |
|  16   | 147900  | 0.15 |
|  17   |  88865  | 0.09 |
|  18   |  52075  | 0.05 |
|  19   |  29449  | 0.03 |
|  20   |  16217  | 0.02 |

### Frequencies of low (2-6), uncounted(7-9), and high cards (A,10-K) by count
| Count | Low  | Uncounted | High |
|-------|------|-----------|------|
|  -20  | 30.4 |   11.1    | 10.4 |
|  -19  | 29.9 |   11.2    | 10.9 |
|  -18  | 29.3 |   11.3    | 11.3 |
|  -17  | 28.8 |   11.4    | 11.8 |
|  -16  | 28.3 |   11.5    | 12.3 |
|  -15  | 27.7 |   11.5    | 12.7 |
|  -14  | 27.2 |   11.6    | 13.2 |
|  -13  | 26.7 |   11.7    | 13.7 |
|  -12  | 26.1 |   11.7    | 14.1 |
|  -11  | 25.6 |   11.8    | 14.6 |
|  -10  | 25.1 |   11.8    | 15.1 |
|  -9   | 24.6 |   11.9    | 15.6 |
|  -8   |  24  |   11.9    |  16  |
|  -7   | 23.5 |    12     | 16.5 |
|  -6   |  23  |    12     |  17  |
|  -5   | 22.5 |    12     | 17.5 |
|  -4   |  22  |    12     |  18  |
|  -3   | 21.5 |   12.1    | 18.5 |
|  -2   |  21  |   12.1    |  19  |
|  -1   | 20.5 |   12.1    | 19.5 |
|   0   |  20  |   12.1    |  20  |
|   1   | 19.5 |   12.1    | 20.5 |
|   2   |  19  |   12.1    |  21  |
|   3   | 18.5 |   12.1    | 21.5 |
|   4   |  18  |    12     |  22  |
|   5   | 17.5 |    12     | 22.5 |
|   6   |  17  |    12     |  23  |
|   7   | 16.5 |    12     | 23.5 |
|   8   |  16  |   11.9    |  24  |
|   9   | 15.6 |   11.9    | 24.6 |
|  10   | 15.1 |   11.8    | 25.1 |
|  11   | 14.6 |   11.8    | 25.6 |
|  12   | 14.1 |   11.7    | 26.1 |
|  13   | 13.7 |   11.7    | 26.7 |
|  14   | 13.2 |   11.6    | 27.2 |
|  15   | 12.7 |   11.6    | 27.7 |
|  16   | 12.3 |   11.5    | 28.3 |
|  17   | 11.8 |   11.4    | 28.8 |
|  18   | 11.4 |   11.3    | 29.4 |
|  19   | 10.9 |   11.2    | 29.9 |
|  20   | 10.4 |   11.1    | 30.4 |

### Probability of dealer blackjack if ace is showing by count

| Count | Probability (%) |
|-------|-----------------|
|  -20  |      16.1       |
|  -19  |      16.8       |
|  -18  |      17.5       |
|  -17  |      18.2       |
|  -16  |      18.9       |
|  -15  |      19.6       |
|  -14  |      20.3       |
|  -13  |       21        |
|  -12  |      21.7       |
|  -11  |      22.5       |
|  -10  |      23.2       |
|  -9   |      23.9       |
|  -8   |      24.7       |
|  -7   |      25.4       |
|  -6   |      26.2       |
|  -5   |      26.9       |
|  -4   |      27.7       |
|  -3   |      28.4       |
|  -2   |      29.2       |
|  -1   |      29.9       |
|   0   |      30.7       |
|   1   |      31.5       |
|   2   |      32.3       |
|   3   |       33        |
|   4   |      33.8       |
|   5   |      34.6       |
|   6   |      35.4       |
|   7   |      36.2       |
|   8   |       37        |
|   9   |      37.8       |
|  10   |      38.6       |
|  11   |      39.4       |
|  12   |      40.2       |
|  13   |       41        |
|  14   |      41.8       |
|  15   |      42.7       |
|  16   |      43.5       |
|  17   |      44.3       |
|  18   |      45.2       |
|  19   |       46        |
|  20   |      46.9       |

Note that insurance is advantageous when the count is greater than 3.

# generate-dealer-outcome-distribution.jl
#
println(
"""
Generates the distribution of the dealer's outcomes by the card showing and the count.
"""
)

using Blackjack
using DataFrames
using JSON
using OffsetArrays

const NUMBER_OF_SHOES = 1_000
configuration = Blackjack.DEFAULT_CONFIGURATION

const COUNT_RANGE = COUNT_RANGE_PER_DECK * configuration.DECKS_PER_SHOE # The maximum -/+ range of possible counts
const TOTAL_COUNTS = COUNT_RANGE * 2 + 1 # The total number of counts

const HIGHEST_POSSIBLE_SCORE = BUST
const LOWEST_TWO_CARD_SCORE = 2
const HIGHEST_TWO_CARD_SCORE_EX_BJ = 20

# Print the rules that are in use.
println("Rules in use:")
println(Blackjack.Rules.deconstruct(configuration.RULES))

# Convert a value to a percentage for display.
to_percent(x, digits = 0) = round(x * 100, digits=digits)

println("Simulating $NUMBER_OF_SHOES shoes...")

outcomes = OffsetArray(zeros(Int64, TOTAL_COUNTS, 10, HIGHEST_POSSIBLE_SCORE), -COUNT_RANGE:COUNT_RANGE, 1:10, 1:HIGHEST_POSSIBLE_SCORE)

shoe = Blackjack.Shoes.Shoe(configuration.DECKS_PER_SHOE, configuration.PENETRATION)
for s in 1:NUMBER_OF_SHOES
    Blackjack.Shoes.shuffle!(shoe)

    while !Blackjack.Shoes.done(shoe)
        true_count = round(Blackjack.Shoes.true_count(shoe))
        hand = [Blackjack.Shoes.deal!(shoe), Blackjack.Shoes.deal!(shoe)]
        under = Blackjack.Rules.value(hand[1]) # Value of the dealer's hidden card
        showing = Blackjack.Rules.value(hand[2]) # Value of the dealer's showing card

        # If rules.dealerChecksForBlackjack is true, then the case of a blackjack is not counted in the outcomes
        # because the round ends immediately before the player can make any kind of decision.
        if configuration.RULES.DEALER_CHECKS_FOR_BLACKJACK
            if (under == ACE && showing == 10) || (under == 10 && showing == ACE)
                continue
            end
        end

        while Blackjack.Rules.dealer_must_hit(hand, configuration.RULES)
            push!(hand, Blackjack.Shoes.deal!(shoe))
        end

        _, score = Blackjack.Rules.value(hand)
        if score > 21
            outcomes[showing, BUST] += 1
        else
            outcomes[showing, score] += 1
        end
    end
    if s % (NUMBER_OF_SHOES ÷ 10) == 0
        println("$(to_percent(s / NUMBER_OF_SHOES * 100))% of $NUMBER_OF_SHOES")
    end
end

# Calculate the distribution
aggregated_distribution = [
    showing_N[i] > 0 ? outcomes[i, j] / Float64(showing_N[i]) : 0
    for i in 1:10, j in 1:HIGHEST_POSSIBLE_SCORE
]

println("Dealer outcome distribution by card showing:")
aggregated_distribution_table = Dict(
    "17 (%)"   => to_percent.(aggregated_distribution[:, 17], 1),
    "18 (%)"   => to_percent.(aggregated_distribution[:, 18], 1),
    "19 (%)"   => to_percent.(aggregated_distribution[:, 19], 1),
    "20 (%)"   => to_percent.(aggregated_distribution[:, 20], 1),
    "21 (%)"   => to_percent.(aggregated_distribution[:, 21], 1),
    "Bust (%)" => to_percent.(aggregated_distribution[:, BUST], 1),
)

aggregated_distribution_df = DataFrame(aggregated_distribution_table)
println(aggregated_distribution_df)
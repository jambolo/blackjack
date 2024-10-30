# generate-next-card-outcome-distribution.jl
#
println(
"""
Generates a distribution of outcomes of drawing one card for each possible score. Aces are counted as 11 only if the
outcome is between 17 and 21.
"""
)

using JSON
#using Plots
#gr() # Use the GR backend for plotting
using DataFrames

using Blackjack

const NUMBER_OF_SHOES = 100_000_000
configuration = Blackjack.DEFAULT_CONFIGURATION

const PROBABILITY_OF_NUMBER = 4.0 / 52.0
const PROBABILITY_OF_ACE = 4.0 / 52.0
const PROBABILITY_OF_FACE = 12.0 / 52.0

const HIGHEST_POSSIBLE_SCORE = BUST
const LOWEST_TWO_CARD_SCORE = 2
const HIGHEST_TWO_CARD_SCORE_EX_BJ = 20

# Print the rules that are in use.
println("Rules in use:")
println(Blackjack.Rules.deconstruct(configuration.RULES))

# Convert a value to a percentage for display.
to_percent(x, digits = 0) = round(x * 100, digits=digits)

# Returns the sums of the range for each row converted to percentage.
ranged_sum_percent(a, range) = [to_percent(sum(row[range]), 1) for row in eachrow(a)]

# Simulate the outcome distribution
outcomes = zeros(Int64, HIGHEST_TWO_CARD_SCORE_EX_BJ, HIGHEST_POSSIBLE_SCORE)
start_N = zeros(Int64, HIGHEST_TWO_CARD_SCORE_EX_BJ)
shoe = Blackjack.Shoes.Shoe(configuration.DECKS_PER_SHOE, configuration.PENETRATION)

println("Simulating $NUMBER_OF_SHOES shoes...")
for s in 1:NUMBER_OF_SHOES
    Blackjack.Shoes.shuffle!(shoe)

    # Deal each hand in the shoe up to the penetration limit and record the outcomes.
    while !Blackjack.Shoes.done(shoe)
        # Deal the starting hand.
        start = Blackjack.Shoes.deal_value!(shoe) + Blackjack.Shoes.deal_value!(shoe)
        start_N[start] += 1

        # Deal the next card.
        card = Blackjack.Shoes.deal_value!(shoe)
        if card == ACE
            if start >= 6 && start <= 10
                outcomes[start, start + 11] += 1
            else
                outcomes[start, start + 1] += 1
            end
        else
            if start + card <= 21
                outcomes[start, start + card] += 1
            else
                outcomes[start, BUST] += 1
            end
        end
    end

    if s % (NUMBER_OF_SHOES ÷ 10) == 0
        println("$(to_percent(s / NUMBER_OF_SHOES))% of $NUMBER_OF_SHOES shoes.")
    end
end


distribution = [
    start_N[i] > 0 ? Float64(outcomes[i, j]) / Float64(start_N[i]) : 0.0
    for i in 1:HIGHEST_TWO_CARD_SCORE_EX_BJ,
        j in 1:HIGHEST_POSSIBLE_SCORE]


# Save the distribution to a JSON file
out = Dict(
    "number_of_shoes" => NUMBER_OF_SHOES,
    "configuration" => configuration,
    "distribution" => distribution
)
open("data/nextCardOutcomeDistribution.json", "w") do io
    JSON.print(io, out)
end

# Display the outcome distribution
distribution_table = to_percent.(distribution, 1)
distribution_df = DataFrame(distribution_table, :auto)
println(distribution_df)

outcome_ranges = Dict(
    "3-16" => 3:16,
    "17-21" => 17:21,
    "BUST" => BUST:BUST
)

range_table = Dict(
    key => ranged_sum_percent(distribution, range) for (key, range) in outcome_ranges
)
range_df = DataFrame(range_table)
println(range_df)

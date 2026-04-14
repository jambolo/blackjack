# generate-next-card-outcome-distribution.jl
#
println("""
Generates a distribution of outcomes of drawing one card for each possible score. Aces are counted as 11 only if the
outcome is between 17 and 21.
""")

using Blackjack
using DataFrames
using JSON
using PrettyTables

const NUMBER_OF_SHOES = 10_000_000
const NUMBER_OF_SHOES_STR = commafy(NUMBER_OF_SHOES)

configuration = Blackjack.DEFAULT_CONFIGURATION

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

println("Simulating $NUMBER_OF_SHOES_STR shoes...")
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
        println("$(to_percent(s / NUMBER_OF_SHOES))% of $NUMBER_OF_SHOES_STR shoes.")
    end
end
println()

distribution = [
    start_N[i] > 0 ? Float64(outcomes[i, j]) / Float64(start_N[i]) : 0.0
    for i in 1:HIGHEST_TWO_CARD_SCORE_EX_BJ,
        j in 1:HIGHEST_POSSIBLE_SCORE]


# Output the results.
struct Output
    number_of_shoes::Int64
    configuration::Blackjack.Configuration
    next_card_outcome_distribution::Matrix{Float64}
end

open("data/next-card-outcome-distribution.json", "w") do io
    JSON.print(io, Output(NUMBER_OF_SHOES, configuration, distribution))
    println("Wrote next card outcome distribution to data/next-card-outcome-distribution.json")
    println()
end

# Display the outcome distribution
distribution_table = to_percent.(distribution, 1)
distribution_df = DataFrame(distribution_table, [string.(1:21); "BUST"])
insertcols!(distribution_df, 1, "Start" => collect(1:HIGHEST_TWO_CARD_SCORE_EX_BJ))

println("Next card outcome distribution:")
println("After dealing $(configuration.DECKS_PER_SHOE - configuration.PENETRATION) decks from a $(configuration.DECKS_PER_SHOE)-deck shoe for $NUMBER_OF_SHOES_STR shoes.")
let df = distribution_df[2:end, [1; 3:end]]
    pretty_table(df; backend = :markdown, column_labels = names(df),
        formatters = [(v, i, j) -> j > 1 && v == 0.0 ? "" : v])
end
println()

range_df = DataFrame(
    "Start" => collect(1:HIGHEST_TWO_CARD_SCORE_EX_BJ),
    "3-16"  => ranged_sum_percent(distribution, 3:16),
    "17-21" => ranged_sum_percent(distribution, 17:21),
    "Bust"  => ranged_sum_percent(distribution, BUST:BUST)
)

println("Next card outcome distribution (aggregated ranges):")
println("After dealing $(configuration.DECKS_PER_SHOE - configuration.PENETRATION) decks from a $(configuration.DECKS_PER_SHOE)-deck shoe for $NUMBER_OF_SHOES_STR shoes.")
pretty_table(range_df[2:end, :]; backend = :markdown, column_labels = names(range_df),
    formatters = [(v, i, j) -> j > 1 && v == 0.0 ? "" : v])

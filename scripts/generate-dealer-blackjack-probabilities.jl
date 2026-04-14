# generate-dealer-blackjack-probabilities.jl
#
println("""
Computes the probability of a dealer showing an ace having a blackjack by count from `data/card-densities-by-count.json`.
Results are written to `data/dealer-blackjack-probabilities-by-count.json`. A summary is written to the console.
""")

using Blackjack
using DataFrames
using JSON
using PrettyTables

configuration = Blackjack.DEFAULT_CONFIGURATION

const COUNT_RANGE = COUNT_RANGE_PER_DECK * configuration.DECKS_PER_SHOE

# Print the rules that are in use.
println("Rules in use:")
println(Blackjack.Rules.deconstruct(configuration.RULES))

# Maps a signed count value to a 1-based array index
count_index(c) = c + COUNT_RANGE + 1

# Convert a value to a percentage for display.
to_percent(x, digits = 0) = round(x * 100, digits=digits)

# card_densities_by_count is serialized column-major: outer index = card (1-13), inner index = count_index
data = JSON.parsefile("data/card-densities-by-count.json")
card_densities_by_count = data["card_densities_by_count"]

# Probability of a 10-value hole card (dealer blackjack) for each count
probabilities = [
    card_densities_by_count[10][count_index(c)] +
    card_densities_by_count[JACK][count_index(c)] +
    card_densities_by_count[QUEEN][count_index(c)] +
    card_densities_by_count[KING][count_index(c)]
    for c in -COUNT_RANGE:COUNT_RANGE
]

# Output the results.
struct Output
    configuration::Blackjack.Configuration
    dealer_blackjack_probabilities_by_count::Vector{Float64}
end

open("data/dealer-blackjack-probabilities-by-count.json", "w") do io
    JSON.print(io, Output(configuration, probabilities))
    println("Wrote dealer blackjack probabilities by count to data/dealer-blackjack-probabilities-by-count.json")
    println()
end

df = DataFrame(
    "Count" => collect(-20:20),
    "%"     => [to_percent(probabilities[count_index(c)], 1) for c in -20:20]
)

println("Dealer blackjack probabilities:")
pretty_table(df; backend = :markdown, column_labels = names(df))

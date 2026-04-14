# generate-count-probability-data.jl
#
println("""
Notes the true count after dealing half of a 6-deck shoe many times and writes the probability of each count
to `data/count-probabilities.json`. A summary is written to the console.
""")

using Blackjack
using DataFrames
using JSON
using PrettyTables
using Printf

const NUMBER_OF_SHOES = 100_000_000
const NUMBER_OF_SHOES_STR = commafy(NUMBER_OF_SHOES)

configuration = Blackjack.DEFAULT_CONFIGURATION

const COUNT_RANGE  = COUNT_RANGE_PER_DECK * configuration.DECKS_PER_SHOE
const CARDS_PER_SHOE = DECK_SIZE * configuration.DECKS_PER_SHOE
const DEALT_CARDS  = round(Int, CARDS_PER_SHOE / 2)

# Print the rules that are in use.
println("Rules in use:")
println(Blackjack.Rules.deconstruct(configuration.RULES))

# Maps a signed count value to a 1-based array index
count_index(c) = c + COUNT_RANGE + 1

# Convert a value to a percentage for display.
to_percent(x, digits = 0) = round(x * 100, digits=digits)

count_frequencies = zeros(Int64, 2 * COUNT_RANGE + 1)
shoe = Blackjack.Shoes.Shoe(configuration.DECKS_PER_SHOE, 0.0)

println("Simulating $NUMBER_OF_SHOES_STR shoes...")
for s in 1:NUMBER_OF_SHOES
    Blackjack.Shoes.shuffle!(shoe)
    tc = clamp(round(Int, Blackjack.Shoes.true_count_after(shoe, DEALT_CARDS)), -COUNT_RANGE, COUNT_RANGE)
    count_frequencies[count_index(tc)] += 1

    if s % (NUMBER_OF_SHOES ÷ 10) == 0
        println("$(to_percent(s / NUMBER_OF_SHOES))% of $NUMBER_OF_SHOES_STR shoes.")
    end
end
println()

count_probabilities = count_frequencies ./ NUMBER_OF_SHOES

# Output the results.
struct Output
    number_of_shoes::Int64
    configuration::Blackjack.Configuration
    count_probabilities::Vector{Float64}
end

open("data/count-probabilities.json", "w") do io
    JSON.print(io, Output(NUMBER_OF_SHOES, configuration, count_probabilities))
    println("Wrote count probabilities to data/count-probabilities.json")
    println()
end

counts_col = [c for c in -20:20 if count_frequencies[count_index(c)] > 0]
df = DataFrame(
    "Count" => counts_col,
    "N"     => [count_frequencies[count_index(c)] for c in counts_col],
    "%"     => [count_probabilities[count_index(c)] * 100 for c in counts_col]
)

println("Count probabilities:")
println("After $NUMBER_OF_SHOES_STR shoes.")
pretty_table(df; backend = :markdown, column_labels = names(df), formatters = [(v, i, j) -> j == 3 ? @sprintf("%.2f", v) : v])

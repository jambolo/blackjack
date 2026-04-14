# generate-true-count-distribution.jl
#
println("""
Computes the distribution of true counts in a shoe as each card is dealt to the deck penetration limit.
Results are written to `data/true-count-distribution.json`. A summary is written to the console.
""")

using Blackjack
using DataFrames
using JSON
using PrettyTables
using Printf

const NUMBER_OF_SHOES = 10_000_000
const NUMBER_OF_SHOES_STR = commafy(NUMBER_OF_SHOES)

configuration = Blackjack.DEFAULT_CONFIGURATION

const COUNT_RANGE         = COUNT_RANGE_PER_DECK * configuration.DECKS_PER_SHOE
const CARDS_PLAYED_PER_SHOE = floor(Int, (configuration.DECKS_PER_SHOE - configuration.PENETRATION) * DECK_SIZE)

# Print the rules that are in use.
println("Rules in use:")
println(Blackjack.Rules.deconstruct(configuration.RULES))

# Maps a signed count value to a 1-based array index
count_index(c) = c + COUNT_RANGE + 1

# Convert a value to a percentage for display.
to_percent(x, digits = 0) = round(x * 100, digits=digits)

count_frequencies = zeros(Int64, 2 * COUNT_RANGE + 1)
shoe = Blackjack.Shoes.Shoe(configuration.DECKS_PER_SHOE, configuration.PENETRATION)

println("Simulating $NUMBER_OF_SHOES_STR shoes...")
for s in 1:NUMBER_OF_SHOES
    Blackjack.Shoes.shuffle!(shoe)

    while !Blackjack.Shoes.done(shoe)
        Blackjack.Shoes.deal!(shoe)
        tc = clamp(round(Int, Blackjack.Shoes.true_count(shoe)), -COUNT_RANGE, COUNT_RANGE)
        count_frequencies[count_index(tc)] += 1
    end

    if s % (NUMBER_OF_SHOES ÷ 10) == 0
        println("$(to_percent(s / NUMBER_OF_SHOES))% of $NUMBER_OF_SHOES_STR shoes.")
    end
end
println()

true_count_distribution = count_frequencies ./ (CARDS_PLAYED_PER_SHOE * NUMBER_OF_SHOES)

# Output the results.
struct Output
    number_of_shoes::Int64
    configuration::Blackjack.Configuration
    true_count_distribution::Vector{Float64}
end

open("data/true-count-distribution.json", "w") do io
    JSON.print(io, Output(NUMBER_OF_SHOES, configuration, true_count_distribution))
    println("Wrote true count distribution to data/true-count-distribution.json")
    println()
end

df = DataFrame(
    "Count" => collect(-20:20),
    "%"     => [true_count_distribution[count_index(c)] * 100 for c in -20:20]
)

println("True count distribution:")
println("After dealing $(configuration.DECKS_PER_SHOE - configuration.PENETRATION) decks from a $(configuration.DECKS_PER_SHOE)-deck shoe for $NUMBER_OF_SHOES_STR shoes.")
pretty_table(df; backend = :markdown, column_labels = names(df), formatters = [(v, i, j) -> j == 2 ? @sprintf("%.2f", v) : v])

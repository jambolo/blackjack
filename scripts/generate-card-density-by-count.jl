# generate-card-density-by-count.jl
#
println(
"""
Computes the average density of each card for each count after each card is dealt up to the deck penetration
limit. Results are written to the file `data/cardDensitiesByCount.json`. A summary is written to the console.
"""
)

using Blackjack
using JSON
using DataFrames


const NUMBER_OF_SHOES = 10_000_000
configuration = Blackjack.DEFAULT_CONFIGURATION

const COUNT_RANGE = COUNT_RANGE_PER_DECK * configuration.DECKS_PER_SHOE
const NUMBER_OF_COUNT_VALUES = 2 * COUNT_RANGE + 1
const NUMBER_OF_CARDS_DEALT = floor((configuration.DECKS_PER_SHOE - configuration.PENETRATION) * DECK_SIZE)

# Print the rules that are in use.
println("Rules in use:")
println(Blackjack.Rules.deconstruct(configuration.RULES))

# Sums the densities of low, high, and uncounted cards.
function densities_by_type(f::Vector{Float64})
    low = sum(f[c] for c in LOW_CARDS)
    uncounted = sum(f[c] for c in UNCOUNTED_CARDS)
    high = sum(f[c] for c in HIGH_CARDS)
    return (low, uncounted, high)
end

# Returns the index of the count in the count frequencies array.
count_index(c) = c + COUNT_RANGE + 1

# For a huge number of rounds:
#   1. Shuffle the shoe.
#   2. For each card in the shoe, up to the penetration limit,
#       a. For the true count, accumulate the density of each card in the remaining_cards cards.

# Accumulated densities of each card for each count.
card_densities_by_count = zeros(Float64, NUMBER_OF_COUNT_VALUES, NUMBER_OF_CARDS_PER_SUIT)

# Number of occurrences for each count.
count_frequencies = zeros(Int64, NUMBER_OF_COUNT_VALUES)

# The shoe
shoe = Blackjack.Shoes.Shoe(configuration.DECKS_PER_SHOE, configuration.PENETRATION)

println("Simulating $NUMBER_OF_SHOES shoes...")
for s in 1:NUMBER_OF_SHOES
    Blackjack.Shoes.shuffle!(shoe)

    # For each card, the number remaining in the shoe.
    remaining_cards = fill(NUMBER_OF_SUITS * configuration.DECKS_PER_SHOE, NUMBER_OF_CARDS_PER_SUIT)

    # Deal each card in the shoe up to the penetration limit. After each card is dealt, accumulate the density of each
    # card in the remaining_cards shoe.
    while !Blackjack.Shoes.done(shoe)
        # Deal the next card.
        card = Blackjack.Shoes.deal!(shoe)
        true_count = round(Int, Blackjack.Shoes.true_count(shoe))
        i = count_index(true_count)

        # Update the number of occurrences for this count.
        count_frequencies[i] += 1

        # Decrement the number of this card remaining in the shoe.
        remaining_cards[card] -= 1

        # Accumulate the densities of each remaining card for this count.
        cards_remaining = Blackjack.Shoes.remaining(shoe)
        card_densities_by_count[i, :] .+= remaining_cards ./ cards_remaining
    end

    if s % (NUMBER_OF_SHOES ÷ 10) == 0
        println("$(round(s / NUMBER_OF_SHOES * 100))% of $NUMBER_OF_SHOES shoes.")
    end
end

# Compute the average density of each card for each count.
for i in 1:NUMBER_OF_COUNT_VALUES
    f = count_frequencies[i]
    if f > 0
        card_densities_by_count[i, :] ./= f
    else
        card_densities_by_count[i, :] .= 0
    end
end

# Output the results.
struct Output
    number_of_shoes::Int64
    configuration::Blackjack.Configuration
    card_densities_by_count
end

output = Output(NUMBER_OF_SHOES, configuration, card_densities_by_count)
open("data/cardDensitiesByCount.json", "w") do io
    JSON.print(io, output)
end

# Summarize card density by count
counts = collect(-20:20)
table = []
for c in -20:20
    i = count_index(c)
    low, uncounted, high = densities_by_type(card_densities_by_count[i, :])
    push!(table, Dict(
        "Count" => c,
        "Low (%)" => round(low * 100, digits=1),
        "Uncounted (%)" => round(uncounted * 100, digits=1),
        "High (%)" => round(high * 100, digits=1)
    ))
end


# Convert the array of dictionaries to a DataFrame
df = DataFrame(table)

# Display the DataFrame
println(df)

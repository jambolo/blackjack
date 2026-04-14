# generate-dealer-outcome-distribution.jl
#
println("""
Generates the distribution of the dealer's outcomes by the card showing and the count.
""")

using Blackjack
using DataFrames
using JSON
using OffsetArrays
using PrettyTables

const NUMBER_OF_SHOES = 10_000_000
const NUMBER_OF_SHOES_STR = commafy(NUMBER_OF_SHOES)

configuration = Blackjack.DEFAULT_CONFIGURATION

const COUNT_RANGE = COUNT_RANGE_PER_DECK * configuration.DECKS_PER_SHOE
const TOTAL_COUNTS = COUNT_RANGE * 2 + 1
const HIGHEST_POSSIBLE_SCORE = BUST

# Print the rules that are in use.
println("Rules in use:")
println(Blackjack.Rules.deconstruct(configuration.RULES))

to_percent(x, digits = 0) = round(x * 100, digits=digits)

println("Simulating $NUMBER_OF_SHOES_STR shoes...")

outcomes = OffsetArray(zeros(Int64, TOTAL_COUNTS, 10, HIGHEST_POSSIBLE_SCORE), -COUNT_RANGE:COUNT_RANGE, 1:10, 1:HIGHEST_POSSIBLE_SCORE)
shoe = Blackjack.Shoes.Shoe(configuration.DECKS_PER_SHOE, configuration.PENETRATION)

for s in 1:NUMBER_OF_SHOES
    Blackjack.Shoes.shuffle!(shoe)

    while !Blackjack.Shoes.done(shoe)
        true_count = clamp(round(Int, Blackjack.Shoes.true_count(shoe)), -COUNT_RANGE, COUNT_RANGE)
        hand = [Blackjack.Shoes.deal!(shoe), Blackjack.Shoes.deal!(shoe)]
        under   = Blackjack.Rules.value(hand[1])
        showing = Blackjack.Rules.value(hand[2])

        if configuration.RULES.DEALER_CHECKS_FOR_BLACKJACK
            if (under == ACE && showing == 10) || (under == 10 && showing == ACE)
                continue
            end
        end

        while Blackjack.Rules.dealer_must_hit(hand, configuration.RULES)
            push!(hand, Blackjack.Shoes.deal!(shoe))
        end

        _, score = Blackjack.Rules.value(hand)
        outcomes[true_count, showing, score > 21 ? BUST : score] += 1
    end

    if s % (NUMBER_OF_SHOES ÷ 10) == 0
        println("$(to_percent(s / NUMBER_OF_SHOES))% of $NUMBER_OF_SHOES_STR shoes.")
    end
end
println()

showing_totals = [sum(outcomes[c, i, j] for c in -COUNT_RANGE:COUNT_RANGE, j in 1:HIGHEST_POSSIBLE_SCORE) for i in 1:10]
aggregated_distribution = [
    showing_totals[i] > 0 ? sum(outcomes[c, i, j] for c in -COUNT_RANGE:COUNT_RANGE) / Float64(showing_totals[i]) : 0.0
    for i in 1:10, j in 1:HIGHEST_POSSIBLE_SCORE
]

# Output the results.
struct Output
    number_of_shoes::Int64
    configuration::Blackjack.Configuration
    dealer_outcome_distribution::Matrix{Float64}
end

open("data/dealer-outcome-distribution.json", "w") do io
    JSON.print(io, Output(NUMBER_OF_SHOES, configuration, aggregated_distribution))
    println("Wrote dealer outcome distribution to data/dealer-outcome-distribution.json")
    println()
end

println("Dealer outcome distribution by card showing:")
println("After dealing $(configuration.DECKS_PER_SHOE - configuration.PENETRATION) decks from a $(configuration.DECKS_PER_SHOE)-deck shoe for $NUMBER_OF_SHOES_STR shoes.")
showing_labels = [i == 1 ? "Ace" : string(i) for i in 1:10]
df = DataFrame(
    "Showing"  => showing_labels,
    "17 (%)"   => to_percent.(aggregated_distribution[:, 17], 1),
    "18 (%)"   => to_percent.(aggregated_distribution[:, 18], 1),
    "19 (%)"   => to_percent.(aggregated_distribution[:, 19], 1),
    "20 (%)"   => to_percent.(aggregated_distribution[:, 20], 1),
    "21 (%)"   => to_percent.(aggregated_distribution[:, 21], 1),
    "Bust (%)" => to_percent.(aggregated_distribution[:, BUST], 1),
)
pretty_table(df; backend = :markdown, column_labels = names(df))

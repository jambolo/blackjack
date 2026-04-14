# analyze-kings-bounty.jl
#
println("""
Computes the expected value of the King's Bounty side bet by simulating a large number of rounds.
Results are written to `data/kings-bounty-analysis.json`. A summary is written to the console.
""")

using Blackjack
using DataFrames
using JSON
using Printf
using PrettyTables

const NUMBER_OF_SHOES = 10_000
const NUMBER_OF_SHOES_STR = commafy(NUMBER_OF_SHOES)

configuration = Blackjack.DEFAULT_CONFIGURATION
const DECKS_PER_SHOE = configuration.DECKS_PER_SHOE
const PENETRATION    = configuration.PENETRATION

const COUNT_RANGE      = COUNT_RANGE_PER_DECK * DECKS_PER_SHOE
const TEN_COUNT_RANGE  = 4 * NUMBER_OF_SUITS * DECKS_PER_SHOE
const KING_COUNT_RANGE = NUMBER_OF_SUITS * DECKS_PER_SHOE
const SPADE = 1
const ACCUMULATE_RETURNS = false   # flip to true to populate `returns` tensor (expensive)

println("Rules in use:")
println(Blackjack.Rules.deconstruct(configuration.RULES))

# Helpers (match other scripts)
count_index(c) = c + COUNT_RANGE + 1
to_percent(x, digits = 0) = round(x * 100, digits = digits)

const OUTCOMES = (
    "Kings of Spades + BJ", "Kings of Spades", "Suited Kings", "Suited Q/J/10",
    "Suited 20", "Unsuited Kings", "Unsuited 20", "Other",
)
const PAYOUTS = Dict(
    "Kings of Spades + BJ" => 1000, "Kings of Spades" => 100, "Suited Kings" => 30,
    "Suited Q/J/10" => 20, "Suited 20" => 9, "Unsuited Kings" => 6,
    "Unsuited 20" => 4, "Other" => -1,
)

println("Payout table:")
for outcome in OUTCOMES
    println("- $(outcome): $(PAYOUTS[outcome])")
end

# Precomputed dealer-BJ probability per count (indexed via count_index).
# dealer_bj_by_count = P(10-value hole card | dealer shows ACE).
# Multiply by P(ACE) to get the unconditional P(dealer BJ) ≈ P(ACE) × P(10-value)
dealer_bj_data = JSON.parsefile("data/dealer-blackjack-probabilities-by-count.json")
dealer_bj_by_count = Vector{Float64}(dealer_bj_data["dealer_blackjack_probabilities_by_count"])
card_densities_data = JSON.parsefile("data/card-densities-by-count.json")
ace_density_by_count = Vector{Float64}(card_densities_data["card_densities_by_count"][ACE])
dealer_bj_probability_by_count = ace_density_by_count .* dealer_bj_by_count

# Frequency accumulators — Matrix{Int} with one column per outcome for fast hot-loop updates;
# converted to Dicts at JSON-write time.
frequencies               = zeros(Int, length(OUTCOMES))
frequencies_by_count      = zeros(Int, 2*COUNT_RANGE+1,    length(OUTCOMES))
frequencies_by_ten_count  = zeros(Int, TEN_COUNT_RANGE+1,  length(OUTCOMES))
frequencies_by_king_count = zeros(Int, KING_COUNT_RANGE+1, length(OUTCOMES))

count_frequencies      = zeros(Int, 2*COUNT_RANGE+1)
ten_count_frequencies  = zeros(Int, TEN_COUNT_RANGE+1)
king_count_frequencies = zeros(Int, KING_COUNT_RANGE+1)

# `returns` tensor: only allocate if ACCUMULATE_RETURNS
returns = ACCUMULATE_RETURNS ?
    zeros(Int, 2*COUNT_RANGE+1, TEN_COUNT_RANGE+1, KING_COUNT_RANGE+1, 2) :
    nothing

shoe = Blackjack.Shoes.Shoe(DECKS_PER_SHOE, PENETRATION)

number_of_hands = 0

println("Simulating $NUMBER_OF_SHOES_STR shoes...")
for s in 1:NUMBER_OF_SHOES
    Blackjack.Shoes.shuffle!(shoe)
    running_ten_count  = TEN_COUNT_RANGE
    running_king_count = KING_COUNT_RANGE

    while !Blackjack.Shoes.done(shoe)
        # True counts BEFORE dealing the next hand
        remaining_decks = Blackjack.Shoes.remaining(shoe) / DECK_SIZE
        true_count      = round(Int, Blackjack.Shoes.true_count(shoe))
        true_ten_count  = round(Int, running_ten_count  / remaining_decks)
        true_king_count = round(Int, running_king_count / remaining_decks)

        ci = count_index(true_count)
        count_frequencies[ci] += 1
        ten_count_frequencies[true_ten_count + 1]   += 1
        king_count_frequencies[true_king_count + 1] += 1

        # Deal two cards; Shoe updates running_count internally.
        card_a = Blackjack.Shoes.deal!(shoe)
        rank_a = Blackjack.Rules.rank(card_a)
        suit_a = Blackjack.Rules.suit(card_a)
        rank_a >= 10   && (running_ten_count  -= 1)
        rank_a == KING && (running_king_count -= 1)

        card_b = Blackjack.Shoes.deal!(shoe)
        rank_b = Blackjack.Rules.rank(card_b)
        suit_b = Blackjack.Rules.suit(card_b)
        rank_b >= 10   && (running_ten_count  -= 1)
        rank_b == KING && (running_king_count -= 1)

        global number_of_hands += 1

        _, total = Blackjack.Rules.value([rank_a, rank_b])
        outcome_idx = if total == 20
            if suit_a == suit_b
                if rank_a == rank_b
                    if rank_a == KING
                        if suit_a == SPADE
                            rand() < dealer_bj_probability_by_count[ci] ? 1 : 2   # K♠K♠+BJ or K♠K♠
                        else
                            3   # Suited Kings
                        end
                    else
                        4   # Suited Q/J/10
                    end
                else
                    5   # Suited 20
                end
            else
                if rank_a == KING && rank_b == KING
                    6   # Unsuited Kings
                else
                    7   # Unsuited 20
                end
            end
        else
            8   # Other
        end

        frequencies[outcome_idx] += 1
        frequencies_by_count[ci, outcome_idx] += 1
        frequencies_by_ten_count[true_ten_count + 1, outcome_idx] += 1
        frequencies_by_king_count[true_king_count + 1, outcome_idx] += 1

        if ACCUMULATE_RETURNS
            if true_count >= 6 && true_ten_count >= 18 && true_king_count >= 6
                payout = PAYOUTS[OUTCOMES[outcome_idx]]
                for cc in -COUNT_RANGE:true_count, tt in 0:true_ten_count, kk in 0:true_king_count
                    returns[count_index(cc), tt+1, kk+1, 1] += payout
                    returns[count_index(cc), tt+1, kk+1, 2] += 1
                end
            end
        end
    end

    if s % (NUMBER_OF_SHOES ÷ 10) == 0
        println("$(round(Int, s / NUMBER_OF_SHOES * 100))% of $NUMBER_OF_SHOES_STR shoes.")
    end
end
println("Number of hands: $(commafy(number_of_hands))")

# JSON output. Convert per-bucket rows to Dicts for readability.
outcome_freq_dict(row) = Dict(OUTCOMES[i] => row[i] for i in 1:length(OUTCOMES))

struct Output
    number_of_shoes::Int64
    number_of_hands::Int64
    configuration::Blackjack.Configuration
    payouts::Dict{String,Int}
    frequencies::Dict{String,Int}
    frequencies_by_count::Vector{Dict{String,Int}}
    frequencies_by_ten_count::Vector{Dict{String,Int}}
    frequencies_by_king_count::Vector{Dict{String,Int}}
    count_frequencies::Vector{Int}
    ten_count_frequencies::Vector{Int}
    king_count_frequencies::Vector{Int}
end

output = Output(
    NUMBER_OF_SHOES, number_of_hands, configuration,
    Dict(string(k) => v for (k, v) in PAYOUTS),
    outcome_freq_dict(frequencies),
    [outcome_freq_dict(@view frequencies_by_count[i, :])      for i in 1:size(frequencies_by_count, 1)],
    [outcome_freq_dict(@view frequencies_by_ten_count[i, :])  for i in 1:size(frequencies_by_ten_count, 1)],
    [outcome_freq_dict(@view frequencies_by_king_count[i, :]) for i in 1:size(frequencies_by_king_count, 1)],
    count_frequencies, ten_count_frequencies, king_count_frequencies,
)

open("data/kings-bounty-analysis.json", "w") do io
    JSON.print(io, output)
    println("Wrote kings bounty analysis to data/kings-bounty-analysis.json")
    println()
end

# Console summary: one row per outcome plus a total row.
total_payout = 0
total_occurrence = 0
rows = []
for i in 1:length(OUTCOMES)
    n = frequencies[i]
    payout = PAYOUTS[OUTCOMES[i]] * n
    push!(rows, (
        Hand = OUTCOMES[i],
        var"Frequency (%)" = to_percent(n / number_of_hands, 4),
        Payout = round(payout / number_of_hands, digits = 4),
    ))
    global total_payout += payout
    global total_occurrence += n
end
push!(rows, (
    Hand = "Total",
    var"Frequency (%)" = to_percent(total_occurrence / number_of_hands, 4),
    Payout = round(total_payout / number_of_hands, digits = 4),
))
df = DataFrame(rows)
println("Kings Bounty outcomes:")
pretty_table(df; backend = :markdown, column_labels = names(df), formatters = [(v, i, j) -> j in (2, 3) ? @sprintf("%.4f", v) : v,])

#=
# ── Disabled analysis sections ──
# These require ACCUMULATE_RETURNS = true to populate the `returns` tensor.

# Find the boundaries of the return table in which the return is not negative.
min_count = let
    result = COUNT_RANGE; found = false
    for c in -COUNT_RANGE:COUNT_RANGE
        found && break
        ci = count_index(c)
        for t in 0:TEN_COUNT_RANGE
            found && break
            for k in 0:KING_COUNT_RANGE
                if returns[ci, t+1, k+1, 1] > 0
                    result = c; found = true; break
                end
            end
        end
    end
    result
end
max_count = let
    result = -COUNT_RANGE; found = false
    for c in COUNT_RANGE:-1:-COUNT_RANGE
        found && break
        ci = count_index(c)
        for t in 0:TEN_COUNT_RANGE
            found && break
            for k in 0:KING_COUNT_RANGE
                if returns[ci, t+1, k+1, 1] > 0
                    result = c; found = true; break
                end
            end
        end
    end
    result
end
min_ten_count = let
    result = TEN_COUNT_RANGE; found = false
    for t in 0:TEN_COUNT_RANGE
        found && break
        for c in -COUNT_RANGE:COUNT_RANGE
            found && break
            ci = count_index(c)
            for k in 0:KING_COUNT_RANGE
                if returns[ci, t+1, k+1, 1] > 0
                    result = t; found = true; break
                end
            end
        end
    end
    result
end
max_ten_count = let
    result = 0; found = false
    for t in TEN_COUNT_RANGE:-1:0
        found && break
        for c in -COUNT_RANGE:COUNT_RANGE
            found && break
            ci = count_index(c)
            for k in 0:KING_COUNT_RANGE
                if returns[ci, t+1, k+1, 1] > 0
                    result = t; found = true; break
                end
            end
        end
    end
    result
end
min_king_count = let
    result = KING_COUNT_RANGE; found = false
    for k in 0:KING_COUNT_RANGE
        found && break
        for c in -COUNT_RANGE:COUNT_RANGE
            found && break
            ci = count_index(c)
            for t in 0:TEN_COUNT_RANGE
                if returns[ci, t+1, k+1, 1] > 0
                    result = k; found = true; break
                end
            end
        end
    end
    result
end
max_king_count = let
    result = 0; found = false
    for k in KING_COUNT_RANGE:-1:0
        found && break
        for c in -COUNT_RANGE:COUNT_RANGE
            found && break
            ci = count_index(c)
            for t in 0:TEN_COUNT_RANGE
                if returns[ci, t+1, k+1, 1] > 0
                    result = k; found = true; break
                end
            end
        end
    end
    result
end

println("min_count: $min_count")
println("max_count: $max_count")
println("min_ten_count: $min_ten_count")
println("max_ten_count: $max_ten_count")
println("min_king_count: $min_king_count")
println("max_king_count: $max_king_count")

# Find the location of the maximum return.
best = -Inf
best_count = 0; best_ten_count = 0; best_king_count = 0
for c in -COUNT_RANGE:COUNT_RANGE
    ci = count_index(c)
    for t in 0:TEN_COUNT_RANGE, k in 0:max_king_count
        if returns[ci, t+1, k+1, 1] > best
            best = Float64(returns[ci, t+1, k+1, 1])
            best_count = c; best_ten_count = t; best_king_count = k
        end
    end
end
println("Maximum return:")
println("  when count >= $best_count, 10-count >= $best_ten_count, king-count >= $best_king_count")
println("    overall: $(best / number_of_hands)")
println("    per bet : $(best / returns[count_index(best_count), best_ten_count+1, best_king_count+1, 2])")

# Frequencies by count table
rows_by_count = []
for c in -20:20
    ci = count_index(c)
    count_frequencies[ci] == 0 && continue
    n_total = count_frequencies[ci]
    total_payout_c = 0
    row = Dict{String,Any}("Count" => c)
    for (i, outcome) in enumerate(OUTCOMES)
        n = frequencies_by_count[ci, i]
        row[outcome] = to_percent(n / n_total, 4)
        total_payout_c += PAYOUTS[outcome] * n
    end
    row["Total Payout"] = round(total_payout_c / n_total, digits = 4)
    push!(rows_by_count, row)
end
df_by_count = DataFrame(rows_by_count)
println("Frequencies by count:")
pretty_table(df_by_count; backend = :markdown)

# Frequencies by ten-count table
rows_by_ten_count = []
for t in 0:TEN_COUNT_RANGE
    ten_count_frequencies[t+1] == 0 && continue
    n_total = ten_count_frequencies[t+1]
    total_payout_t = 0
    row = Dict{String,Any}("10 Count" => t)
    for (i, outcome) in enumerate(OUTCOMES)
        n = frequencies_by_ten_count[t+1, i]
        row[outcome] = to_percent(n / n_total, 4)
        total_payout_t += PAYOUTS[outcome] * n
    end
    row["Total Payout"] = round(total_payout_t / n_total, digits = 4)
    push!(rows_by_ten_count, row)
end
df_by_ten_count = DataFrame(rows_by_ten_count)
println("Frequencies by ten-count:")
pretty_table(df_by_ten_count; backend = :markdown)

# Frequencies by king-count table
rows_by_king_count = []
for k in 0:KING_COUNT_RANGE
    king_count_frequencies[k+1] == 0 && continue
    n_total = king_count_frequencies[k+1]
    total_payout_k = 0
    row = Dict{String,Any}("King Count" => k)
    for (i, outcome) in enumerate(OUTCOMES)
        n = frequencies_by_king_count[k+1, i]
        row[outcome] = to_percent(n / n_total, 4)
        total_payout_k += PAYOUTS[outcome] * n
    end
    row["Total Payout"] = round(total_payout_k / n_total, digits = 4)
    push!(rows_by_king_count, row)
end
df_by_king_count = DataFrame(rows_by_king_count)
println("Frequencies by king-count:")
pretty_table(df_by_king_count; backend = :markdown)
=#

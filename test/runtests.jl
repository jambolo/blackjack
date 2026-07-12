using Blackjack
using Test

# ── Cards ─────────────────────────────────────────────────────────────────────

@testset "Cards" begin
    @test ACE   == 1
    @test JACK  == 11
    @test QUEEN == 12
    @test KING  == 13

    @test NUMBER_OF_SUITS           == 4
    @test NUMBER_OF_CARDS_PER_SUIT  == 13
    @test DECK_SIZE                 == 52
    @test DECK_SIZE == NUMBER_OF_SUITS * NUMBER_OF_CARDS_PER_SUIT
end

# ── HiLo ──────────────────────────────────────────────────────────────────────

@testset "HiLo" begin
    @testset "card sets" begin
        @test LOW_CARDS     == [2, 3, 4, 5, 6]
        @test NEUTRAL_CARDS == [7, 8, 9]
        @test HIGH_CARDS    == [ACE, 10, JACK, QUEEN, KING]
    end

    @testset "count value — low cards (+1)" begin
        for card in LOW_CARDS
            @test Blackjack.HiLo.value(card) == 1
        end
    end

    @testset "count value — neutral cards (0)" begin
        for card in NEUTRAL_CARDS
            @test Blackjack.HiLo.value(card) == 0
        end
    end

    @testset "count value — high cards (−1)" begin
        for card in HIGH_CARDS
            @test Blackjack.HiLo.value(card) == -1
        end
    end

    @testset "full deck sums to zero" begin
        total = sum(Blackjack.HiLo.value(c) for c in 1:NUMBER_OF_CARDS_PER_SUIT)
        @test total == 0
    end
end

# ── Rules ─────────────────────────────────────────────────────────────────────

@testset "Rules" begin
    @testset "rank" begin
        # rank cycles 1–13 within each suit block
        @test Blackjack.Rules.rank(1)  == ACE
        @test Blackjack.Rules.rank(13) == KING
        @test Blackjack.Rules.rank(14) == ACE   # second suit, first card
        @test Blackjack.Rules.rank(26) == KING  # second suit, last card
        @test Blackjack.Rules.rank(52) == KING  # last card in shoe
    end

    @testset "suit" begin
        @test Blackjack.Rules.suit(1)  == 1
        @test Blackjack.Rules.suit(13) == 1
        @test Blackjack.Rules.suit(14) == 2
        @test Blackjack.Rules.suit(26) == 2
        @test Blackjack.Rules.suit(27) == 3
        @test Blackjack.Rules.suit(52) == 4
    end

    @testset "rank/suit cover all 52 cards" begin
        ranks = [Blackjack.Rules.rank(i) for i in 1:DECK_SIZE]
        suits = [Blackjack.Rules.suit(i) for i in 1:DECK_SIZE]
        @test sort(unique(ranks)) == collect(ACE:KING)
        @test sort(unique(suits)) == [1, 2, 3, 4]
        # each (rank, suit) pair appears exactly once
        @test length(unique(zip(ranks, suits))) == DECK_SIZE
    end

    @testset "card value" begin
        @test Blackjack.Rules.value(ACE)   == 1
        @test Blackjack.Rules.value(2)     == 2
        @test Blackjack.Rules.value(9)     == 9
        @test Blackjack.Rules.value(10)    == 10
        @test Blackjack.Rules.value(JACK)  == 10
        @test Blackjack.Rules.value(QUEEN) == 10
        @test Blackjack.Rules.value(KING)  == 10
    end

    @testset "hand value — hard totals" begin
        @test Blackjack.Rules.value([10, KING])  == (false, 20)
        @test Blackjack.Rules.value([8, 9])      == (false, 17)
        @test Blackjack.Rules.value([10, 6])     == (false, 16)
        @test Blackjack.Rules.value([7, 7, 7])   == (false, 21)
        # Ace counted as 1 when soft total would exceed 21
        @test Blackjack.Rules.value([ACE, KING, 5]) == (false, 16)
    end

    @testset "hand value — soft totals" begin
        @test Blackjack.Rules.value([ACE, 9])    == (true, 20)
        @test Blackjack.Rules.value([ACE, 6])    == (true, 17)
        @test Blackjack.Rules.value([ACE, ACE])  == (true, 12)
        @test Blackjack.Rules.value([ACE, 2])    == (true, 13)
        # Blackjack
        @test Blackjack.Rules.value([ACE, KING]) == (true, 21)
    end

    @testset "dealer_must_hit" begin
        h17_rules   = Blackjack.Rules.RuleSet(true,  true, true, false, false, false, 4, 1.5)
        s17_rules   = Blackjack.Rules.RuleSet(false, true, true, false, false, false, 4, 1.5)

        # Hard totals below 17 — always hit
        @test  Blackjack.Rules.dealer_must_hit([10, 6], h17_rules)
        @test  Blackjack.Rules.dealer_must_hit([10, 6], s17_rules)

        # Hard 17 — never hit
        @test !Blackjack.Rules.dealer_must_hit([10, 7], h17_rules)
        @test !Blackjack.Rules.dealer_must_hit([10, 7], s17_rules)

        # Soft 17 — hit only under H17 rules
        @test  Blackjack.Rules.dealer_must_hit([ACE, 6], h17_rules)
        @test !Blackjack.Rules.dealer_must_hit([ACE, 6], s17_rules)

        # Soft 18 — never hit
        @test !Blackjack.Rules.dealer_must_hit([ACE, 7], h17_rules)
        @test !Blackjack.Rules.dealer_must_hit([ACE, 7], s17_rules)

        # Hard totals above 17 — never hit
        @test !Blackjack.Rules.dealer_must_hit([10, KING], h17_rules)
        @test !Blackjack.Rules.dealer_must_hit([10, 8],    h17_rules)
    end

    @testset "RuleSet deconstruct contains key fields" begin
        rules = Blackjack.Rules.RuleSet(true, true, true, false, false, true, 3, 1.5)
        s = Blackjack.Rules.deconstruct(rules)
        @test occursin("true",  s)
        @test occursin("false", s)
        @test occursin("1.5",   s)
        @test occursin("3",     s)
    end
end

# ── Shoes ─────────────────────────────────────────────────────────────────────

@testset "Shoes" begin
    @testset "construction" begin
        shoe = Blackjack.Shoes.Shoe(6, 1.5)
        @test length(shoe.cards) == 6 * DECK_SIZE
        @test shoe.index         == 1
        @test shoe.running_count == 0
        # limit = ceil((6 - 1.5) * 52) = ceil(234.0) = 234
        @test shoe.limit         == ceil(Int, (6 - 1.5) * DECK_SIZE)
        # all 52 × 6 = 312 cards present (permuted)
        @test sort(shoe.cards)   == sort(repeat(collect(1:DECK_SIZE), 6))
    end

    @testset "shuffle! resets state" begin
        shoe = Blackjack.Shoes.Shoe(2, 0.5)
        Blackjack.Shoes.deal!(shoe)
        Blackjack.Shoes.deal!(shoe)
        @test shoe.index != 1
        # deal enough cards to ensure the running count is unlikely to be zero
        for _ in 1:10; Blackjack.Shoes.deal!(shoe); end
        Blackjack.Shoes.shuffle!(shoe)
        @test shoe.index         == 1
        @test shoe.running_count == 0

        Blackjack.Shoes.shuffle!(shoe)
        @test shoe.index         == 1
        @test shoe.running_count == 0
        @test sort(shoe.cards)   == sort(repeat(collect(1:DECK_SIZE), 2))
    end

    @testset "deal! advances index and updates running count" begin
        shoe = Blackjack.Shoes.Shoe(1, 0.0)
        card = Blackjack.Shoes.deal!(shoe)
        @test shoe.index == 2
        @test card == shoe.cards[1]
        expected_count = Blackjack.HiLo.value(Blackjack.Rules.rank(card))
        @test shoe.running_count == expected_count
    end

    @testset "deal_value! returns blackjack value not raw card" begin
        shoe = Blackjack.Shoes.Shoe(1, 0.0)
        v = Blackjack.Shoes.deal_value!(shoe)
        expected = Blackjack.Rules.value(Blackjack.Rules.rank(shoe.cards[1]))
        @test v == expected
        @test v in 1:10
    end

    @testset "remaining" begin
        shoe = Blackjack.Shoes.Shoe(1, 0.0)
        @test Blackjack.Shoes.remaining(shoe) == DECK_SIZE
        Blackjack.Shoes.deal!(shoe)
        @test Blackjack.Shoes.remaining(shoe) == DECK_SIZE - 1
    end

    @testset "done" begin
        shoe = Blackjack.Shoes.Shoe(1, 0.0)
        @test !Blackjack.Shoes.done(shoe)
        # deal all cards up to limit
        while !Blackjack.Shoes.done(shoe)
            Blackjack.Shoes.deal!(shoe)
        end
        @test Blackjack.Shoes.done(shoe)
    end

    @testset "true_count" begin
        shoe = Blackjack.Shoes.Shoe(1, 0.0)
        # Before dealing, running count is 0, so true count is 0
        @test Blackjack.Shoes.true_count(shoe) == 0.0
    end

    @testset "running_count_after" begin
        shoe = Blackjack.Shoes.Shoe(1, 0.0)
        # A full balanced deck sums to 0
        @test Blackjack.Shoes.running_count_after(shoe, DECK_SIZE) == 0
        # Consistent with dealing one card manually
        expected = Blackjack.HiLo.value(Blackjack.Rules.rank(shoe.cards[1]))
        @test Blackjack.Shoes.running_count_after(shoe, 1) == expected
    end

    @testset "true_count_after" begin
        shoe = Blackjack.Shoes.Shoe(2, 0.0)
        # At exactly the midpoint of a 2-deck shoe, 1 deck remains, so
        # true_count_after == running_count_after (count ÷ 1 deck).
        rc = Blackjack.Shoes.running_count_after(shoe, DECK_SIZE)
        @test Blackjack.Shoes.true_count_after(shoe, DECK_SIZE) == Float64(rc)
    end

    @testset "deal! running count matches running_count_after" begin
        shoe = Blackjack.Shoes.Shoe(1, 0.0)
        n = 20
        for _ in 1:n
            Blackjack.Shoes.deal!(shoe)
        end
        @test shoe.running_count == Blackjack.Shoes.running_count_after(shoe, n)
    end

    @testset "full shoe running count is zero (balanced deck)" begin
        shoe = Blackjack.Shoes.Shoe(1, 0.0)
        while shoe.index <= length(shoe.cards)
            Blackjack.Shoes.deal!(shoe)
        end
        @test shoe.running_count == 0
    end
end

# ── Strategy ──────────────────────────────────────────────────────────────────

@testset "Strategy" begin
    data_dir = joinpath(@__DIR__, "..", "data")
    h17_ns = Blackjack.Strategy.load_table(joinpath(data_dir, "H17-DAS-NS.json"))
    s17_ls = Blackjack.Strategy.load_table(joinpath(data_dir, "S17-DAS-LS.json"))

    @testset "table_for selects by rules" begin
        h17_ns_rules = Blackjack.Rules.RuleSet(true,  true, true, false, false, false, 4, 1.5)
        s17_ls_rules = Blackjack.Rules.RuleSet(false, true, true, false, false, true,  4, 1.5)

        t = Blackjack.Strategy.table_for(h17_ns_rules)
        @test t["meta"]["dealer_stands_on_soft_17"] == false
        @test t["meta"]["surrender_allowed"]        == false

        t = Blackjack.Strategy.table_for(s17_ls_rules)
        @test t["meta"]["dealer_stands_on_soft_17"] == true
        @test t["meta"]["surrender_allowed"]        == true

        # Works with the RuleSet instance held by the top-level module's Configuration
        t = Blackjack.Strategy.table_for(Blackjack.DEFAULT_CONFIGURATION.RULES)
        @test t["meta"]["dealer_stands_on_soft_17"] == false
        @test t["meta"]["surrender_allowed"]        == false

        # All tables assume double-after-split is allowed
        no_das_rules = Blackjack.Rules.RuleSet(true, true, false, false, false, false, 4, 1.5)
        @test_throws ArgumentError Blackjack.Strategy.table_for(no_das_rules)
    end

    @testset "pairs" begin
        @test Blackjack.Strategy.player_action(h17_ns, [ACE, ACE], 6) == "P"
        @test Blackjack.Strategy.player_action(h17_ns, [8, 8], 10)    == "P"
        @test Blackjack.Strategy.player_action(h17_ns, [10, 10], 6)   == "S"
        @test Blackjack.Strategy.player_action(h17_ns, [5, 5], 6)     == "Dh"
        @test Blackjack.Strategy.player_action(h17_ns, [9, 9], 7)     == "S"
        # Face cards collapse to 10: J,Q is a pair of 10s
        @test Blackjack.Strategy.player_action(h17_ns, [JACK, QUEEN], 6) == "S"
    end

    @testset "soft hands" begin
        @test Blackjack.Strategy.player_action(h17_ns, [ACE, KING], 10) == "S"  # blackjack (soft 21)
        @test Blackjack.Strategy.player_action(h17_ns, [ACE, 7], 9)     == "H"  # soft 18
        @test Blackjack.Strategy.player_action(h17_ns, [ACE, 2], 5)     == "Dh" # soft 13
        # Soft 19 vs 6 differs by dealer soft-17 rule
        @test Blackjack.Strategy.player_action(h17_ns, [ACE, 8], 6) == "Ds"
        @test Blackjack.Strategy.player_action(s17_ls, [ACE, 8], 6) == "S"
        # Multi-card soft hand: A,A,A is soft 13, not a pair
        @test Blackjack.Strategy.player_action(h17_ns, [ACE, ACE, ACE], 5) == "Dh"
    end

    @testset "hard hands" begin
        @test Blackjack.Strategy.player_action(h17_ns, [10, 6], 10)   == "H"
        @test Blackjack.Strategy.player_action(s17_ls, [10, 6], 10)   == "Rh" # surrender allowed
        @test Blackjack.Strategy.player_action(h17_ns, [6, 5], 6)     == "Dh" # hard 11
        @test Blackjack.Strategy.player_action(h17_ns, [6, 5], ACE)   == "Dh" # hard 11 vs A (H17)
        @test Blackjack.Strategy.player_action(s17_ls, [6, 5], ACE)   == "H"  # hard 11 vs A (S17)
        @test Blackjack.Strategy.player_action(h17_ns, [10, 2], 2)    == "H"
        @test Blackjack.Strategy.player_action(h17_ns, [10, 2], 4)    == "S"
        @test Blackjack.Strategy.player_action(h17_ns, [2, 3], 2)     == "H"  # hard 5
        @test Blackjack.Strategy.player_action(h17_ns, [10, 7, 3], ACE) == "S" # hard 20
        # Ace counted as 1 when the soft total would bust: A,K,5 is hard 16
        @test Blackjack.Strategy.player_action(h17_ns, [ACE, KING, 5], 10) == "H"
    end

    @testset "argument errors" begin
        @test_throws ArgumentError Blackjack.Strategy.player_action(h17_ns, [10], 6)        # too few cards
        @test_throws ArgumentError Blackjack.Strategy.player_action(h17_ns, [10, 14], 6)    # bad card
        @test_throws ArgumentError Blackjack.Strategy.player_action(h17_ns, [10, 6], 0)     # bad upcard
        @test_throws ArgumentError Blackjack.Strategy.player_action(h17_ns, [10, 6], 14)    # bad upcard
        @test_throws ArgumentError Blackjack.Strategy.player_action(h17_ns, [10, 9, 5], 6)  # busted
    end
end

# ── Commafy ───────────────────────────────────────────────────────────────────

@testset "Commafy" begin
    @test commafy(0)             == "0"
    @test commafy(1)             == "1"
    @test commafy(999)           == "999"
    @test commafy(1_000)         == "1,000"
    @test commafy(1_234)         == "1,234"
    @test commafy(10_000)        == "10,000"
    @test commafy(100_000)       == "100,000"
    @test commafy(1_000_000)     == "1,000,000"
    @test commafy(1_234_567)     == "1,234,567"
    @test commafy(1_234_567_890) == "1,234,567,890"
    @test commafy(-1)            == "-1"
    @test commafy(-1_000)        == "-1,000"
    @test commafy(-1_234_567)    == "-1,234,567"
end

# ── Blackjack (top-level module) ───────────────────────────────────────────────

@testset "Blackjack module" begin
    @testset "BUST constant" begin
        @test BUST == 22
    end

    @testset "DEFAULT_CONFIGURATION" begin
        cfg = Blackjack.DEFAULT_CONFIGURATION
        @test cfg.DECKS_PER_SHOE == 6
        @test cfg.PENETRATION    == 1.5
        @test cfg.RULES.DEALER_MUST_HIT_SOFT_17  == true
        @test cfg.RULES.DEALER_CHECKS_FOR_BLACKJACK == true
        @test cfg.RULES.DOUBLE_AFTER_SPLIT_ALLOWED  == true
        @test cfg.RULES.RESPLIT_ACES_ALLOWED        == false
        @test cfg.RULES.HIT_SPLIT_ACES_ALLOWED      == false
        @test cfg.RULES.SURRENDER_ALLOWED           == false
        @test cfg.RULES.MAX_SPLIT_HANDS             == 4
        @test cfg.RULES.BLACKJACK_PAYOFF            == 1.5
    end
end

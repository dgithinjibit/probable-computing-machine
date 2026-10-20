; l7-01-moses.metta
; L7: a MOSES-shaped program search, written from scratch in MeTTa.
;
; Grounded in trueagi-io/hyperon-moses's docs/metta-port-highlevel-guide.md,
; which names three tricks that made AS-MOSES competitive:
;   1. reduce candidates to normal form, so syntactic twins become one candidate;
;   2. locally vectorize the search space around an exemplar (a "deme");
;   3. vectorize the fitness: per-data-point components, not one number.
; This file implements trick 1 in full, trick 3 as per-row hits, and trick 2 as a
; deme grown by mutation rules. It is NOT a port of MOSES; it is the shape of one.
; hyperon-moses is AGPL-3.0, so nothing here is copied from it.

; --- The target: a truth table, as FACTS. --------------------------------------
; L6's lesson: `match` only sees stored atoms, so data goes in as facts, never as
; `(= (target 1 1) 1)` rules. Four rows, two inputs, one output: the AND function.
(target 0 0 0)
(target 0 1 0)
(target 1 0 0)
(target 1 1 1)

; --- Candidates are DATA, not executable MeTTa. --------------------------------
; Tags keep the interpreter from reducing the program while we are searching over
; it. The guide gets the same effect with a unicode trick (`and` becomes a bold
; `𝐚𝐧𝐝`); tagged symbols are the boring version, and they also keep `==` from
; unifying two different programs by accident.
(= (eval-c (const-0) $a $b) 0)
(= (eval-c (const-1) $a $b) 1)
(= (eval-c (var-x) $a $b) $a)
(= (eval-c (var-y) $a $b) $b)
(= (eval-c (c-not $p) $a $b)
    (if (== (eval-c $p $a $b) 1) 0 1))
(= (eval-c (c-and $p $q) $a $b)
    (if (== (eval-c $p $a $b) 1)
        (if (== (eval-c $q $a $b) 1) 1 0)
        0))
(= (eval-c (c-or $p $q) $a $b)
    (if (== (eval-c $p $a $b) 1) 1
        (if (== (eval-c $q $a $b) 1) 1 0)))

!(assertEqualToResult (eval-c (c-and (var-x) (var-y)) 1 0) (0))
!(assertEqualToResult (eval-c (c-or (var-x) (var-y)) 1 0) (1))
!(assertEqualToResult (eval-c (c-not (c-and (var-x) (var-y))) 1 1) (0))

; --- Trick 1: normal form. ----------------------------------------------------
; One rule per head, with the tests nested inside it. Two same-head `nf` rules
; would return the same candidate twice (L0's lesson), and `(c-and $p $p)` is
; matched by an idempotence rule and a sorting rule at once, so the branches have
; to be guards. `rank` is a total order over shapes, which is what makes sorting
; legal. `case` is the one construct here that is first-match rather than
; explore-everything, so it is the right tool for "exactly one of these shapes".
(= (rank (const-0)) 0)
(= (rank (const-1)) 1)
(= (rank (var-x)) 2)
(= (rank (var-y)) 3)
(= (rank (c-not $p)) (+ 4 (rank $p)))
(= (rank (c-and $p $q)) (+ 4 (+ (rank $p) (rank $q))))
(= (rank (c-or $p $q)) (+ 5 (+ (rank $p) (rank $q))))

; Leaf rules. Without them `(nf (var-y))` has no rule, and the `let` below binds
; $a to the UNREDUCED atom `(nf (var-y))`, which then poisons every comparison
; downstream and prints an un-reduced `if`. Verified on this runtime: a let whose
; value does not reduce stays as the expression itself.
(= (nf (const-0)) (const-0))
(= (nf (const-1)) (const-1))
(= (nf (var-x)) (var-x))
(= (nf (var-y)) (var-y))

; $a and $b disagree only if one of them is the negation of the other, and either
; argument can be the negation, so the test runs in both orders.
(= (neg-pair $x $y)
    (case $x (((c-not $r) (== $r $y)) ($other False))))

(= (nf (c-and $p $q))
    (let $a (nf $p)
        (let $b (nf $q)
            (if (== $a $b) $a
                (if (neg-pair $a $b) (const-0)
                    (if (neg-pair $b $a) (const-0)
                        (if (>= (rank $a) (rank $b)) (c-and $b $a)
                            (c-and $a $b))))))))
(= (nf (c-or $p $q))
    (let $a (nf $p)
        (let $b (nf $q)
            (if (== $a $b) $a
                (if (neg-pair $a $b) (const-1)
                    (if (neg-pair $b $a) (const-1)
                        (if (>= (rank $a) (rank $b)) (c-or $b $a)
                            (c-or $a $b))))))))
(= (nf (c-not $p))
    (case (nf $p) (((c-not $r) (nf $r)) ($q (c-not $q)))))

!(assertEqualToResult (nf (c-and (var-y) (var-x))) ((c-and (var-x) (var-y))))
!(assertEqualToResult (nf (c-and (var-x) (var-x))) ((var-x)))
!(assertEqualToResult (nf (c-not (c-not (var-y)))) ((var-y)))
!(assertEqualToResult (nf (c-and (var-x) (c-not (var-x)))) ((const-0)))
!(assertEqualToResult (nf (c-and (c-not (var-y)) (var-y))) ((const-0)))
!(assertEqualToResult (nf (c-or (var-x) (c-not (var-x)))) ((const-1)))
!(assertEqualToResult (nf (c-not (c-not (c-not (var-y))))) ((c-not (var-y))))

; Twins. `(c-and (var-y) (var-x))` and `(c-and (var-x) (var-y))` are two programs
; syntactically and one program semantically; after `nf` they are the same atom,
; so the search never scores the same idea twice.
!(assertEqual (nf (c-and (var-y) (var-x)))
              (nf (c-and (var-x) (var-y))))

; This ENF is deliberately INCOMPLETE. `(c-and (var-x) (c-and (var-x) (var-y)))`
; is absorption-reducible to `(c-and (var-x) (var-y))` and stays as it is, because
; absorption needs a rule that looks two levels down. Exercise 37 asks you to add
; it without giving `nf` a second head.
!(assertEqualToResult (nf (c-and (c-and (var-x) (var-y)) (var-x)))
    ((c-and (var-x) (c-and (var-x) (var-y)))))

; --- Size, hits, and the score. -----------------------------------------------
(= (size (const-0)) 1)
(= (size (const-1)) 1)
(= (size (var-x)) 1)
(= (size (var-y)) 1)
(= (size (c-not $p)) (+ 1 (size $p)))
(= (size (c-and $p $q)) (+ 1 (+ (size $p) (size $q))))
(= (size (c-or $p $q)) (+ 1 (+ (size $p) (size $q))))

; One `1` per row the candidate gets right, and `Empty` drops the rows it misses.
; That is trick 3 at this scale: the fitness is a vector of per-datump results
; which happens to be summed here. Keep the sum and the count apart and you have
; the Pareto-style components MOSES actually uses.
(= (hit $p)
    (match &self (target $a $b $o)
        (if (== (eval-c $p $a $b) $o) 1 Empty)))
(= (hits $p) (let $t (collapse (hit $p)) (foldl-atom $t 0 $acc $e (+ $acc $e))))

!(assertEqualToResult (hits (var-x)) (3))
!(assertEqualToResult (hits (c-and (var-x) (var-y))) (4))
!(assertEqualToResult (hits (const-0)) (3))
!(assertEqualToResult (hits (c-or (var-x) (var-y))) (2))
!(assertEqualToResult (hits (c-not (c-and (var-x) (var-y)))) (0))

; --- The population. ----------------------------------------------------------
; Facts again: the population is a space of atoms you can query, not a list you
; have to thread through a function. Three of these seven entries are the same
; program after `nf`.
(cand (var-x))
(cand (var-y))
(cand (const-0))
(cand (c-and (var-x) (var-y)))
(cand (c-and (var-y) (var-x)))
(cand (c-not (c-not (c-and (var-x) (var-y)))))
(cand (c-or (var-x) (var-y)))

(= (scored)
    (match &self (cand $p) (, (nf $p) (hits $p) (size (nf $p)))))
!(collapse (scored))

; --- The penalty, and the trap inside it. -------------------------------------
; MOSES does not rank candidates by accuracy alone; a complexity penalty is
; subtracted so a shorter program wins ties. Here the penalty is a named constant
; so you can watch what it does to the ranking.
(= (penalty) 0)
(= (score $p) (- (hits $p) (* (penalty) (size $p))))

; With penalty 0 the correct AND wins outright.
!(assertEqualToResult (score (c-and (var-x) (var-y))) (4))
; With penalty 1 it does not: `(var-x)` is wrong on one row and short, so it
; outscores a program that is right on all four. This is the honest reason MOSES
; spends pages on its penalty constant and its plateau rules.
(= (penalty-1) 1)
(= (score1 $p) (- (hits $p) (* (penalty-1) (size $p))))
!(assertEqualToResult (score1 (var-x)) (2))
!(assertEqualToResult (score1 (c-and (var-x) (var-y))) (1))
!(assertEqualToResult (score1 (const-0)) (2))
; Note the tie: `(const-0)` is wrong on a row and right on three, one node long,
; so it scores the same as `(var-x)` and BOTH beat the correct answer. Under
; penalty 1 the search would return a constant. That is the plateau MOSES's
; complexity rules exist to break, reproduced in three lines.

; --- Trick 2, the local version: grow a deme around one exemplar. -------------
; The heads here DO overlap on purpose. `(grow $p)` matches every rule, so a
; `(c-and ...)` exemplar yields neighbours from the three structural rules AND the
; two extension rules. That is enumeration, the same deliberate multiplication
; [L3] uses to list candidates -- the opposite of the accidental kind L0 warns
; about. The difference: here you want all five results.
(= (grow (c-and $p $q)) (c-not (c-and $p $q)))
(= (grow (c-and $p $q)) (c-and (c-not $p) $q))
(= (grow (c-and $p $q)) (c-or $p $q))
(= (grow $p) (c-and $p (var-x)))
(= (grow $p) (c-and $p (var-y)))

; Order is not guaranteed across results, so never assert the deme as a list.
; Assert what is order-free: how many neighbours, and the total size.
(= (deme-count $p)
    (let $t (collapse (grow $p)) (foldl-atom $t 0 $acc $e (+ $acc 1))))
(= (deme-size $p)
    (let $t (collapse (grow $p)) (foldl-atom $t 0 $acc $e (+ $acc (size $e)))))
!(assertEqualToResult (deme-count (c-and (var-x) (var-y))) (5))
!(assertEqualToResult (deme-size (c-and (var-x) (var-y))) (21))
!(assertEqualToResult (deme-count (var-x)) (2))
!(collapse (grow (c-and (var-x) (var-y))))

; The best neighbour's fitness, computed order-free with a max fold.
(= (deme-best $p)
    (let $t (collapse (grow $p))
        (foldl-atom $t 0 $acc $e (if (>= (hits $e) $acc) (hits $e) $acc))))
!(assertEqualToResult (deme-best (c-and (var-x) (var-y))) (4))
!(assertEqualToResult (deme-best (c-or (var-x) (var-y))) (3))

; Selection: keep only neighbours above a threshold, and store them normalized.
; `let` over a multi-result query branches once per result, which is what makes
; this a filter rather than a loop.
(= (good $p $threshold)
    (let $q (grow $p)
        (if (>= (hits $q) $threshold) (nf $q) Empty)))
(= (good-count $p $threshold)
    (let $t (collapse (good $p $threshold))
        (foldl-atom $t 0 $acc $e (+ $acc 1))))
!(collapse (good (c-and (var-x) (var-y)) 4))
!(assertEqualToResult (good-count (c-and (var-x) (var-y)) 4) (2))
!(assertEqualToResult (good-count (c-and (var-x) (var-y)) 0) (5))
!(assertEqualToResult (good-count (c-and (var-x) (var-y)) 5) (0))
; Both survivors normalize to a three-node program, because absorption is not in
; this ENF. Print above; the exact atoms are order-dependent, so they stay a print.
!(assertEqualToResult (size (nf (c-and (c-and (var-x) (var-y)) (var-x)))) (5))

; --- Assertions about the search itself. --------------------------------------
!(assertEqualToResult (hits (nf (c-and (var-y) (var-x)))) (4))
!(assertEqualToResult (size (nf (c-not (c-not (c-and (var-x) (var-y)))))) (3))
; The two surviving population twins are one program, so a deduplicated
; population has five distinct shapes, not seven. Check it by eye above, then
; write distinct-count as exercise 38.

; The three tricks, in the order the guide lists them, in one file: normal form
; dedups the population (the scored table above prints the AND three times because
; the population contains it three times), the deme is a local neighbourhood with
; an order-free summary, and the fitness is per-row. The ranking trap at penalty
; 1 is the reason none of those three is a detail.

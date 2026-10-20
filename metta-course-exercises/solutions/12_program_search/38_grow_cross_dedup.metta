; Exercise 38 — Grow, cross, dedup  [SOLUTION]
; Book: [L7 — Program search](../../../metta-book/src/ch13-l7-moses.md)
;
; Trick 2 at full strength: a deme is a LOCAL neighbourhood, crossover recombines
; two of them, and deduplication is what stops the population filling with renamed
; twins. Everything is asserted order-free, because `collapse`d result order is not
; guaranteed on this runtime.

; --- Target, language, evaluation, hits: the L7 listing's machinery. ----------
(target 0 0 0)
(target 0 1 0)
(target 1 0 0)
(target 1 1 1)

(= (eval-c (const-0) $a $b) 0)
(= (eval-c (const-1) $a $b) 1)
(= (eval-c (var-x) $a $b) $a)
(= (eval-c (var-y) $a $b) $b)
(= (eval-c (c-not $p) $a $b) (if (== (eval-c $p $a $b) 1) 0 1))
(= (eval-c (c-and $p $q) $a $b)
    (if (== (eval-c $p $a $b) 1) (if (== (eval-c $q $a $b) 1) 1 0) 0))
(= (eval-c (c-or $p $q) $a $b)
    (if (== (eval-c $p $a $b) 1) 1 (if (== (eval-c $q $a $b) 1) 1 0)))
(= (hit $p)
    (match &self (target $a $b $o)
        (if (== (eval-c $p $a $b) $o) 1 Empty)))
(= (hits $p) (let $t (collapse (hit $p)) (foldl-atom $t 0 $acc $e (+ $acc $e))))

(= (rank (const-0)) 0)
(= (rank (const-1)) 1)
(= (rank (var-x)) 2)
(= (rank (var-y)) 3)
(= (rank (c-not $p)) (+ 4 (rank $p)))
(= (rank (c-and $p $q)) (+ 4 (+ (rank $p) (rank $q))))
(= (rank (c-or $p $q)) (+ 5 (+ (rank $p) (rank $q))))
(= (nf (const-0)) (const-0))
(= (nf (const-1)) (const-1))
(= (nf (var-x)) (var-x))
(= (nf (var-y)) (var-y))
(= (neg-pair $x $y) (case $x (((c-not $r) (== $r $y)) ($other False))))
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
                    (if (neg-pair $b $a) (const-1) (c-or $a $b)))))))
(= (nf (c-not $p)) (case (nf $p) (((c-not $r) (nf $r)) ($q (c-not $q)))))

(= (size (const-0)) 1)
(= (size (const-1)) 1)
(= (size (var-x)) 1)
(= (size (var-y)) 1)
(= (size (c-not $p)) (+ 1 (size $p)))
(= (size (c-and $p $q)) (+ 1 (+ (size $p) (size $q))))
(= (size (c-or $p $q)) (+ 1 (+ (size $p) (size $q))))

; --- (1) Mutation: the deme. --------------------------------------------------
; Heads overlap on purpose -- `(grow $p)` catches everything, so a `c-and` exemplar
; gets structural neighbours AND extensions. Enumeration is the one place where
; same-head overlap is what you want.
(= (grow (c-and $p $q)) (c-not (c-and $p $q)))
(= (grow (c-and $p $q)) (c-and (c-not $p) $q))
(= (grow (c-and $p $q)) (c-or $p $q))
(= (grow $p) (c-and $p (var-x)))
(= (grow $p) (c-and $p (var-y)))
(= (grow-count $p)
    (let $t (collapse (grow $p)) (foldl-atom $t 0 $acc $e (+ $acc 1))))
(= (grow-best $p)
    (let $t (collapse (grow $p))
        (foldl-atom $t 0 $acc $e (if (>= (hits $e) $acc) (hits $e) $acc))))

!(assertEqualToResult (grow-count (var-x)) (2))
!(assertEqualToResult (grow-count (c-and (var-x) (var-y))) (5))
!(assertEqualToResult (grow-count (c-or (var-x) (var-y))) (2))

; --- (2) Crossover: swap a subtree between two parents. -----------------------
; `subs` enumerates every subterm, including the whole program -- that is what
; makes "copy a whole parent into itself" a legal (and useless) child, exactly as
; in a real GA. `replace` has ONE head and branches with `case`, and it replaces
; every occurrence of the chosen subterm.
(= (subs $p) $p)
(= (subs (c-not $p)) (subs $p))
(= (subs (c-and $p $q)) (subs $p))
(= (subs (c-and $p $q)) (subs $q))
(= (subs (c-or $p $q)) (subs $p))
(= (subs (c-or $p $q)) (subs $q))
(= (subs-count $p)
    (let $t (collapse (subs $p)) (foldl-atom $t 0 $acc $e (+ $acc 1))))

(= (replace $p $old $new)
    (if (== $p $old) $new
        (case $p
          (((c-not $r) (c-not (replace $r $old $new)))
           ((c-and $a $b) (c-and (replace $a $old $new) (replace $b $old $new)))
           ((c-or $a $b) (c-or (replace $a $old $new) (replace $b $old $new)))
           ($o $p)))))

(= (cross $a $b)
    (let $s (subs $a)
        (let $t (subs $b)
            (nf (replace $a $s $t)))))
(= (cross-count $a $b)
    (let $t (collapse (cross $a $b)) (foldl-atom $t 0 $acc $e (+ $acc 1))))

!(assertEqualToResult (subs-count (var-x)) (1))
!(assertEqualToResult (subs-count (c-and (var-x) (var-y))) (3))
!(assertEqualToResult (subs-count (c-and (c-not (var-x)) (var-y))) (4))
!(assertEqualToResult (cross-count (c-and (var-x) (var-y)) (c-or (var-x) (var-y))) (9))
!(assertEqualToResult (replace (c-and (var-x) (var-y)) (var-x) (var-y)) ((c-and (var-y) (var-y))))
!(assertEqualToResult (nf (replace (c-and (var-x) (var-y)) (var-x) (var-y))) ((var-y)))

; `cross` produces children, not necessarily distinct children -- the count above
; counts before dedup, which is why (3) exists.
(= (cross-best $a $b)
    (let $t (collapse (cross $a $b))
        (foldl-atom $t 0 $acc $e (if (>= (hits $e) $acc) (hits $e) $acc))))
!(assertEqualToResult (cross-best (c-and (var-x) (var-y)) (c-or (var-x) (var-y))) (4))

; --- (3) Dedup: a named space plus a guard. -----------------------------------
!(bind! &seen (new-space))
; The guard MUST test the atom it is storing. A first draft of `seen-count` matched
; (s $q) -- any $q -- which meant "have I stored anything at all", and the whole
; population deduped into one survivor. A filter that does not filter is silent here;
; the count is how you catch it.
(= (seen-count $p)
    (let $t (collapse (match &seen (s $p) 1)) (foldl-atom $t 0 $acc $e (+ $acc $e))))
(= (note! $p) (if (== (seen-count $p) 0) (add-atom &seen (s $p)) Empty))
(= (stored)
    (let $t (collapse (match &seen (s $q) 1)) (foldl-atom $t 0 $acc $e (+ $acc $e))))

(cand (var-x))
(cand (var-y))
(cand (const-0))
(cand (c-and (var-x) (var-y)))
(cand (c-and (var-y) (var-x)))
(cand (c-not (c-not (c-and (var-x) (var-y)))))
(cand (c-or (var-x) (var-y)))

!(collapse (match &self (cand $p) (note! (nf $p))))
!(assertEqualToResult (stored) (5))
!(assertEqualToResult (seen-count (c-and (var-x) (var-y))) (1))
; ...but NOT with its mirror: `&seen` holds normalized atoms, so an un-normalized
; query finds nothing. Query the space in the same canonical form you wrote into it.
!(assertEqualToResult (seen-count (c-and (var-y) (var-x))) (0))
!(assertEqualToResult (seen-count (c-not (var-x))) (0))

; Seven candidates, five programs. The AND, its mirror and its double negation are
; one inhabitant of `&seen` -- which is tricks 1 and 2 meeting: normal form is what
; makes a deme-sized population mean something.

; --- (4) One generation of local search, and its limit. -----------------------
; From the near-miss `var-x`, one deme step finds the truth:
!(assertEqualToResult (hits (var-x)) (3))
!(assertEqualToResult (grow-best (var-x)) (4))
; From `c-or (var-x) (var-y)`, one deme step does NOT: the extensions of an OR are
; ANDs with a leaf, and both simplify back to a single variable. The neighbourhood
; around a wrong shape cannot see the right shape -- the guide's "wisdom is not
; transferable between demes", in four atoms.
!(assertEqualToResult (hits (c-or (var-x) (var-y))) (2))
!(assertEqualToResult (grow-best (c-or (var-x) (var-y))) (3))
; Therefore a search that only grows demes around elites will stall here. The two
; repairs, in order of how much they cost you: more mutation operators (add a rule
; that swaps a leaf for a constant), restarts in a different deme, or crossover
; between demes -- which is what (2) is for.
!(assertEqualToResult (cross-best (c-or (var-x) (var-y)) (var-x)) (3))

; --- (5) Order-free habits, asserted. ----------------------------------------
; Never assert a multi-result query as a list. Count it, sum it, or fold a max over
; it. These three lines are the same facts as above, phrased so they cannot flake:
!(assertEqualToResult (let $t (collapse (grow (c-and (var-x) (var-y))))
                        (foldl-atom $t 0 $acc $e (+ $acc (size $e)))) (21))
!(assertEqualToResult (let $t (collapse (grow (c-and (var-x) (var-y))))
                        (foldl-atom $t 0 $acc $e (+ $acc (hits $e)))) (12))
!(assertEqualToResult (let $t (collapse (subs (c-and (c-not (var-x)) (var-y))))
                        (foldl-atom $t 0 $acc $e (+ $acc (size $e)))) (8))

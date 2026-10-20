; Exercise 37 — Canonical shapes  [SOLUTION]
; Book: [L7 — Program search](../../../metta-book/src/ch13-l7-moses.md)
;
; Trick 1 done properly. The listing's `nf` sorts and collapses double negation;
; this exercise adds ABSORPTION, keeps one rule per head, and then proves the two
; properties that make a normal form worth paying for:
;   (a) idempotence   -- normalizing twice is normalizing once;
;   (b) behaviour preservation -- hits before == hits after.
; Without (b) you have not built a normal form, you have built a filter.

; --- The target, as facts. -----------------------------------------------------
(target 0 0 0)
(target 0 1 0)
(target 1 0 0)
(target 1 1 1)

; --- The candidate language, as data. -----------------------------------------
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

; --- Booleans by hand. --------------------------------------------------------
; There is no `bool-and`, `bool-or` or `bool-not` on 0.2.10 (verified: the calls are
; returned unreduced), and `if` wants a real Bool, so two-of-these-two helpers are
; the cheapest honest thing.
(= (or-bool $x $y) (if $x True (if $y True False)))
(= (not-bool $x) (if $x False True))
!(assertEqualToResult (or-bool True False) (True))
!(assertEqualToResult (or-bool False False) (False))
!(assertEqualToResult (not-bool True) (False))

; --- Rank, for the sorting half of the normal form. ---------------------------
(= (rank (const-0)) 0)
(= (rank (const-1)) 1)
(= (rank (var-x)) 2)
(= (rank (var-y)) 3)
(= (rank (c-not $p)) (+ 4 (rank $p)))
(= (rank (c-and $p $q)) (+ 4 (+ (rank $p) (rank $q))))
(= (rank (c-or $p $q)) (+ 5 (+ (rank $p) (rank $q))))

(= (neg-pair $x $y) (case $x (((c-not $r) (== $r $y)) ($other False))))
(= (sort-and $a $b) (if (>= (rank $a) (rank $b)) (c-and $b $a) (c-and $a $b)))

; --- Absorption, in either argument position. ---------------------------------
; A ^ (A ^ B) = A, and A ^ (B ^ A) = A, and the same with the compound on the
; right. Each helper has ONE head and uses `case` to branch on shape, because two
; rules with the head `absorb-and` would return the candidate twice -- the L0 trap,
; and the reason `case` exists in this chapter at all.
(= (absorb-and-b $a $b)
    (case $b
      (((c-and $r $s) (if (or-bool (== $r $a) (== $s $a)) $b (sort-and $a $b)))
       ($o (sort-and $a $b)))))
(= (absorb-and $a $b)
    (case $a
      (((c-and $r $s) (if (or-bool (== $r $b) (== $s $b)) $a (absorb-and-b $a $b)))
       ($o (absorb-and-b $a $b)))))

; --- nf: leaf rules, one rule per operator head. ------------------------------
(= (nf (const-0)) (const-0))
(= (nf (const-1)) (const-1))
(= (nf (var-x)) (var-x))
(= (nf (var-y)) (var-y))
(= (nf (c-and $p $q))
    (let $a (nf $p)
        (let $b (nf $q)
            (if (== $a $b) $a
                (if (neg-pair $a $b) (const-0)
                    (if (neg-pair $b $a) (const-0)
                        (absorb-and $a $b)))))))
(= (nf (c-or $p $q))
    (let $a (nf $p)
        (let $b (nf $q)
            (if (== $a $b) $a
                (if (neg-pair $a $b) (const-1)
                    (if (neg-pair $b $a) (const-1)
                        (c-or $a $b)))))))
(= (nf (c-not $p)) (case (nf $p) (((c-not $r) (nf $r)) ($q (c-not $q)))))

; --- (1) The shapes the listing left unreduced now reduce. --------------------
!(assertEqualToResult (nf (c-and (var-x) (c-and (var-x) (var-y)))) ((c-and (var-x) (var-y))))
!(assertEqualToResult (nf (c-and (c-and (var-y) (var-x)) (var-y))) ((c-and (var-x) (var-y))))
!(assertEqualToResult (nf (c-and (c-not (c-not (var-x))) (var-x))) ((var-x)))
!(assertEqualToResult (nf (c-and (c-and (var-x) (var-y)) (c-and (var-x) (var-y)))) ((c-and (var-x) (var-y))))

; --- (2) What this ENF still cannot do, asserted rather than promised. --------
; No distribution, no De Morgan, no factoring, so this stays a mess:
!(assertEqualToResult (nf (c-and (c-or (var-x) (var-y)) (c-not (var-x))))
    ((c-and (c-not (var-x)) (c-or (var-x) (var-y)))))
; Adding distribution means a rule that rewrites a node into a deeper tree, which
; can loop with the sorting rule. That is why MOSES's ENF is a fixed rule list and
; why "how complete is your normal form" is a design question, not a checkbox.

; --- (3) Idempotence: normalizing twice is normalizing once. ------------------
(= (idem? $p) (if (== (nf (nf $p)) (nf $p)) True False))
!(assertEqualToResult (idem? (c-and (var-x) (c-and (var-x) (var-y)))) (True))
!(assertEqualToResult (idem? (c-and (c-and (var-y) (var-x)) (var-y))) (True))
!(assertEqualToResult (idem? (c-not (c-not (c-not (var-x))))) (True))
!(assertEqualToResult (idem? (c-and (c-or (var-x) (var-y)) (c-not (var-x)))) (True))

; --- (4) Behaviour preservation: the whole point. -----------------------------
(= (safe? $p) (if (== (hits $p) (hits (nf $p))) True False))
!(assertEqualToResult (safe? (c-and (var-x) (c-and (var-x) (var-y)))) (True))
!(assertEqualToResult (safe? (c-and (c-not (c-not (var-x))) (var-x))) (True))
!(assertEqualToResult (safe? (c-not (c-not (c-and (var-x) (var-y))))) (True))
!(assertEqualToResult (safe? (c-and (c-not (var-x)) (var-x))) (True))
!(assertEqualToResult (safe? (c-and (c-or (var-x) (var-y)) (c-not (var-x)))) (True))
; The contradiction case is the one to say out loud: `(c-and (c-not (var-x))
; (var-x))` is a program that is always 0, and its normal form is the constant
; `const-0`. They are different programs with the same truth table, so `hits`
; agrees -- and that is exactly the equivalence `nf` is supposed to buy you.
!(assertEqualToResult (hits (c-and (c-not (var-x)) (var-x))) (3))
!(assertEqualToResult (hits (nf (c-and (c-not (var-x)) (var-x)))) (3))

; --- (5) Normalization shrinks, which is the payoff. --------------------------
(= (size (const-0)) 1)
(= (size (const-1)) 1)
(= (size (var-x)) 1)
(= (size (var-y)) 1)
(= (size (c-not $p)) (+ 1 (size $p)))
(= (size (c-and $p $q)) (+ 1 (+ (size $p) (size $q))))
(= (size (c-or $p $q)) (+ 1 (+ (size $p) (size $q))))
!(assertEqualToResult (size (nf (c-and (var-x) (c-and (var-x) (var-y))))) (3))
!(assertEqualToResult (size (nf (c-not (c-not (c-not (var-x)))))) (2))
!(assertEqualToResult (size (c-and (var-x) (c-and (var-x) (var-y)))) (5))
!(assertEqualToResult (if (< (size (nf (c-and (var-x) (c-and (var-x) (var-y)))))
                             (size (c-and (var-x) (c-and (var-x) (var-y))))) True False) (True))

; --- (6) The trap this file walked into on the way. ---------------------------
; A first attempt at absorption was a second rule with the head `(nf (c-and $p $q))`.
; It compiled, and every `c-and` candidate came back twice. Same-head rules do not
; specialize each other here; they enumerate. If a query that should be one result
; comes back as two, count the heads before you read the bodies --
;   !(collapse (nf (c-and (var-x) (var-y))))     ; one tuple, two atoms = bug
; and the reason `case` is safe is that it is first-match:
!(assertEqualToResult (nf (c-and (var-x) (var-y))) ((c-and (var-x) (var-y))))
!(assertEqualToResult (collapse (nf (c-and (var-x) (var-y)))) (((c-and (var-x) (var-y)))))
!(assertEqualToResult (collapse (nf (c-not (c-not (var-x))))) (((var-x))))
; Read those last two lines against the two above them. `collapse` returns ONE

; Exercise 36 — Fitness is a vector, not a number
; Book: [L7 — Program search](../../../metta-book/src/ch13-l7-moses.md)
;
; The target is MAJORITY-OF-THREE: output 1 when at least two of x, y, z are 1.
; Requirements:
;   1. the eight target rows as FACTS (t $x $y $z $o), in the order below
;   2. `eval-c` for three inputs (the two-input version is in the listing; add
;      (var-z) and thread the third argument through not/and/or)
;   3. (bad $p)   -- for every row the candidate gets WRONG, emit the row itself
;                    as (, $x $y $z), and nothing for the rows it gets right
;   4. (bad-count $p) -- order-free, via collapse + a let-bound foldl-atom
;   5. (dominates $a $b) -- True when $a has no more errors AND is strictly smaller
;   6. (better $a $b) -- fewer errors wins outright; size breaks the tie
;
; Then assert, with the numbers you computed on paper first:
;   bad-count of (var-x), (const-1), (const-0), (c-and (var-x) (var-y))
;   and prove that (c-and (var-x) (var-y)) and (c-and (var-x) (var-z)) are TIED on
;   the count but wrong on different rows -- four eval-c calls, not a printed table,
;   because collapse order is not guaranteed.
;
; Finally write the three-node-terms program (two ANDs under an OR) and the full
; majority, and answer in a comment: which of {var-x, the two-term OR, majority}
; dominates which, and what does that say about Pareto selection alone?
;
; Constraints: <, <=, >=, == exist; !=, bool-and, bool-or, bool-not, member do not.

(t 0 0 0 0)
(t 0 0 1 0)
(t 0 1 0 0)
(t 0 1 1 1)
(t 1 0 0 0)
(t 1 0 1 1)
(t 1 1 0 1)
(t 1 1 1 1)

(= (eval-c (const-0) $x $y $z) 0)
(= (eval-c (const-1) $x $y $z) 1)
(= (eval-c (var-x) $x $y $z) $x)
(= (eval-c (var-y) $x $y $z) $y)
(= (eval-c (var-z) $x $y $z) $z)
; Your three-input not/and/or go here:

; Your bad / bad-count / size / dominates / better go here:

;!(assertEqualToResult (bad-count (var-x)) ())
;!(assertEqualToResult (bad-count (const-1)) ())
;!(assertEqualToResult (bad-count (c-and (var-x) (var-y))) ())
;!(assertEqualToResult (bad-count (c-and (var-x) (var-z))) ())

; Exercise 37 — Canonical shapes
; Book: [L7 — Program search](../../../metta-book/src/ch13-l7-moses.md)
;
; The listing's `nf` sorts `c-and` children and collapses double negation. Extend
; it to ABSORPTION -- A ^ (A ^ B) = A, in either argument position -- and then prove
; the two properties that make a normal form worth the rules.
;
; Requirements:
;   1. (or-bool $x $y) and (not-bool $x) out of `if`, because bool-or/bool-not do
;      not exist on this runtime
;   2. `rank` and the leaf rules for nf -- all four leaves, or every `let` in the
;      recursion binds an UNREDUCED `(nf (var-y))` atom and the whole thing silently
;      stops comparing
;   3. (neg-pair $x $y) via `case`, True when either argument is the negation of the
;      other
;   4. (sort-and $a $b), (absorb-and $a $b), (absorb-and-b $a $b) -- ONE head each.
;      You may NOT add a second rule whose head is (nf (c-and $p $q)); the reason is
;      requirement 6
;   5. nf for c-and, c-or, c-not
;   6. idempotence: (idem? $p) is True when (== (nf (nf $p)) (nf $p)); assert it for
;      four messy programs
;   7. behaviour preservation: (safe? $p) is True when (hits $p) == (hits (nf $p));
;      assert it for the same four, and for the contradiction (c-and (c-not (var-x))
;      (var-x)) -- whose normal form is a different program with the same truth table
;   8. shrink: assert the size before and after for (c-and (var-x) (c-and (var-x)
;      (var-y))), and assert that a program needing DISTRIBUTION does not shrink --
;      (c-and (c-or (var-x) (var-y)) (c-not (var-x))) stays a three-plus-two mess.
;      Say in one sentence why you did not add De Morgan.
;
; Prediction table before you run (write the answer, then run):
;   !(nf (c-and (var-x) (c-and (var-x) (var-y))))            ->
;   !(nf (c-and (c-and (var-y) (var-x)) (var-y)))            ->
;   !(nf (c-and (c-not (c-not (var-x))) (var-x)))            ->
;   !(nf (c-and (c-and (var-x) (var-y)) (c-and (var-x) (var-y)))) ->
;   !(hits (c-and (c-not (var-x)) (var-x)))                  ->
;   !(nf (c-and (c-or (var-x) (var-y)) (c-not (var-x))))        ->

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

; Your rules go here:

;!(assertEqualToResult (nf (c-and (var-x) (c-and (var-x) (var-y)))) ())
;!(assertEqualToResult (idem? (c-not (c-not (c-not (var-x))))) ())
;!(assertEqualToResult (safe? (c-and (c-not (var-x)) (var-x))) ())

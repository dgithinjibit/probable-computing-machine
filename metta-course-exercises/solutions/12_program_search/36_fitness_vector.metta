; Exercise 36 — Fitness is a vector, not a number  [SOLUTION]
; Book: [L7 — Program search](../../../metta-book/src/ch13-l7-moses.md)
;
; Trick 3 of the port guide: MOSES keeps the per-data-point components of fitness
; and compares programs on the whole vector (plus size), because a single score
; hides which rows a program gets wrong -- and two programs with the same score can
; be wrong in completely different places.

; --- The target: majority-of-three. --------------------------------------------
(t 0 0 0 0)
(t 0 0 1 0)
(t 0 1 0 0)
(t 0 1 1 1)
(t 1 0 0 0)
(t 1 0 1 1)
(t 1 1 0 1)
(t 1 1 1 1)

; --- Three inputs instead of two. ---------------------------------------------
(= (eval-c (const-0) $x $y $z) 0)
(= (eval-c (const-1) $x $y $z) 1)
(= (eval-c (var-x) $x $y $z) $x)
(= (eval-c (var-y) $x $y $z) $y)
(= (eval-c (var-z) $x $y $z) $z)
(= (eval-c (c-not $p) $x $y $z)
    (if (== (eval-c $p $x $y $z) 1) 0 1))
(= (eval-c (c-and $p $q) $x $y $z)
    (if (== (eval-c $p $x $y $z) 1)
        (if (== (eval-c $q $x $y $z) 1) 1 0)
        0))
(= (eval-c (c-or $p $q) $x $y $z)
    (if (== (eval-c $p $x $y $z) 1) 1
        (if (== (eval-c $q $x $y $z) 1) 1 0)))

!(assertEqualToResult (eval-c (c-and (var-x) (var-y)) 1 1 0) (1))
!(assertEqualToResult (eval-c (c-or (var-x) (var-y)) 0 0 1) (0))

; --- The vector, as failures. --------------------------------------------------
; Emit the ROW, not a 1, for every row the candidate gets wrong. Then the fitness
; component you can assert order-free is the count, and the rows themselves are a
; set you can name one at a time.
(= (bad $p)
    (match &self (t $x $y $z $o)
        (if (== (eval-c $p $x $y $z) $o) Empty (, $x $y $z))))
(= (bad-count $p)
    (let $t (collapse (bad $p)) (foldl-atom $t 0 $acc $e (+ $acc 1))))

!(assertEqualToResult (bad-count (var-x)) (2))
!(assertEqualToResult (bad-count (const-1)) (4))
!(assertEqualToResult (bad-count (const-0)) (4))
!(assertEqualToResult (bad-count (c-and (var-x) (var-y))) (2))
!(assertEqualToResult (bad-count (c-and (var-x) (var-z))) (2))

; The point of the whole exercise: these two are tied on the scalar and disagree
; on the vector. Read it as four calls, not as a printed table, because the order
; of `collapse`d results is not guaranteed.
!(assertEqualToResult (eval-c (c-and (var-x) (var-y)) 1 0 1) (0))
!(assertEqualToResult (eval-c (c-and (var-x) (var-z)) 1 0 1) (1))
!(assertEqualToResult (eval-c (c-and (var-x) (var-y)) 1 1 0) (1))
!(assertEqualToResult (eval-c (c-and (var-x) (var-z)) 1 1 0) (0))
!(assertEqualToResult (eval-c (c-and (var-x) (var-y)) 0 1 1) (0))
!(assertEqualToResult (eval-c (c-and (var-x) (var-z)) 0 1 1) (0))

; --- Size, and the two-objective comparison. ----------------------------------
(= (size (const-0)) 1)
(= (size (const-1)) 1)
(= (size (var-x)) 1)
(= (size (var-y)) 1)
(= (size (var-z)) 1)
(= (size (c-not $p)) (+ 1 (size $p)))
(= (size (c-and $p $q)) (+ 1 (+ (size $p) (size $q))))
(= (size (c-or $p $q)) (+ 1 (+ (size $p) (size $q))))

!(assertEqualToResult (size (c-or (c-and (var-x) (var-y)) (c-and (var-x) (var-z)))) (7))

; $a dominates $b when it is no worse on errors AND strictly smaller. This is the
; relation MOSES's plateau handling is built on, in three nested ifs.
(= (dominates $a $b)
    (if (<= (bad-count $a) (bad-count $b))
        (if (< (size $a) (size $b)) True False)
        False))

!(assertEqualToResult (dominates (var-x) (c-and (var-x) (var-y))) (True))
!(assertEqualToResult (dominates (c-and (var-x) (var-y)) (var-x)) (False))
!(assertEqualToResult (dominates (const-1) (const-0)) (False))

; --- The front, by hand. ------------------------------------------------------
; Two-node-error `var-x` (size 1) versus seven-node `OR(AND(x,y), AND(x,z))`,
; which is wrong on exactly one row:
(= (two-term) (c-or (c-and (var-x) (var-y)) (c-and (var-x) (var-z))))
!(assertEqualToResult (bad-count (two-term)) (1))
!(assertEqualToResult (dominates (var-x) (two-term)) (False))
!(assertEqualToResult (dominates (two-term) (var-x)) (False))
; Neither dominates the other: the small one errs more often but is cheaper, the
; big one errs less often but is larger. Both stay on the front. Now add the
; truth:
(= (maj) (c-or (c-and (var-x) (var-y)) (c-or (c-and (var-x) (var-z)) (c-and (var-y) (var-z)))))
!(assertEqualToResult (bad-count (maj)) (0))
!(assertEqualToResult (size (maj)) (11))
!(assertEqualToResult (dominates (maj) (two-term)) (False))
!(assertEqualToResult (dominates (maj) (var-x)) (False))
; Read those last two together. The 11-node truth is dominated by nothing and
; dominates nothing, because it is the largest thing on the board. Under pure
; Pareto selection the lie at size 1, the near-miss at size 7 and the correct
; program at size 11 sit on the same front and get sampled with equal honour.
; That is not a bug in the definition -- it is why a search needs an error
; threshold or a weighted score BEFORE it needs a cleverer comparator. Exercise 37
; makes shapes canonical so the front is smaller; 38 grows it locally instead of
; globally; neither fixes what this paragraph shows.

; Which is why the comparator you actually use has an error term first. Strictly
; fewer errors wins regardless of size; size breaks ties.
(= (better $a $b)
    (if (< (bad-count $a) (bad-count $b)) True
        (if (== (bad-count $a) (bad-count $b)) (< (size $a) (size $b)) False)))
!(assertEqualToResult (better (maj) (var-x)) (True))
!(assertEqualToResult (better (var-x) (c-and (var-x) (var-y))) (True))
!(assertEqualToResult (better (c-and (var-x) (var-y)) (c-and (var-x) (var-z))) (False))
; That last one is the tie the scalar cannot see: both are two errors and three
; nodes, wrong on different rows, and `better` calls them equal. To pick between
; them you need the vector, not the comparator -- which is the whole argument for
; keeping per-datump fitness around after you have learned to count it.

; --- Printed for the record, not asserted. ------------------------------------
!(collapse (bad (var-x)))
!(collapse (bad (const-1)))

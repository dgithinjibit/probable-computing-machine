; Solution 30 — Composing strength and confidence
(= (min-f $a $b) (if (< $a $b) $a $b))
(= (my-abs $x) (if (< $x 0) (- 0 $x) $x))

(= (and-stv $s1 $c1 $s2 $c2)
    (stv (* $s1 $s2) (min-f $c1 $c2)))

(= (or-stv $s1 $c1 $s2 $c2)
    (stv (- (+ $s1 $s2) (* $s1 $s2)) (min-f $c1 $c2)))

(= (not-stv $s $c) (stv (- 1 $s) $c))

!(assertEqualToResult (and-stv 2 3 4 5) ((stv 8 3)))
!(assertEqualToResult (or-stv 1 3 0 2) ((stv 1 2)))
!(assertEqualToResult (or-stv 2 5 0 3) ((stv 2 3)))
!(assertEqualToResult (not-stv 3 5) ((stv -2 5)))
!(assertEqual (min-f 3 5) 3)
!(assertEqual (my-abs -4) 4)

; Read the or-stv numbers before you trust the formula: (or-stv 2 3 4 5) is
; (- (+ 2 4) (* 2 4)) = -2, not 6. Whole numbers make the arithmetic checkable by
; hand, which is exactly why an assertion written from intuition goes wrong here.
; Real stv strengths live in [0, 1], where s1+s2-s1*s2 cannot leave the range.

; The naive product/min combination above is an approximation of PLN's
; evaluation rules, not those rules. Treat the property tests as the contract
; you are claiming, and read trueagi-io/PLN before trusting the constants.

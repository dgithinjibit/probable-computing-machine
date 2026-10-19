; l0-01-drills.metta
; L0 cards 1-5. Type these cold in your own file, then compare with this one.
; Do not paste. The checks at the bottom are part of the card.

; --- card 1: a rule and its call ---
(= (double $x) (* 2 $x))
!(double 4)

; --- card 2: facts, and one query over them ---
(parent Ada Bea)
(parent Bea Cy)
!(match &self (parent Ada $child) $child)

; --- card 3: recursion that stops ---
; One rule, with the stop written INSIDE it as a guard. If you write two rules
; here - (factorial 0) and (factorial $n) - the recursive rule also matches 0,
; the interpreter explores both, and the program never answers.
(= (factorial $n) (if (> $n 0) (* $n (factorial (- $n 1))) 1))
!(factorial 5)
!(factorial 0)

; --- card 4: a list, and a map over it ---
(= (triple $x) (* 3 $x))
(= (mymap $f ()) ())
(= (mymap $f (:: $head $tail)) (:: ($f $head) (mymap $f $tail)))
!(mymap triple (:: 1 (:: 2 (:: 3 ()))))

; --- card 5: a separate space you write to and read back ---
!(bind! &scratch (new-space))
!(add-atom &scratch (sensor left black))
!(match &scratch (sensor left $lane) $lane)

; --- the checks: an assertion that holds prints a single empty pair of parens ---
!(assertEqual (double 4) 8)
!(assertEqual (factorial 5) 120)
!(assertEqualToResult (match &self (parent Ada $c) $c) (Bea))

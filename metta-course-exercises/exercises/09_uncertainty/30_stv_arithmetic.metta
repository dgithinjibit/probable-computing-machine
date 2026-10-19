; Exercise 30 — Composing strength and confidence
; Book: metta-book/src/ch10-l4-uncertainty-and-agency.md (L4)
;
; There is no uncertainty in the interpreter. Write it.
; Requirements:
;   1. (: stv (-> $t $t Atom)) is not enough — define nothing; stv is your data
;   2. (and-stv $s1 $c1 $s2 $c2) -> (stv (* $s1 $s2) (min-f $c1 $c2))
;   3. (or-stv $s1 $c1 $s2 $c2) -> strength = s1 + s2 - s1*s2, confidence = min
;   4. (not-stv $s $c) -> (stv (- 1 $s) $c)
;   5. write your own min-f and my-abs: min-atom/max-atom answer floats and abs
;      does not exist in this build (verified fact sheet)
;
; Assertions use whole numbers so the printed forms are unambiguous; the semantic
; claim is identical for 0.7 and 0.8. If a float assertion prints differently on
; your build, change the assertion, not the rule.

; Your rules go here:


;!(assertEqualToResult (and-stv 2 3 4 5) ((stv 8 3)))
;!(assertEqualToResult (not-stv 3 5) ((stv -2 5)))

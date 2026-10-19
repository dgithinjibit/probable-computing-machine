; l0-02-toy-graph.metta
; L0 card 6: the kinship graph that most MeTTa material starts from, written
; by hand. Facts are edges, and a derived relation is a rule whose body is one
; match over a conjunction.

(child Dee Bea)
(sibling Cy Dee)
(female Cy)

; A conjunction pattern (comma) says: all of these must hold at the same time,
; sharing variables. Here $p is found once and used twice.
(= (aunt? $x $y)
   (match &self (, (sibling $x $p) (child $p $y)) True))
!(aunt? Cy Bea)

; A derived relation can answer with a constructed atom instead of True.
(= (aunt-of $x $y)
   (match &self (, (sibling $x $p) (child $p $y)) ($x aunt-of $y)))
!(aunt-of Cy Bea)

; Now add a second rule with the same head to require femaleness. Both rules
; have the same head, so both are explored: the query returns the answer twice.
; MeTTa has no first-match-wins and no override.
(= (aunt-of $x $y)
   (match &self (, (sibling $x $p) (child $p $y) (female $x)) ($x aunt-of $y)))
!(aunt-of Cy Bea)

; A query over a relation that has no rule at all. Sibling is stored only in
; one direction, so this produces nothing - the symmetry is your exercise.
!(match &self (sibling Dee $other) $other)

!(assertEqualToResult (match &self (sibling Cy $s) $s) (Dee))

; 02-facts-and-queries.metta
; Facts are atoms stored without the ! prefix. match searches the space.

(parent Ada Bea)
(parent Bea Cy)
(parent Cy Dee)

; One variable in the pattern captures the value in that position.
!(match &self (parent Ada $child) $child)
!(match &self (parent Cy $child) $child)

; A variable can appear on either side, and the same variable in the pattern
; and the template is substituted with the same value.
!(match &self (parent $person Cy) $person)

; Two facts match this pattern, so two results come back.
!(match &self (parent $p $c) ($p is a parent of $c))

; Conjunction: a comma pattern requires all parts to hold at the same time,
; with the variables shared.
!(match &self (, (parent Ada $x) (parent $x $y)) (Ada grandparent of $y))

; A pattern that matches nothing produces no result at all: the query is
; simply not reduced.
!(match &self (parent Dan $person) $person)

; Whitespace is part of the grammar. match&self is one symbol, not match
; applied to &self, so this line is stored rather than run:
;(match&self (parent Dan $person) $person)

; Exercise 02 — Query family facts
; Add the parent facts shown in the assertions.
; A query for Ada's children should return Bea and Cy.
; Add facts below:
(parent Ada Bea)
(parent Ada Cy)

!( match &self (parent Ada $person) $person)  




;!(match &self (parent Ada $child) $child)
;!(assertEqualToResult
    ;(match &self (parent Ada $child) $child)
    ;(Bea Cy))

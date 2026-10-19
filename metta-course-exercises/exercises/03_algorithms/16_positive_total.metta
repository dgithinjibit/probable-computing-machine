; Exercise 16 — Positive total (capstone)
; Sum only the positive numbers in a list.
; Implement the predicate and recursive total; do not change the assertions.
; Example: positive-total (:: -2 (:: 4 (:: 3 ()))) -> 7
; Your rules go here:

!(assertEqual (positive-total ()) 0)
!(assertEqual (positive-total (:: -2 (:: 4 (:: 3 ())))) 7)
!(assertEqual (positive-total (:: -5 (:: 0 ()))) 0)

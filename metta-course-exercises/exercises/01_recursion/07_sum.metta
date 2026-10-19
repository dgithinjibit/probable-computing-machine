; Exercise 07 — List sum
; Sum the numbers in a (:: head tail) list. The empty list sums to zero.
; Example: (sum (:: 4 (:: -1 (:: 3 ())))) -> 6
; Your rules go here:

!(assertEqual (sum ()) 0)
!(assertEqual (sum (:: 4 (:: -1 (:: 3 ())))) 6)

; Exercise 19 — Two sum
; Return True if two different list elements add up to the target.
; Example: (has-two-sum 9 (:: 2 (:: 7 (:: 11 ())))) -> True
; Your rules go here:

!(assertEqual (has-two-sum 9 (:: 2 (:: 7 (:: 11 ())))) True)
!(assertEqual (has-two-sum 6 (:: 3 (:: 3 ()))) True)
!(assertEqual (has-two-sum 6 (:: 3 ())) False)
!(assertEqual (has-two-sum 4 (:: 1 (:: 2 ()))) False)

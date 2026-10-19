; Exercise 20 — Palindrome list
; Return True when a list reads the same from either end.
; Example: (palindrome? (:: 1 (:: 2 (:: 1 ())))) -> True
; Your rules go here:

!(assertEqual (palindrome? ()) True)
!(assertEqual (palindrome? (:: 1 (:: 2 (:: 1 ())))) True)
!(assertEqual (palindrome? (:: 1 (:: 2 ()))) False)

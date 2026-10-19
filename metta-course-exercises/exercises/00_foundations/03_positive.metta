; Exercise 03 — Positive numbers
; Define (positive $n) to return True exactly when n is greater than zero.
; Examples: (positive 4) -> True, (positive 0) -> False
; Your rule goes here:

!(assertEqual (positive 4) True)
!(assertEqual (positive 0) False)
!(assertEqual (positive -2) False)

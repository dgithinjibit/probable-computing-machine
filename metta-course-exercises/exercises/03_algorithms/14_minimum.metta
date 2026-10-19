; Exercise 14 — Minimum
; Find the smallest number in a non-empty list.
; Example: (minimum (:: 4 (:: -2 (:: 7 ())))) -> -2
; You may write a helper that carries the best value so far.
; Your rules go here:

!(assertEqual (minimum (:: 4 (:: -2 (:: 7 ())))) -2)
!(assertEqual (minimum (:: 8 ())) 8)

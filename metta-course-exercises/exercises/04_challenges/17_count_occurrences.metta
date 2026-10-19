; Exercise 17 — Count occurrences
; Count how many times a value appears in a list.
; Example: (count-occurrences 2 (:: 2 (:: 1 (:: 2 ())))) -> 2
; Your rules go here:

!(assertEqual (count-occurrences 2 (:: 2 (:: 1 (:: 2 ())))) 2)
!(assertEqual (count-occurrences 5 (:: 2 (:: 1 ()))) 0)
!(assertEqual (count-occurrences 1 ()) 0)

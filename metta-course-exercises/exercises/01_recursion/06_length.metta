; Exercise 06 — List length
; Count the elements in a list built with (:: head tail) and ().
; Examples: (length ()) -> 0, (length (:: a (:: b ()))) -> 2
; Your rules go here:

!(assertEqual (length ()) 0)
!(assertEqual (length (:: a (:: b (:: c ()))) ) 3)

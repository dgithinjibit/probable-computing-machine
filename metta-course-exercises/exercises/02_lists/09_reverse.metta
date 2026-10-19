; Exercise 09 — Reverse a list
; Return a new list with the elements in the opposite order.
; Example: (reverse (:: 1 (:: 2 (:: 3 ())))) -> (:: 3 (:: 2 (:: 1 ())))
; Your rules go here:

!(assertEqual (reverse ()) ())
!(assertEqual
    (reverse (:: 1 (:: 2 (:: 3 ()))))
    (:: 3 (:: 2 (:: 1 ()))))

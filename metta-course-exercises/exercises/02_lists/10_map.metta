; Exercise 10 — Map
; Define triple, then map a function over every element of a list.
; Example: (map triple (:: 1 (:: 2 ()))) -> (:: 3 (:: 6 ()))
; Your rules go here:

!(assertEqual (map triple ()) ())
!(assertEqual
    (map triple (:: 1 (:: 2 ())))
    (:: 3 (:: 6 ())))

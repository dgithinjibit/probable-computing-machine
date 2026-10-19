; Exercise 11 — Filter positive values
; Keep only values greater than zero, preserving their order.
; Example: (filter-positive (:: -1 (:: 2 (:: 0 ())))) -> (:: 2 ())
; Your rules go here:

!(assertEqual (filter-positive ()) ())
!(assertEqual
    (filter-positive (:: -1 (:: 2 (:: 0 (:: 3 ())))))
    (:: 2 (:: 3 ())))

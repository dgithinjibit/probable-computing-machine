; Exercise 15 — Sort a list
; Return the numbers in ascending order, keeping duplicate values.
; Example: (sort (:: 3 (:: 1 (:: 2 ())))) -> (:: 1 (:: 2 (:: 3 ())))
; Build on minimum and a helper that removes only the first matching value.
; Your rules go here:

!(assertEqual (sort ()) ())
!(assertEqual
    (sort (:: 3 (:: 1 (:: 2 (:: 1 ())))))
    (:: 1 (:: 1 (:: 2 (:: 3 ())))))

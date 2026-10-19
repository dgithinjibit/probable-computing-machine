; Exercise 12 — Remove all matches
; Remove every occurrence of a value from a list, preserving other values.
; Example: remove 2 from (:: 2 (:: 1 (:: 2 ()))) -> (:: 1 ())
; Your rules go here:

!(assertEqual
    (remove-all 2 (:: 2 (:: 1 (:: 2 ()))))
    (:: 1 ()))

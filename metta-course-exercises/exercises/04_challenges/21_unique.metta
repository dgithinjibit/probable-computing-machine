; Exercise 21 — Remove duplicates
; Keep the first occurrence of each value, preserving the original order.
; Example: (deduplicate (:: 3 (:: 1 (:: 3 (:: 2 ())))))
;          -> (:: 3 (:: 1 (:: 2 ())))
; Your rules go here:

!(assertEqual (deduplicate ()) ())
!(assertEqual
    (deduplicate (:: 3 (:: 1 (:: 3 (:: 2 (:: 1 ()))))))
    (:: 3 (:: 1 (:: 2 ()))))
!(assertEqual (deduplicate (:: 4 (:: 4 ()))) (:: 4 ()))

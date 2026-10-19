; Exercise 08 — Append one value
; Add the value to the end of a list without changing the original order.
; Example: (append (:: 1 (:: 2 ())) 3) -> (:: 1 (:: 2 (:: 3 ())))
; Your rules go here:

!(assertEqual
    (append (:: 1 (:: 2 ())) 3)
    (:: 1 (:: 2 (:: 3 ()))))

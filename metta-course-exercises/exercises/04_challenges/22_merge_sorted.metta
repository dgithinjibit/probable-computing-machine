; Exercise 22 — Merge sorted lists
; Merge two ascending lists into one ascending list.
; Example: (merge-sorted (:: 1 (:: 4 ())) (:: 2 (:: 3 ())))
;          -> (:: 1 (:: 2 (:: 3 (:: 4 ()))))
; Your rules go here:

!(assertEqual (merge-sorted () ()) ())
!(assertEqual
    (merge-sorted (:: 1 (:: 4 ())) (:: 2 (:: 3 ())))
    (:: 1 (:: 2 (:: 3 (:: 4 ())))))
!(assertEqual
    (merge-sorted (:: 1 (:: 2 ())) (:: 2 (:: 2 ())))
    (:: 1 (:: 2 (:: 2 (:: 2 ())))))

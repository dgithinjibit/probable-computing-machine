; Exercise 13 — Membership
; Return True when a value occurs in the list, otherwise False.
; Example: (contains 2 (:: 1 (:: 2 ()))) -> True
; Your rules go here:

!(assertEqual (contains 2 (:: 1 (:: 2 ()))) True)
!(assertEqual (contains 5 (:: 1 (:: 2 ()))) False)
!(assertEqual (contains 1 ()) False)

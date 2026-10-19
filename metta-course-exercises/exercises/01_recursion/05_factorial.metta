; Exercise 05 — Factorial
; Define factorial for non-negative integers: n! = n * (n - 1)! and 0! = 1.
; Examples: (factorial 0) -> 1, (factorial 5) -> 120
; Your rules go here:
(= (factorial $x) 
    (if (== $n 0)
       1
       (* $n (factorial (- $n 1)))))

(factorial 0)
;!(assertEqual (factorial 0) 1)
;!(assertEqual (factorial 5) 120)

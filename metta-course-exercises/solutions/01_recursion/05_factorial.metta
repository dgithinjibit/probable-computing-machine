(: factorial (-> Number Number))
(= (factorial $n)
    (if (== $n 0)
        1
        (* $n (factorial (- $n 1)))))
(factorial 0)
;!(assertEqual (factorial 0) 1)
;!(assertEqual (factorial 5) 120)

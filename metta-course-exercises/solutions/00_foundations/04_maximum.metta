(: maximum (-> Number Number Number))
(= (maximum $a $b) (if (> $a $b) $a $b))

!(assertEqual (maximum 8 3) 8)
!(assertEqual (maximum -2 5) 5)
!(assertEqual (maximum 4 4) 4)

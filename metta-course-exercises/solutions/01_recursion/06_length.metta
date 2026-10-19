(: length (-> (List $t) Number))
(= (length ()) 0)
(= (length (:: $head $tail)) (+ 1 (length $tail)))

!(assertEqual (length ()) 0)
!(assertEqual (length (:: a (:: b (:: c ()))) ) 3)

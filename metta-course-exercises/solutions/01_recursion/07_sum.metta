(: sum (-> (List Number) Number))
(= (sum ()) 0)
(= (sum (:: $head $tail)) (+ $head (sum $tail)))

!(assertEqual (sum ()) 0)
!(assertEqual (sum (:: 4 (:: -1 (:: 3 ())))) 6)

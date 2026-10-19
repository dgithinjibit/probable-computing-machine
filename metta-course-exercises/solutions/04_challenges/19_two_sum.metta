(: contains (-> $t (List $t) Bool))
(= (contains $value ()) False)
(= (contains $value (:: $head $tail))
    (if (== $value $head)
        True
        (contains $value $tail)))

(: has-two-sum (-> Number (List Number) Bool))
(= (has-two-sum $target ()) False)
(= (has-two-sum $target (:: $head $tail))
    (if (contains (- $target $head) $tail)
        True
        (has-two-sum $target $tail)))

!(assertEqual (has-two-sum 9 (:: 2 (:: 7 (:: 11 ())))) True)
!(assertEqual (has-two-sum 6 (:: 3 (:: 3 ()))) True)
!(assertEqual (has-two-sum 6 (:: 3 ())) False)
!(assertEqual (has-two-sum 4 (:: 1 (:: 2 ()))) False)

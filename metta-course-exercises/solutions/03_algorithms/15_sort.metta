(: minimum (-> (List Number) Number))
(: minimum-from (-> (List Number) Number Number))
(= (minimum (:: $head $tail)) (minimum-from $tail $head))
(= (minimum-from () $best) $best)
(= (minimum-from (:: $head $tail) $best)
    (if (< $head $best)
        (minimum-from $tail $head)
        (minimum-from $tail $best)))

(: remove-first (-> Number (List Number) (List Number)))
(= (remove-first $value (:: $head $tail))
    (if (== $value $head)
        $tail
        (:: $head (remove-first $value $tail))))
(= (remove-first $value ()) ())

(: sort (-> (List Number) (List Number)))
(= (sort ()) ())
(= (sort (:: $head $tail))
    (let $smallest (minimum (:: $head $tail))
        (:: $smallest
            (sort (remove-first $smallest (:: $head $tail)))))
)

!(assertEqual (sort ()) ())
!(assertEqual
    (sort (:: 3 (:: 1 (:: 2 (:: 1 ())))))
    (:: 1 (:: 1 (:: 2 (:: 3 ())))))

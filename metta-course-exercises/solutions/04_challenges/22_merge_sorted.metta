(: merge-sorted (-> (List Number) (List Number) (List Number)))
(= (merge-sorted () $right) $right)
(= (merge-sorted (:: $left-head $left-tail) ())
    (:: $left-head $left-tail))
(= (merge-sorted (:: $left-head $left-tail)
                 (:: $right-head $right-tail))
    (if (<= $left-head $right-head)
        (:: $left-head
            (merge-sorted $left-tail (:: $right-head $right-tail)))
        (:: $right-head
            (merge-sorted (:: $left-head $left-tail) $right-tail))))

!(assertEqual (merge-sorted () ()) ())
!(assertEqual
    (merge-sorted (:: 1 (:: 4 ())) (:: 2 (:: 3 ())))
    (:: 1 (:: 2 (:: 3 (:: 4 ())))))
!(assertEqual
    (merge-sorted (:: 1 (:: 2 ())) (:: 2 (:: 2 ())))
    (:: 1 (:: 2 (:: 2 (:: 2 ())))))

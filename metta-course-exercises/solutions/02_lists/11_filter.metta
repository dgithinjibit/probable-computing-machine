(: positive (-> Number Bool))
(= (positive $n) (> $n 0))
(= (filter-positive ()) ())
(= (filter-positive (:: $head $tail))
    (if (positive $head)
        (:: $head (filter-positive $tail))
        (filter-positive $tail)))

!(assertEqual (filter-positive ()) ())
!(assertEqual
    (filter-positive (:: -1 (:: 2 (:: 0 (:: 3 ())))))
    (:: 2 (:: 3 ())))

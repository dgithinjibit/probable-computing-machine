(: contains (-> $t (List $t) Bool))
(= (contains $value ()) False)
(= (contains $value (:: $head $tail))
    (if (== $value $head)
        True
        (contains $value $tail)))

!(assertEqual (contains 2 (:: 1 (:: 2 ()))) True)
!(assertEqual (contains 5 (:: 1 (:: 2 ()))) False)
!(assertEqual (contains 1 ()) False)

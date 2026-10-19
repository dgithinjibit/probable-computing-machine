(= (remove-all $value ()) ())
(= (remove-all $value (:: $head $tail))
    (if (== $value $head)
        (remove-all $value $tail)
        (:: $head (remove-all $value $tail))))

!(assertEqual
    (remove-all 2 (:: 2 (:: 1 (:: 2 ()))))
    (:: 1 ()))

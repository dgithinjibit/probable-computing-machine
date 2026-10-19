(: append (-> (List $t) $t (List $t)))
(= (append () $value) (:: $value ()))
(= (append (:: $head $tail) $value)
    (:: $head (append $tail $value)))

!(assertEqual
    (append (:: 1 (:: 2 ())) 3)
    (:: 1 (:: 2 (:: 3 ()))))

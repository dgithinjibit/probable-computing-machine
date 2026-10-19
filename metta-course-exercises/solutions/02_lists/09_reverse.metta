(: reverse (-> (List $t) (List $t)))
(= (reverse $values) (reverse-into $values ()))
(= (reverse-into () $result) $result)
(= (reverse-into (:: $head $tail) $result)
    (reverse-into $tail (:: $head $result)))

!(assertEqual (reverse ()) ())
!(assertEqual
    (reverse (:: 1 (:: 2 (:: 3 ()))))
    (:: 3 (:: 2 (:: 1 ()))))

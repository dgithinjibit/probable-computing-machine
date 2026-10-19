(: contains (-> $t (List $t) Bool))
(= (contains $value ()) False)
(= (contains $value (:: $head $tail))
    (if (== $value $head)
        True
        (contains $value $tail)))

(: reverse (-> (List $t) (List $t)))
(: reverse-into (-> (List $t) (List $t) (List $t)))
(= (reverse $values) (reverse-into $values ()))
(= (reverse-into () $result) $result)
(= (reverse-into (:: $head $tail) $result)
    (reverse-into $tail (:: $head $result)))

(: deduplicate (-> (List $t) (List $t)))
(: deduplicate-into (-> (List $t) (List $t) (List $t)))
(= (deduplicate $values) (reverse (deduplicate-into $values ())))
(= (deduplicate-into () $seen) $seen)
(= (deduplicate-into (:: $head $tail) $seen)
    (if (contains $head $seen)
        (deduplicate-into $tail $seen)
        (deduplicate-into $tail (:: $head $seen))))

!(assertEqual (deduplicate ()) ())
!(assertEqual
    (deduplicate (:: 3 (:: 1 (:: 3 (:: 2 (:: 1 ()))))))
    (:: 3 (:: 1 (:: 2 ()))))
!(assertEqual (deduplicate (:: 4 (:: 4 ()))) (:: 4 ()))

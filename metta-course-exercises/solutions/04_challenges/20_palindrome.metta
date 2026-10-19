(: reverse (-> (List $t) (List $t)))
(: reverse-into (-> (List $t) (List $t) (List $t)))
(= (reverse $values) (reverse-into $values ()))
(= (reverse-into () $result) $result)
(= (reverse-into (:: $head $tail) $result)
    (reverse-into $tail (:: $head $result)))

(: palindrome? (-> (List $t) Bool))
(= (palindrome? $values) (== $values (reverse $values)))

!(assertEqual (palindrome? ()) True)
!(assertEqual (palindrome? (:: 1 (:: 2 (:: 1 ())))) True)
!(assertEqual (palindrome? (:: 1 (:: 2 ()))) False)

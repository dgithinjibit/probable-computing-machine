; 07-filter.metta
; A predicate passed as an argument: functions are atoms like any other.

(: positive (-> Number Bool))
(= (positive $x) (> $x 0))
(= (filter $predicate ()) ())
(= (filter $predicate (:: $head $tail))
    (if ($predicate $head)
        (:: $head (filter $predicate $tail))
        (filter $predicate $tail)))

!(filter positive (:: 1 (:: -2 (:: 3 ()))))
!(filter positive (:: -1 (:: -2 ())))

; The stdlib also offers folds over tuple expressions (not over :: lists).
; foldl-atom takes the list, the initial value, the accumulator variable, the
; element variable and the operation.
!(foldl-atom (:: 1 (:: 2 (:: 3 ()))) 0 $acc $e (+ $acc $e))
!(foldl-atom (1 2 3) 0 $acc $e (+ $acc $e))
!(map-atom (1 2 3) $x (* $x 10))
!(min-atom (3 1 2))

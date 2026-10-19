(= (triple $n) (* 3 $n))
(= (map $function ()) ())
(= (map $function (:: $head $tail))
    (:: ($function $head) (map $function $tail)))

!(assertEqual (map triple ()) ())
!(assertEqual
    (map triple (:: 1 (:: 2 ())))
    (:: 3 (:: 6 ())))

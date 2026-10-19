; 06-map.metta
; Two rules, one for each shape of a list: empty, and head :: tail.

(= (cube $x) (* $x (* $x $x)))
(= (map $f ()) ())
(= (map $f (:: $head $tail))
    (:: ($f $head) (map $f $tail)))

!(map cube (:: 1 (:: 3 (:: 6 ()))))

; The same program written with declared data types, which is how upstream
; MeTTa examples usually look. (: List (-> $a Type)) makes List a type
; constructor, Nil a value, and Cons a constructor taking a head and a tail.
(: List (-> $a Type))
(: Nil (List $a))
(: Cons (-> $a (List $a) (List $a)))
(= (map-cube Nil) Nil)
(= (map-cube (Cons $head $tail)) (Cons (cube $head) (map-cube $tail)))
!(map-cube (Cons 1 (Cons 3 (Cons 6 Nil))))

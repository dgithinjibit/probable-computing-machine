; 04-evaluation.metta
; What is stored, what is evaluated, and what one step of evaluation means.

(color apple red)
(color watermelon green)
(= (favorite-color $thing) (match &self (color $thing $value) $value))

!(favorite-color apple)
!(favorite-color watermelon)
; Nothing is printed for pear: no fact matches, so the call is not reduced.
!(favorite-color pear)

; Arguments fill the pattern positions left to right. $person is the FIRST
; slot of (race $person $complexion), so passing "black" here looks for facts
; that start with black and finds none.
(race africa black)
(race europe white)
(race asia yellow)
(= (complexion-of $region) (match &self (race $region $skin) $skin))
!(complexion-of africa)

; eval performs exactly one step of reduction, which is how you watch a
; recursive function move.
(= (count $n) (if (> $n 0) (count (- $n 1)) zero))
!(count 3)
!(eval (count 3))
!(eval (eval (count 3)))

; collapse turns all results of a query into one tuple, so you can count them.
(= (fruit) apple)
(= (fruit) pear)
!(collapse (fruit))

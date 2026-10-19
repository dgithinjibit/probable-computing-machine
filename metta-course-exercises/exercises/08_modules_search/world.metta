; Exercise 28 (module side) — the map, as a library
; The module's &self is THIS space, not the client's. Facts belong here.
; See README.md in this directory for how to run it.

(= (rooms) (match &self (room $r) $r))
(= (adjacent $a) (match &self (connects $a $b) $b))

(room kitchen)
(room hall)
(room pantry)
(connects kitchen hall)
(connects kitchen pantry)

; Task 3: add a query here that shows &self is the module space, e.g.
; !(match &self (room $r) $r)

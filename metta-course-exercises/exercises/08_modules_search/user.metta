; Exercise 28 (client side) — use the library, declare nothing
; Must be run from this directory: import! resolves against the working directory.

!(import! &world world)

;!(assertEqual (world rooms) (kitchen hall pantry))
;!(assertEqualToResult (world adjacent kitchen) (hall pantry))

; Task 4 — the upward-dependency wall. This should NOT work, because a module may
; not depend on the client that imports it:
;   write (client-only fact) into this file, then try to reach it from world.metta.
; Fix it by giving world.metta a function that takes a space as an argument:
;   (= (objects-in $space $room) (match $space (at $o $room) $o))
; and call it with the client's own space.

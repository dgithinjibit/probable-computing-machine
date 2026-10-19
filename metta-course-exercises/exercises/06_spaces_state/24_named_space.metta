; Exercise 24 — A space you can inspect
; Book: metta-book/src/ch03-00-facts-spaces-queries.md (L1 Unit 2)
;
; Build a named space that holds a rover's map facts, then query it.
; Requirements:
;   1. bind! a new space to &map
;   2. add-atom three rooms and two connections
;   3. define (adjacent $a) that returns every room connected from $a
;
; Note the difference between !(get-atoms &map) and !(get-atoms &self):
; on this build only the named one prints. See the verified fact sheet.

!(bind! &map (new-space))

; Your add-atom calls go here:


; Your rule goes here:
; (= (adjacent $a) ...)

;!(assertEqualToResult (adjacent kitchen) (hall pantry))
;!(assertEqualToResult (match &map (room $r) $r) (kitchen hall pantry))

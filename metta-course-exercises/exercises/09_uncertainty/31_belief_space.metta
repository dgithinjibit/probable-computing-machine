; Exercise 31 — A belief space with one honest hole
; Book: metta-book/src/ch10-l4-uncertainty-and-agency.md (L4)
;
; Requirements:
;   1. build &kb and add at least four (Inheritance $a $b (stv $s $c)) links
;   2. (strength $a $b) returns the stored strength
;   3. (believe $a) returns the strength of the strongest link out of $a, using
;      collapse + foldl-atom (tuple children, not :: lists)
;   4. then delete one (strength ...) fact and show your fold silently shrinking
;      rather than raising — that is the L4 failure mode, on purpose
;
; Write in one sentence why (believe $a) must not be a second (= (strength ...))
; rule with the same head.

; Your rules go here:


;!(assertEqualToResult (strength "off-line" "danger") (0.7))

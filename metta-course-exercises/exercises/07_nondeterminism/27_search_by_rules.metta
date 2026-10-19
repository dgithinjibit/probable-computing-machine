; Exercise 27 — Find the program by rules, not by hand
; Book: metta-book/src/ch09-l3-modules-and-search.md (L3)
;
; Let the interpreter's rule lookup be your search engine: several rules for one
; head enumerate candidates, a guard keeps the ones that fit, and Empty rejects
; the rest without printing noise.
; Requirements:
;   1. (a-num) enumerates 1, 2, 3, 4
;   2. (square-is $t) returns only the candidate whose square equals $t
;   3. !(square-is 9) answers 3
;
; Do NOT write four guarded rules that all fire. Use one rule plus match/if, or
; one rule plus Empty, and say in a comment which you chose and why.

; Your rules go here:


;!(assertEqual (square-is 9) 3)
;!(assertEqualToResult (a-num) (1 2 3 4))

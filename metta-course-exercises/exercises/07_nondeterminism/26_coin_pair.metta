; Exercise 26 — Two coins, four results
; Book: metta-book/src/ch05-00-evaluation-and-results.md (L1 Unit 4)
;
; Nondeterminism multiplies across argument positions.
; Requirements:
;   1. define (coin) so it returns heads AND tails (two rules, same head)
;   2. define (pair $a $b) returning (ab $a $b)
;   3. predict the number of results of !(pair (coin) (coin)) before running
;   4. collapse the same call into one tuple
;
; Write your prediction as a comment. Wrong predictions that were written down
; first are the useful ones.

; Your rules go here:


; Prediction for !(pair (coin) (coin)):

;!(assertEqualToResult (pair (coin) (coin)) ((ab heads heads) (ab heads tails) (ab tails heads) (ab tails tails)))
;!(assertEqualToResult (collapse $r (coin)) ((heads tails)))

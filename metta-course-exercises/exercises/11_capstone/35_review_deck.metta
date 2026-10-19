; Exercise 35 — The review deck
; Book: every level; recall cards are listed at the end of each chapter
;
; Spaced repetition in the language you are learning. Requirements:
;   1. (card $id :level $l :last $day :step $n) atoms, at least six cards
;      covering L0 to L5
;   2. (due? $id $today) is True when (- $today :last) >= :step
;   3. (next $today) returns the due cards
;   4. (answer! $id $today $ok) advances :last and steps :step through 1/3/7/21
;      when $ok is True, and resets it to 1 when $ok is False
;
; Constraints: >=, >, <, == exist; !=, abs, sqrt, sum-atom do not. Guard negative
; gaps with >= rather than reaching for abs.

(card c-01 :level L0 :last 300 :step 1)
(card c-02 :level L1 :last 330 :step 3)
(card c-03 :level L2 :last 337 :step 7)

; Your rules go here:

;!(assertEqualToResult (due? c-01 342) (True))
;!(assertEqualToResult (due? c-03 340) (False))

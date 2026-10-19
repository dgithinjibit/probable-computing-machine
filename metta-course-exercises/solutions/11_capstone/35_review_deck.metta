; Solution 35 — The review deck
(card c-01 :level L0 :last 300 :step 1)
(card c-02 :level L1 :last 330 :step 3)
(card c-03 :level L2 :last 337 :step 7)
(card c-04 :level L3 :last 320 :step 21)
(card c-05 :level L4 :last 341 :step 7)
(card c-06 :level L5 :last 305 :step 21)

(= (gap $id $today)
    (match &self (card $id :level $l :last $d :step $s) (- $today $d)))
(= (step-of $id)
    (match &self (card $id :level $l :last $d :step $s) $s))

; due? is >=, guarded for a negative gap (a card recorded in the "future" is not
; due). abs does not exist here, so the guard is explicit instead.
(= (due? $id $today)
    (let $g (gap $id $today)
        (let $s (step-of $id)
            (if (< $g 0) False (if (>= $g $s) True False)))))

(= (next $today) (match &self (card $id :level $l :last $d :step $s) $id))

!(assertEqualToResult (due? c-01 342) (True))
!(assertEqualToResult (due? c-05 342) (False))
!(assertEqualToResult (due? c-03 344) (True))
!(assertEqualToResult (due? c-04 341) (True))

; (answer! ...) intentionally left as state-free: mutate by remove-atom of the
; exact old card atom, then add-atom the new one. Two notes before you write it:
; (1) remove-atom matches by whole atom, not by :level key, so you must remember
; the exact atom you stored; (2) (step-of $id) returns the step of the card you
; then replace, so sequence the two calls — the second must run after the first.
;
; Step ladder: 1 -> 3 -> 7 -> 21 -> 21 (a card that keeps being right stays at
; the widest interval this deck supports).

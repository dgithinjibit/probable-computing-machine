; l6-01-report.metta
; L6: the capstone's two pieces of infrastructure, small enough to read at once.
; Everything here is composition from L0 to L5; nothing is new syntax.

; --- the hour log ---
; FACTS, not rules: match sees stored atoms, and (= (hours day-342) 14) is stored
; as an = expression, so a rule-shaped log is invisible to (all-hours) and reports
; silence instead of hours. Verified 2026-10-19.
(hours day-340 14)
(hours day-341 9)
(hours day-342 0)
(hours day-343 12)

(= (all-hours) (match &self (hours $d $h) $h))
; foldl-atom's first position is Atom-typed, so it is handed UN_EVALUATED: bind the
; collapse with `let` first, or you fold over the two children of the call itself.
; Verified 2026-10-19 -- the wrong shape answers with (Error (+ 0 collapse) ...).
(= (total) (let $t (collapse (all-hours)) (foldl-atom $t 0 $acc $e (+ $acc $e))))
(= (days-count) (let $t (collapse (all-hours)) (foldl-atom $t 0 $acc $e (+ $acc 1))))

!(total)
!(days-count)

; Integer division is the first place a published number goes wrong:
!(assertEqual (/ 35 4) 8)
!(assertEqual (/ (* 1.0 35) 4) 8.75)
!(assertEqual (total) 35)

; --- the review deck ---
(card c-01 :level L0 :last 300 :step 1)
(card c-02 :level L1 :last 330 :step 3)
(card c-03 :level L2 :last 337 :step 7)

(= (gap $id $today) (match &self (card $id :level $l :last $d :step $s) (- $today $d)))
(= (step-of $id) (match &self (card $id :level $l :last $d :step $s) $s))
(= (due? $id $today)
    (let $g (gap $id $today)
        (let $s (step-of $id)
            (if (< $g 0) False (if (>= $g $s) True False)))))

!(due? c-01 342)
!(due? c-03 344)

!(assertEqualToResult (due? c-01 342) (True))
!(assertEqualToResult (due? c-02 342) (True))

; The capstone standard: every number this book will let you say out loud is
; asserted somewhere in this file, and the arithmetic cliff is shown rather than
; stepped on.

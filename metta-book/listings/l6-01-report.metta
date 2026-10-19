; l6-01-report.metta
; L6: the capstone's two pieces of infrastructure, small enough to read at once.
; Everything here is composition from L0 to L5; nothing is new syntax.

; --- the hour log ---
(= (hours day-340) 14)
(= (hours day-341) 9)
(= (hours day-342) 0)
(= (hours day-343) 12)

(= (all-hours) (match &self (hours $d $h) $h))
(= (total) (foldl-atom (collapse $h (all-hours)) 0 $acc $e (+ $acc $e)))
(= (days-count) (foldl-atom (collapse $d (match &self (hours $d $h) 1)) 0 $acc $e (+ $acc 1)))

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

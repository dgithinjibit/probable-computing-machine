; Solution 34 — The hour log
(= (hours day-340) 14)
(= (hours day-341) 9)
(= (hours day-342) 0)
(= (hours day-343) 12)

(= (all-hours) (match &self (hours $d $h) $h))

; collapse turns the four results into one tuple, whose children foldl-atom folds.
; (foldl-atom over a :: list would fold the wrong things — see the fact sheet.)
(= (total) (foldl-atom (collapse $h (all-hours)) 0 $acc $e (+ $acc $e)))
(= (days-count) (foldl-atom (collapse $d (match &self (hours $d $h) 1)) 0 $acc $e (+ $acc 1)))

!(assertEqualToResult (all-hours) (14 9 0 12))
!(assertEqual (total) 35)
!(assertEqual (days-count) 4)

; Integer truncation, shown rather than hidden: total/days-count is 35/4, and
; (/ 35 4) gives 8, not 8.75. Multiply one operand by 1.0 for the honest average.
!(assertEqual (/ 35 4) 8)
!(assertEqual (/ (* 1.0 35) 4) 8.75)

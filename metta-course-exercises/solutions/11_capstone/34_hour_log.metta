; Solution 34 — The hour log
; Data is written as FACTS here, not as rules. That choice is requirement 6.
(hours day-340 14)
(hours day-341 9)
(hours day-342 0)
(hours day-343 12)

(= (all-hours) (match &self (hours $d $h) $h))

; collapse turns the four results into one tuple, whose children foldl-atom folds.
; collapse is ONE-argument on 0.2.10 -- it is not a binder; `let` is the binder.
; And the tuple has to be BOUND before foldl-atom sees it: foldl-atom's first
; position is an `Atom`-typed parameter, which the spec says is passed without
; evaluation, so (foldl-atom (collapse (all-hours)) ...) hands the folder the
; un-evaluated call and its two children -- you get (+ 0 collapse) and a
; BadArgType. Verified 2026-10-19.
(= (total) (let $t (collapse (all-hours)) (foldl-atom $t 0 $acc $e (+ $acc $e))))
(= (days-count) (let $t (collapse (all-hours)) (foldl-atom $t 0 $acc $e (+ $acc 1))))
(= (avg) (/ (* 1.0 (total)) (days-count)))

!(assertEqualToResult (all-hours) (14 9 0 12))
!(assertEqualToResult (collapse (all-hours)) ((12 0 9 14)))
!(assertEqual (total) 35)
!(assertEqual (days-count) 4)

; Integer truncation, shown rather than hidden: total/days-count is 35/4, and
; (/ 35 4) gives 8, not 8.75. Multiply one operand by 1.0 for the honest average.
!(assertEqual (/ 35 4) 8)
!(assertEqual (/ (* 1.0 35) 4) 8.75)
!(assertEqual (avg) 8.75)

; Requirement 6 -- the form grind.txt actually uses is a RULE:
(= (hours2 day-345) 11)
!(assertEqual (hours2 day-345) 11)
!(assertEqualToResult (match &self (hours2 $d $h) $h) ())
; A rule answers a call but is invisible to match, because match looks at the
; atoms that are stored and (= (hours2 day-345) 11) is stored as an = expression
; whose head is =, not hours2. So a rule-shaped log can only be read one day at a
; time, by name, and (all-hours) over it returns nothing at all -- silently. Write
; the log as facts; keep the rules for the arithmetic over them.

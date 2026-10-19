; Exercise 34 — The hour log
; Book: metta-book/src/ch12-l6-capstone.md (L6)
;
; Requirements:
;   1. rules of the form (= (hours day-342) 14) — your own, at least four days
;   2. (all-hours) returns every recorded value
;   3. (total) sums them with collapse + foldl-atom (tuple children, not :: lists)
;   4. (days-count) counts them
;   5. (avg) divides — and then show, in a comment, what integer truncation did to
;      your average. / between integers truncates: (/ 7 2) is 3.
;
; This is the file where a number you plan to say out loud gets checked.

; Your rules go here:

;!(assertEqualToResult (all-hours) (14 9 0 12))
;!(assertEqual (total) 35)

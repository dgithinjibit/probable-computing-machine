; Exercise 34 — The hour log
; Book: metta-book/src/ch12-l6-capstone.md (L6)
;
; Requirements:
;   1. at least four recorded days. Write them as FACTS, i.e. (hours day-342 14).
;      (grind.txt writes them as rules, (= (hours day-342) 14). Requirement 6 is
;      about why that form cannot be read the way this exercise reads facts.)
;   2. (all-hours) returns every recorded value
;   3. (total) sums them with collapse + foldl-atom (tuple children, not :: lists)
;   4. (days-count) counts them
;   5. (avg) divides — and then show, in a comment, what integer truncation did to
;      your average. / between integers truncates: (/ 7 2) is 3.
;   6. in a comment: define (= (hours2 day-345) 11) as a RULE and show that
;      (match &self (hours2 $d $h) $h) finds nothing while (hours2 day-345) answers
;      11. Which one is data, which one is a function, and what does that cost you
;      when the log is going to be read by a report?
;
; This is the file where a number you plan to say out loud gets checked.

; Your facts go here:

;!(assertEqualToResult (all-hours) (14 9 0 12))
;!(assertEqual (total) 35)

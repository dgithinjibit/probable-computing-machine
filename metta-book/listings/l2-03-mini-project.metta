; 08-mini-project.metta
; Facts, a labelled function, a query over the facts, and self-checks.

(: label-score (-> Number Symbol))
(= (label-score $score)
    (if (>= $score 60) passing needs-review))

(score Ada 92)
(score Bea 48)
(score Cy 75)

!(match &self (score $student $value) ($student (label-score $value)))

; assertEqual checks one result and prints nothing when it holds; it is the
; cheapest way to make a listing self-testing.
!(assertEqual (label-score 60) passing)
!(assertEqual (label-score 59) needs-review)
!(assertEqualToResult
  (match &self (score $s 48) $s)
  (Bea))

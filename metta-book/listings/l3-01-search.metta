; l3-01-search.metta
; L3: rule lookup as a search engine. Enumeration rules generate candidates,
; one filter rule keeps what fits, and Empty rejects silently rather than
; printing False. Spec basis: metta_call runs query(space, (= atom $X)) and
; collects EVERY binding, so N same-head rules = N candidates.

(= (a-num) 1)
(= (a-num) 2)
(= (a-num) 3)
(= (a-num) 4)

(= (square-is $t)
    (let $n (a-num)
        (if (== (* $n $n) $t) $n Empty)))

!(square-is 9)
!(square-is 16)

; Two positions multiply: 4 x 4 = 16 candidate pairs, not 8.
(= (sum-to $t)
    (let $a (a-num)
        (let $b (a-num)
            (if (== (+ $a $b) $t) (, $a $b) Empty))))
!(sum-to 5)

; Programs are atoms too. Lowering a shape is the same multi-match, one level up
; (see l5-01-lowering.metta).
!(assertEqual (square-is 9) 3)
!(assertEqualToResult (a-num) (1 2 3 4))

; The module half of L3 lives in metta-course-exercises/exercises/08_modules_search/,
; because import! resolves against the working directory and cannot be checked from
; wherever the verifier happens to sit.

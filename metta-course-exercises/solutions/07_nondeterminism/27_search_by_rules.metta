; Solution 27 — Find the program by rules, not by hand
; Four enumeration rules (candidates), one search rule (filter). The filter is a
; single rule; Empty is what "this candidate is not an answer" looks like, and it
; contributes nothing to the result set instead of printing a False.
(= (a-num) 1)
(= (a-num) 2)
(= (a-num) 3)
(= (a-num) 4)

(= (square-is $t)
    (let $n (a-num)
        (if (== (* $n $n) $t) $n Empty)))

!(assertEqual (square-is 9) 3)
!(assertEqual (square-is 16) 4)
!(assertEqualToResult (a-num) (1 2 3 4))

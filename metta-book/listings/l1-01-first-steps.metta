; 01-first-steps.metta
; The three things every MeTTa file needs: atoms, the ! prefix, and rules.

; Two numbers and a computation. The ! prefix means "evaluate this and show me".
!(+ 2 3)
!(% 11 3)

; x and y are symbols. Symbols are ids; they are not numbers and they do not
; hold values the way a variable in Python does.
;x = 2
;y = 3

; A rule: "(= (pattern) body)" teaches the interpreter how to reduce a call.
; $x marks a variable, so the rule matches any argument.
(= (double $x) (* 2 $x))
;we are doubling $x by 2
!(double 4)
!(double 10)

; Without the $ marker the left side only matches the literal symbol x, so the
; call below is not reduced and is returned unchanged. Uncomment it and run the
; file to see the difference:
;(= (bad-double x) (* 2 x))
;!(bad-double 4)

; A stored atom is data. This line has no !, so it is added to the space
; instead of being printed:
(first fact of the file)

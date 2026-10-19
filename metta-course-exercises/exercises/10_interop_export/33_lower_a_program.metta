; Exercise 33 — Lower one program into another
; Book: metta-book/src/ch11-l5-interop-and-export.md (L5)
;
; A transpiler front end is pattern matching over program shapes. Keep the program
; as DATA (never as a live expression), or the interpreter reduces it before your
; rules ever see it — see L1 Unit 4 on argument position.
; Requirements:
;   1. facts of the form (prog <expr>) hold the source shape, e.g.
;      (prog (add (mul 2 x) 3))
;   2. (lower $e) rewrites: (mul $a $b) -> (:mul $a $b), (add $a $b) -> (:add $a $b),
;      numbers -> (:mov r0 $n), symbols -> (:ld $sym)
;   3. (compile $p) lowers a whole (prog ...) into a list of instruction tuples
;
; Then answer, in a comment: which part of this is a transducer and what would make
; it a compiler? (Hint: register allocation, scheduling, a real target semantics.)

(prog (add (mul 2 x) 3))

; Your rules go here:

;!(assertEqualToResult (lower (mul 2 x)) ((:mul 2 x)))

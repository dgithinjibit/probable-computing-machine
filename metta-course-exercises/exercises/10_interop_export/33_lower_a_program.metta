; Exercise 33 — Lower one program into another, deterministically
; Book: metta-book/src/ch11-l5-interop-and-export.md (L5)
;
; A transpiler front end is pattern matching over program shapes. Keep the program
; as DATA (never as a live expression), or the interpreter reduces it before your
; rules ever see it — see L1 Unit 4 on argument position.
;
; The twist that makes this a real lowering and not a toy: it must give ONE answer.
; Calling is querying, and every rule that matches is explored, so overlapping
; patterns multiply. Leaves therefore carry their own tag instead of being
; recognised by a catch-all rule.
;
; Requirements:
;   1. facts of the form (prog <expr>) hold the source shape, with tagged leaves,
;      e.g. (prog (add (mul (num 2) (var x)) (num 3)))
;   2. (lower $e) rewrites:
;        (mul $a $b) -> (:mul (lower $a) (lower $b))
;        (add $a $b) -> (:add (lower $a) (lower $b))
;        (num $v)    -> (:mov r0 $v)
;        (var $n)    -> (:ld $n)
;   3. (compile) lowers every (prog ...) fact in the space
;   4. assert exactly one instruction tree for (prog (mul (num 2) (var x))), and
;      find out what an op you gave no rule for produces. It is neither an error
;      nor silence -- look at what comes back and assert THAT.
;
; Then answer, in a comment:
;   a. why can the leaf rules not be written as catch-alls like (= (lower $x) (:ld $x))?
;   b. which part of this is a transducer and what would make it a compiler?
;      (Hint: register allocation, scheduling, a real target semantics, and a
;      validator that refuses illegal shapes.)

(prog (add (mul (num 2) (var x)) (num 3)))

; Your rules go here:

;!(assertEqualToResult (compile)
;    ((:add (:mul (:mov r0 2) (:ld x)) (:mov r0 3))))

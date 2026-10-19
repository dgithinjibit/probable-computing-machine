; Solution 33 — Lower one program into another
(prog (add (mul 2 x) 3))

; The source stays data: it lives behind (prog ...), so no rule sees a live
; expression that the interpreter would reduce first.
(= (lower $n) (:mov r0 $n))
(= (lower $e) (:ld $e))

(= (lower (mul $a $b)) (:mul (operand $a) (operand $b)))
(= (lower (add $a $b)) (:add (operand $a) (operand $b)))

(= (operand $x) (lower $x))

(= (compile $p) (match &self (prog $e) (lower $e)))

!(assertEqualToResult (compile (prog (mul 2 x))) ((:mul (:mov r0 2) (:ld x))))

; Transducer, not compiler: this maps shape -> shape with no notion of a target's
; legality, no register pressure, no instruction scheduling, no target semantics,
; and nothing checks that (:mul) exists on the far end. It becomes a compiler when
; the target has rules that the source cannot be trusted to respect — at which point
; you need a validator (assertions, as here) and then a scheduler, and that is a
; different project than the one in this file.

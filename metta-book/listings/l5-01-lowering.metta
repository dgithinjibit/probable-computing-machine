; l5-01-lowering.metta
; L5: minimal MeTTa as the assembly layer, and programs kept as DATA so the
; interpreter cannot reduce them before your rules see them.

(= (double $x) (* 2 $x))

; eval makes exactly one step; chain binds the result it just computed.
!(eval (double 3))
!(chain (double 3) $r (+ $r 1))
!(unify (p 1) (p $x) yes no)

; Atoms as data: car/cdr/cons on a tuple.
!(car-atom (1 2 3))
!(cdr-atom (1 2 3))
!(cons-atom add (1 2))

; Lowering: pattern-match program shapes into a target shape. The source sits
; behind (prog ...) so it stays inert.
(prog (add (mul 2 x) 3))
(= (lower (mul $a $b)) (:mul $a $b))
(= (lower (add $a $b)) (:add $a $b))
(= (lower $n) (:mov $n))
(= (compile) (match &self (prog $e) (lower $e)))
!(compile)

!(assertEqual (chain (double 3) $r (+ $r 1)) 7)
!(assertEqualToResult (cdr-atom (1 2 3)) ((2 3)))

; This is a transducer, not a compiler: shape in, shape out, no target semantics,
; no register or schedule decisions. The export half (json with STRING keys,
; fileio round trip) lives in
; metta-course-exercises/exercises/10_interop_export/32_json_roundtrip.metta,
; because those calls touch the filesystem and belong in a checked exercise, not
; in a listing the verifier runs blind.

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
; behind (prog ...) so it stays inert. Leaves carry their own tag (num/var)
; BECAUSE the lowering must be deterministic: see the TRAP note at the bottom.
(prog (add (mul (num 2) (var x)) (num 3)))
(= (lower (num $v)) (:mov r0 $v))
(= (lower (var $n)) (:ld $n))
(= (lower (mul $a $b)) (:mul (lower $a) (lower $b)))
(= (lower (add $a $b)) (:add (lower $a) (lower $b)))
(= (compile) (match &self (prog $e) (lower $e)))
!(assertEqualToResult (compile)
    ((:add (:mul (:mov r0 2) (:ld x)) (:mov r0 3))))

; One program in, exactly one instruction tree out. That is the whole difference
; between this file and a nondeterministic query.

!(assertEqual (chain (double 3) $r (+ $r 1)) 7)
!(assertEqualToResult (cdr-atom (1 2 3)) ((2 3)))

; TRAP, verified 2026-10-19: give lower a catch-all leaf rule
;     (= (lower $n) (:mov $n))
; alongside the (mul ...) and (add ...) rules and (compile) answers with FOURTEEN
; results for the one program above. Calling is querying, and every rule that
; matches is explored, so overlapping patterns are not a style problem, they are
; a multiplicity problem. A lowering is deterministic only when its patterns are
; structurally disjoint -- which is why the leaves here are tagged.

; This is a transducer, not a compiler: shape in, shape out, no target semantics,
; no register or schedule decisions. The export half (json with STRING keys,
; fileio round trip) lives in
; metta-course-exercises/exercises/10_interop_export/32_json_roundtrip.metta,
; because those calls touch the filesystem and belong in a checked exercise, not
; in a listing the verifier runs blind.

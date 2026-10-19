; Solution 33 — Lower one program into another, deterministically
(prog (add (mul (num 2) (var x)) (num 3)))

; The source stays data: it lives behind (prog ...), so no rule sees a live
; expression that the interpreter would reduce first. Leaves are TAGGED (num/var)
; rather than recognised by a catch-all rule, and that is what keeps the answer
; single: the four patterns below have four different heads, so at most one can
; match any given shape.

(= (lower (num $v)) (:mov r0 $v))
(= (lower (var $n)) (:ld $n))
(= (lower (mul $a $b)) (:mul (lower $a) (lower $b)))
(= (lower (add $a $b)) (:add (lower $a) (lower $b)))

(= (compile (prog $e)) (lower $e))

; Note the shape of that rule: it destructures its ARGUMENT. The tempting version,
;     (= (compile $p) (match &self (prog $e) (lower $e)))
; ignores $p and answers with every program in the space -- which is what this file
; originally did, and how one program ended up lowering into someone else's tree.

!(assertEqualToResult (compile (prog (mul (num 2) (var x))))
    ((:mul (:mov r0 2) (:ld x))))
!(assertEqualToResult (compile (prog (add (num 1) (num 2))))
    ((:add (:mov r0 1) (:mov r0 2))))

; (a) An op you never gave a rule for does NOT fail. It comes back UNREDUCED:
; the target tree contains a live (lower ...) call wearing an instruction's
; clothes. Verified 2026-10-19:
!(assertEqualToResult (compile (prog (sub (num 1) (num 2))))
    ((lower (sub (num 1) (num 2)))))
; That is the silent-hole shape, and it is why a lowering needs a validator that
; refuses any result still containing `lower`. Silence would be safer, and MeTTa
; does not give it to you here.

; (b) A catch-all leaf rule (= (lower $x) (:ld $x)) matches EVERYTHING, including
; (mul 2 x) itself, and MeTTa explores every matching rule rather than the first.
; Verified on 0.2.10: with a generic (= (lower $n) (:mov r0 $n)) plus
; (= (lower $e) (:ld $e)) beside the two op rules, lowering
; (prog (mul 2 x)) returns fourteen results instead of one -- the cross product of
; every rule that fits at every position. Overlapping patterns are not a style
; problem here; they are the difference between a transducer and a search.

; Transducer, not compiler: this maps shape -> shape with no notion of a target's
; legality, no register pressure, no instruction scheduling, no target semantics,
; and nothing checks that (:mul) exists on the far end. It becomes a compiler when
; the target has rules that the source cannot be trusted to respect -- at which point
; you need a validator (the assertions above are the beginning of one) and then a
; scheduler, and that is a different project than the one in this file.

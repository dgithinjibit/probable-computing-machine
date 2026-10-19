; Solution 31 — A belief space with one honest hole
!(bind! &kb (new-space))
!(add-atom &kb (Inheritance "off-line" "danger" (stv 0.7 0.8)))
!(add-atom &kb (Inheritance "dark" "off-line" (stv 0.55 0.9)))
!(add-atom &kb (Inheritance "obstacle-near" "danger" (stv 0.9 0.95)))
!(add-atom &kb (Inheritance "lost" "danger" (stv 0.4 0.6)))

(= (strength $a $b) (match &kb (Inheritance $a $b (stv $s $c)) $s))

; strongest-out-of: collect the strengths into one tuple, fold it to a max.
; collapse is NOT a binder on 0.2.10: it takes the whole nondeterministic call as
; a single argument, so the query gets its own rule and collapse wraps the call.
(= (strength-of $a) (match &kb (Inheritance $a $b (stv $s $c)) $s))
(= (strengths $a) (collapse (strength-of $a)))
(= (max-of $t) (foldl-atom $t 0.0 $acc $e (if (< $acc $e) $e $acc)))
(= (believe $a) (max-of (strengths $a)))

!(assertEqualToResult (strength "off-line" "danger") (0.7))
!(assertEqual (believe "off-line") 0.7)
!(assertEqual (believe "lost") 0.4)

; (1) Why not a second (= (strength $a $b) ...) rule? Because every matching rule
; is explored: a "fallback 0.0" rule would return 0.0 *alongside* 0.7, and the
; fold would then take max over a set that includes a lie. Totality has to be
; explicit — see (strength-or-zero) below, which is the safe shape.
(= (strength-or-zero $a $b)
    (let $s (strength $a $b) (if (== $s $s) $s 0.0)))

; (2) The hole, on purpose. Comment out the "dark"/"off-line" add-atom line: the
; fold for (strengths "dark") then sees ONE element instead of two. Nothing
; raises. match with no results prints nothing, so the candidate set silently
; shrinks. The diagnostic is !(collapse (strength-of "dark")) — count the tuple's
; children before you trust the max.

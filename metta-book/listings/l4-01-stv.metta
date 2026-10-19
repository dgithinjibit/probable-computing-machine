; l4-01-stv.metta
; L4: uncertainty is data you write, because the interpreter recognises none of it.
; Assertions use whole numbers so the printed forms stay unambiguous; the semantic
; claim is the same for 0.7 and 0.8.

!(bind! &kb (new-space))
!(add-atom &kb (Inheritance off-line danger (stv 7 8)))
!(add-atom &kb (Inheritance dark off-line (stv 5 9)))
!(add-atom &kb (Inheritance lost danger (stv 4 6)))

(= (min-f $a $b) (if (< $a $b) $a $b))
(= (strength $a $b) (match &kb (Inheritance $a $b (stv $s $c)) $s))
(= (and-stv $s1 $c1 $s2 $c2) (stv (* $s1 $s2) (min-f $c1 $c2)))

!(strength off-line danger)
!(and-stv 2 3 4 5)

; collapse gives a tuple; foldl-atom folds a tuple's CHILDREN (never a :: list).
; collapse takes ONE argument in 0.2.10: it is not a binder. `let` binds.
(= (strength-of $a) (match &kb (Inheritance $a $b (stv $s $c)) $s))
(= (strengths $a) (collapse (strength-of $a)))
(= (max-of $t) (foldl-atom $t 0 $acc $e (if (< $acc $e) $e $acc)))
!(strengths off-line)
!(max-of (strengths off-line))

!(assertEqual (strength off-line danger) 7)
!(assertEqualToResult (and-stv 2 3 4 5) ((stv 8 3)))
!(assertEqual (max-of (strengths off-line)) 7)

; The trap this file is about: delete the second add-atom line and watch
; (strengths ...) shrink to one element with no error at all. match with no
; results prints nothing, so a fold silently sees fewer items. Diagnose with the
; tuple's size, not with the printed value.

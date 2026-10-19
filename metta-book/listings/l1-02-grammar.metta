; l1-02-grammar.metta
; Every line is one top-level atom. `!` is the whole difference between
; "store this" and "run this". Outputs quoted in this file were produced by
; hyperon 0.2.10 on 2026-10-19.

; --- the atom kinds the grammar allows: symbol, string, expression ---
plainSymbol
"a string atom"
(nested (deeper (deepest)) 42)

; --- numbers are grounded atoms, picked by the tokenizer, not by you ---
!(get-type 3)
!(get-type 3.5)
!(get-type -2)
!(get-type three)

; --- head symbols are part of the pattern: this must match exactly ---
(symbol one)
!(match &self (symbol one) found)
!(match &self (slot one) never-matches)

; --- `match` is itself a symbol; writing it without parentheses is a call to
; nothing, and its type shows the three arguments it really wants ---
!(get-type match)

; --- TRAP 1: a bare variable at top level is not data, it is a live variable
; sitting in your space. Store this line and un-comment it:
;   $alone
; then run !(match &self (symbol $x) $x). It answers $x, because the pattern
; unifies with the loose variable instead of with an atom. Keep variables
; inside expressions.
$broken

; --- TRAP 2: comments run to end of line, and # is reserved for the
; interpreter's generated variable names ($t#138). You cannot write $a#b.
;!(get-type $a#b)

; --- TRAP 3: !& is documented as "evaluate and keep the result". This build
; does not parse it: the line below is echoed back as data, and
; !(get-atoms &self) prints nothing. Both are left commented so the file stays
; green.
;!& (+ 1 2)
;!(get-atoms &self)

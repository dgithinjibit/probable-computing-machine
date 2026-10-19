; 05-types.metta
; A type declaration documents and constrains calls; it does not add rules.

(: double (-> Number Number))
(= (double $x) (* 2 $x))
!(double 6)
!(get-type double)
!(get-type (double 6))

; A function with no declaration has the unknown type, and rules still run.
(= (cube $x) (* $x (* $x $x)))
!(cube 2)
!(get-type cube)

; Type variables make a rule generic: $t stands for whatever type the argument
; has, and identity works for numbers and symbols alike.
(: identity (-> $t $t))
(= (identity $x) $x)
!(identity 3)
!(identity three)

; Uncomment the call below to see what a declared type does on a bad argument.
; The runtime answers with an error atom naming the position, the expected
; type and the actual type:
;!(double "six")

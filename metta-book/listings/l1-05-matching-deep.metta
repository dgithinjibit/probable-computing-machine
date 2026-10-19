; 11-matching.metta
; match is the operation MeTTa is built around: search a space, bind variables,
; produce a template.

(isa red color)
(isa green color)
(isa blue color)

; Every matching fact gives one result. Order is not guaranteed.
!(match &self (isa $c color) $c)

; match does not search inside subexpressions. This atom contains a matching
; expression as part of a larger one and is not found:
(top (isa purple color))
!(match &self (isa $c color) $c)

; Variables may appear in the stored atoms too, and a variable in the template
; that is already bound in the pattern is substituted.
(rule (frog $x) (green $x))
!(match &self (rule (frog Sam) $then) $then)
!(match &self (rule ($p $x) (green $x)) ($x is $p))

; A comma pattern is a conjunction: all parts must hold with shared variables.
(frog Sam)
!(match &self (, (frog $x) (rule (frog $x) $y)) $y)

; A pattern with no match produces nothing, which is why "no output" and
; "wrong output" are two different debugging problems.
!(match &self (frog Nobody) $x)

; collapse gathers all results of one query into a single tuple.
!(collapse (match &self (isa $c color) $c))

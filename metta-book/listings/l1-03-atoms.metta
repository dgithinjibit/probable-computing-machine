; 10-atoms.metta
; Atoms are data you can build, take apart and turn into text.

!(get-type foo)
!(get-type $x)
!(get-type (f x))
!(get-type "text")

; Symbols and strings compare differently, so a pattern with a string will not
; find a fact written with a bare symbol.
(role captain)
!(match &self (role $who) $who)

; Build and take apart expressions one child at a time.
!(cons-atom quote (hello world))
!(car-atom (quote hello world))
!(cdr-atom (quote hello world))
!(decons-atom (quote hello world))

; repr turns any atom into a string; parse turns a string back into an atom.
; This is the seed of every "export my AtomSpace" program.
!(repr (score Ada 92))
!(parse "(score Ada 92)")
!(repr "already a string")

; quote and noeval stop evaluation; here noeval keeps a variable unbound inside
; a template.
!(atom-subst (f $x) $x 3)

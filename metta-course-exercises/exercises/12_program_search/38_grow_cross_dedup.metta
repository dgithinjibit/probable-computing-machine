; Exercise 38 — Grow, cross, dedup
; Book: [L7 — Program search](../../../metta-book/src/ch13-l7-moses.md)
;
; Local search on the AND truth table. You may reuse the listing's eval-c, hits,
; rank, nf and size verbatim -- this exercise is about the three operations, not
; about typing them again.
;
; Requirements:
;   1. (grow $p) -- at least five rules. Two of them may share a head with others,
;      and here that is deliberate: `(grow $p)` matching a `(c-and $p $q)` head is
;      how a `c-and` exemplar gets BOTH structural neighbours and extensions. Say in
;      one comment line how you tell deliberate enumeration from the L0 accident.
;   2. (grow-count $p) and (grow-best $p) -- both order-free (count, or a max fold).
;      Assert: count for (var-x) is 2, count for (c-and (var-x) (var-y)) is 5,
;      grow-best for (var-x) is 4.
;   3. (subs $p) -- every subterm, including the whole program. Assert the counts
;      for (var-x), (c-and (var-x) (var-y)) and (c-and (c-not (var-x)) (var-y)).
;   4. (replace $p $old $new) -- ONE head, `case` inside, replacing every
;      occurrence. Assert the two cases where $old is present and the one where it
;      is not (the answer must be the parent unchanged, not silence and not an error).
;   5. (cross $a $b) = (nf (replace $a $s $t)) over every $s in subs $a and every $t
;      in subs $b. Assert the child count is subs(a) * subs(b), and fold a max of
;      (hits $e) over the children.
;   6. Dedup: !(bind! &seen (new-space)), a (note! $p) that stores (s $p) only when
;      it is absent, and (stored) that counts what is in the space. Run it over the
;      listing's seven `cand` facts and assert the distinct count. Get the guard
;      wrong -- match (s $q) instead of (s $p) -- and the whole population collapses
;      to one survivor. Do that ON PURPOSE once, watch the count, then fix it.
;   7. The limit of local search, in three assertions: from (var-x) one deme step
;      reaches 4 hits; from (c-or (var-x) (var-y)) one deme step reaches 3 and no
;      further; cross between those two does not reach 4 either. Explain, in two
;      sentences, which repair you would buy first -- more operators, restarts, or
;      crossover between demes -- and what it costs.
;   8. Order-free habits: assert sum-of-sizes and sum-of-hits over a deme. If you
;      find yourself writing (assertEqualToResult (grow ...) (...)), stop; you have
;      just bet on a result order the interpreter never promised.
;
; Constraints: add-atom, match on a named space, collapse, foldl-atom with a
; let-bound tuple (foldl-atom whose first argument is an un-let expression fails with
; BadArgType, verified), >=, ==, if, case. There is no `member`.

(cand (var-x))
(cand (var-y))
(cand (const-0))
(cand (c-and (var-x) (var-y)))
(cand (c-and (var-y) (var-x)))
(cand (c-not (c-not (c-and (var-x) (var-y)))))
(cand (c-or (var-x) (var-y)))

!(bind! &seen (new-space))

; Your grow / subs / replace / cross / note! / stored rules go here:

;!(assertEqualToResult (grow-count (var-x)) ())
;!(assertEqualToResult (stored) ())
;!(assertEqualToResult (seen-count (c-and (var-y) (var-x))) ())

; Exercise 25 — A counter that actually moves
; Book: metta-book/src/ch08-00-build-a-small-program.md (L2 Unit 2)
;
; Use state for a mutable value and prove the mutation fires exactly once.
; Requirements:
;   1. bind! &ticks as state starting at 0
;   2. define (tick!) that reads the current value and stores the next one
;   3. call (tick!) twice, then assert the state is 2
;
; Trap: if you write two (= (tick!) ...) rules the counter moves by two per
; call. Count before you run. See L1 Unit 3 on same-head rules.

!(bind! &ticks (new-state 0))

; Your rule goes here:
; (= (tick!) ...)

;!(tick!)
;!(assertEqual (get-state &ticks) 1)

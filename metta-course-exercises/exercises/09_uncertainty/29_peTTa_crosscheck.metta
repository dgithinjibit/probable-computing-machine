; Exercise 29 — Cross-check the language against a second implementation
; Book: metta-book/src/appendix-00-offline-workflow.md (Appendix: Offline Workflow)
;
; A SECOND MANUAL LAB, and the only one that needs a runtime this machine does not
; have yet: SWI-Prolog >= 9.3, for ~/Desktop/ex/exercises/peTTa (trueagi-io/PeTTa,
; MIT -- "Efficient MeTTa language implementation in Prolog").
;
; Why this is worth an hour: every surprising hyperon answer is either "the
; language says that" or "this build does that". PeTTa is a second implementation
; of the same spec, so when the two disagree you have found a bug report instead of
; a mystery -- and PeTTa typechecks (: f (-> A B)) at compile time and, under
; --strict, refuses overlapping clauses for a deterministic function. That is the
; exact bug class that made this book's own lowering exercise wrong.
;
; Install first, in your own terminal (privileged, so not an agent's job):
;     sudo apt update && sudo apt install swipl
; Then, ONE example at a time -- never peTTa's test.sh on a 4 GB laptop, it fans
; out eight SWI instances with 3 GB stacks by design:
;     cd ~/Desktop/ex/exercises/peTTa
;     PETTA_STACK_LIMIT=512m sh run.sh ./examples/nars_tuffy.metta
;
; Task: run each snippet below through BOTH interpreters and fill the table.
;
;   hyperon:  cd /tmp && metta file.metta
;   peTTa:    PETTA_STACK_LIMIT=512m sh run.sh /tmp/file.metta
;
;   1. two same-head rules    (= (num) 1) (= (num) 2)   !(num)
;   2. collapse arity          (= (coin) heads) (= (coin) tails)  !(collapse (coin))
;      and the wrong form      !(collapse $r (coin))
;   3. fold over a query       (= (t) (foldl-atom (collapse (num)) 0 $a $e (+ $a 1)))  !(t)
;      versus the let form      (= (t) (let $x (collapse (num)) (foldl-atom $x 0 $a $e (+ $a 1))))
;   4. overlapping clauses     (= (lower (mul $a $b)) (:mul $a $b)) (= (lower $x) (:ld $x))
;      -- in hyperon this multiplies; does peTTa --strict reject it?
;   5. a typed call error      (: half (-> Number Number)) (= (half $x) (/ $x 2)) !(half "six")
;
; Record, per row: hyperon's output, peTTa's output, and which one the spec in
; hyperon-experimental/docs/metta.md supports. Three columns of agreement is a
; lesson; one column of disagreement is an issue you can file, with two minimal
; reproductions attached. Either way you have learned something the first
; implementation alone cannot teach you: whether a behaviour is language or build.

(= (num) 1)
(= (num) 2)

; Nothing below is asserted, because nothing here is solvable without a second
; runtime -- this file is a lab sheet, and it stays silent on purpose so the
; verifier never counts it as a failure.

; Solution 26 — Two coins, four results
(= (coin) heads)
(= (coin) tails)
(= (pair $a $b) (ab $a $b))

; Prediction: 4 results, because 2 x 2. Confirmed by the assertion below.
!(assertEqualToResult (pair (coin) (coin))
    ((ab heads heads) (ab heads tails) (ab tails heads) (ab tails tails)))
!(assertEqualToResult (coin) (heads tails))
!(assertEqualToResult (collapse (coin)) ((heads tails)))

; collapse is ONE-argument on this build. To bind each result in turn you use
; `let`, which is where the multiplicity actually comes from:
!(assertEqualToResult (let $a (coin) (let $b (coin) (ab $a $b)))
    ((ab heads heads) (ab heads tails) (ab tails heads) (ab tails tails)))

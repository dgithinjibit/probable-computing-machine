; Solution 26 — Two coins, four results
(= (coin) heads)
(= (coin) tails)
(= (pair $a $b) (ab $a $b))

; Prediction: 4 results, because 2 x 2. Confirmed by the assertion below.
!(assertEqualToResult (pair (coin) (coin))
    ((ab heads heads) (ab heads tails) (ab tails heads) (ab tails tails)))
!(assertEqualToResult (coin) (heads tails))
!(assertEqualToResult (collapse $r (coin)) ((heads tails)))

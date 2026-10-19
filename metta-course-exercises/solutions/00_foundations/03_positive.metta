(: positive (-> Number Bool))
(= (positive $n) (> $n 0))

!(assertEqual (positive 4) True)
!(assertEqual (positive 0) False)
!(assertEqual (positive -2) False)

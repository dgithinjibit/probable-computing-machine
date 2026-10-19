(: fibonacci (-> Number Number))
(: fibonacci-from (-> Number Number Number Number))
(= (fibonacci $n) (fibonacci-from $n 0 1))
(= (fibonacci-from $remaining $current $next)
    (if (== $remaining 0)
        $current
        (fibonacci-from (- $remaining 1) $next (+ $current $next))))

!(assertEqual (fibonacci 0) 0)
!(assertEqual (fibonacci 1) 1)
!(assertEqual (fibonacci 6) 8)
!(assertEqual (fibonacci 10) 55)

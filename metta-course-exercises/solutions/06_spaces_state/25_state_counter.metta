; Solution 25 — A counter that actually moves
; One rule only. A second same-head rule would double every tick.
!(bind! &ticks (new-state 0))

(= (tick!) (change-state! &ticks (+ (get-state &ticks) 1)))

!(tick!)
!(assertEqual (get-state &ticks) 1)
!(tick!)
!(assertEqual (get-state &ticks) 2)

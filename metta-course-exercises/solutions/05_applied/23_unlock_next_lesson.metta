; Exercise 23 — Unlock the next lesson
(prerequisite python-basics ml-intro)
(prerequisite ml-intro retrieval)
(completed python-basics)

(= (unlocked $lesson)
    (match &self
        (prerequisite $done $lesson)
        (match &self (completed $done) $lesson)))

!(assertEqualToResult (unlocked $lesson) (ml-intro))

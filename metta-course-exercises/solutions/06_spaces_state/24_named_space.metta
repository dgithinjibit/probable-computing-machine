; Solution 24 — A space you can inspect
!(bind! &map (new-space))

!(add-atom &map (room kitchen))
!(add-atom &map (room hall))
!(add-atom &map (room pantry))
!(add-atom &map (connects kitchen hall))
!(add-atom &map (connects kitchen pantry))

(= (adjacent $a) (match &map (connects $a $b) $b))

!(assertEqualToResult (adjacent kitchen) (hall pantry))
!(assertEqualToResult (match &map (room $r) $r) (kitchen hall pantry))
; "no results" is asserted against (), not against Empty: Empty as an expected
; value is itself a type error on this build (verified 2026-10-19).
!(assertEqualToResult (adjacent hall) ())

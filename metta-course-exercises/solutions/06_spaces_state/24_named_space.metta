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
!(assertEqualToResult (adjacent hall) Empty)

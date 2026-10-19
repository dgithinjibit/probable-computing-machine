(parent Ada Bea)
(parent Ada Cy)
(parent Bea Dee)

!(assertEqualToResult
    (match &self (parent Ada $child) $child)
    (Bea Cy))

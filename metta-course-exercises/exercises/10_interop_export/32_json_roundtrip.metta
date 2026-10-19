; Exercise 32 — Getting data in and out
; Book: metta-book/src/ch11-l5-interop-and-export.md (L5)
;
; Requirements:
;   1. import the json module the way this build accepts it (bare name; @metta::json
;      is rejected as "Invalid module name format")
;   2. decode the JSON array [1, 2, 3] into MeTTa and assert the atoms
;   3. build a (day-summary $mode $readings $events) tuple and encode it
;   4. write a text file under /tmp and read it back, asserting the round trip
;
; Known constraints from the fact sheet: json-encode of a dict wants STRING keys,
; symbols come out in a "sym!:a" form, and a decoded object gives you a
; GroundingSpace handle rather than a structure. Build the shape on the MeTTa side
; first; json is the last mile.

!(import! &self json)
!(import! &self fileio)

;!(assertEqualToResult (json-decode "[1, 2, 3]") ((1 2 3)))

; Your rules go here:

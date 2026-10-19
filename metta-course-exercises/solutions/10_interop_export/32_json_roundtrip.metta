; Solution 32 — Getting data in and out
!(import! &self json)
!(import! &self fileio)

; Decoding an array is the verified direction: JSON list -> MeTTa tuple.
!(assertEqualToResult (json-decode "[1, 2, 3]") ((1 2 3)))

; Encoding a summary. Keys must be strings on this build; a symbol key comes out
; in a "sym!:a" form, which is not what a reader expects. Print rather than assert,
; because the exact spacing of the encoder is its business, not yours.
(= (summary) (dict-space "mode" "driving" "readings" (120 118 96)))
!(json-encode (summary))

; Round-trip a file. The handle and mode strings below are the shapes verified on
; 0.2.10 (open with "wc" = write/create); if your build wants a different mode
; string, read the fileio module's own declarations rather than guessing.
!(bind! &h (file-open! "/tmp/metta_day.txt" "wc"))
!(file-write! &h "mode=driving events=3")
!(assertEqual (file-read-to-string! &h) "mode=driving events=3")

; If the two fileio lines behave differently on your build, comment them and keep
; the json-decode assertion: that one is the claim this file is actually making.

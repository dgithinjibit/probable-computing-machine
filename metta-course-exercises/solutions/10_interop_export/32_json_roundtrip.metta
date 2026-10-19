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

; Round-trip a file, verified on 0.2.10 the hard way. You cannot read back through
; the handle you wrote with -- that returns
;   (Error (file-read-to-string! FileHandle-...) Failed to read file contents: Bad file descriptor)
; so open a SECOND handle in "r" mode. And there is no file-close! in this build:
; the call is not an error, it is echoed back unevaluated, which is the worst kind
; of silence because the file is still half-open while your assertion is green.
!(bind! &w (file-open! "/tmp/metta_day.txt" "wc"))
!(file-write! &w "mode=driving events=3")
!(bind! &r (file-open! "/tmp/metta_day.txt" "r"))
!(assertEqual (file-read-to-string! &r) "mode=driving events=3")

; If the fileio lines behave differently on your build, comment them and keep the
; json-decode assertion: that one is the claim this file is actually making.

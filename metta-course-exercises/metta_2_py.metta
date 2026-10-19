;declare type: is-pass takes number, return bool
is-pass(-> number bool)

;tell Metta: this symbol is actually Python function
!(bind! &py (py-atom dict))

;The simple way in hyperon you just use ground op
    (is-pas $mark) (> $mark 50))
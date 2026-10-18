# Blockchain Hybrid Course (branch of the hybrid book-course system)

Fourteen ordered days built from the blockchain books on this laptop plus the four
code courses that already sit beside them. Same engine as `ml-hybrid/` and
`hakin-hybrid/` — read [`../ml-hybrid/README.md`](../ml-hybrid/README.md) for how the
build system works. This file only records what is specific to this branch.

## Open it

```bash
cd ~/Desktop/ex && ./exercises/serve-site.sh    # http://127.0.0.1:8000/blck-hybrid/hybrid-course.html
```

## What the fourteen days are made of

| Book | Used for | Real anchor pages |
|---|---|---|
| _Mastering Blockchain_ (Lantz & Cawrey) | the conceptual spine: origins, fundamentals, Ethereum, tokens, DeFi, privacy, other chains | located with `python3 build_course.py locate`: ch1 p.24, ch2 p.41, ch3 p.77, ch4 p.97, ch5 p.121, ch6 p.141, ch7 p.173, ch8 p.207, ch9 p.229, ch10 p.249 |
| _Blockchain: The Comprehensive Guide_ (Fertig & Schütz, 1290pp) | EVM internals, writing/deploying contracts, contract security | ch2 pp.113–173, ch7 pp.408–435, ch9 pp.464–513, ch15 pp.739–784 |
| _Bitcoin Programming_ (Karasavvas, **CC BY-SA 4.0**) | how Bitcoin works, keys and addresses | ch1 pp.8–29, ch5 pp.43–92 |
| _Bitcoin and Cryptocurrency Technologies_ (Princeton, 26pp **excerpt** of ch.1 only) | hash functions and signatures — the math everything rests on | §1.1 starts physical p.2 |

The code courses are not extracted; they are pointed at, because their value is the
code and they are already yours:

- `../sui-move-intro-course/` — unit-one lessons 1–5 and `exercises/unit-one/`, `unit-two/`
  ownership and wrapping, `exercises/unit-four/` with `locked_coin_df.move` as reference.
- `../scrypto-challenges/` — `1-exchanges/CandyDex/` (read the resource types in
  `src/lib.rs`), `2-oracles/`, `3-lending/`.
- `../starklings/` — `exercises/intro/intro1.cairo`, `intro2.cairo`, then `primitive_types/`.
- `../cairo-book/` — `src/ch01-03-proving-a-prime-number.md` for why a program can be proved.
- `../security-exercises/` — reused on Days 2, 3, 5, 12 and 13: hashing, secret redaction,
  log review, and the severity/report exercises are the same skills in a different costume.

## Deliberate limits

- **No toolchain claims.** `sui`, `scrypto`, `cargo`, `scarb` and any wallet are not
  installed here and this laptop is offline for installs, so the days that would need
  them ask you to read real source and record what you could not verify. Nothing in this
  branch asks you to generate keys or move funds.
- **Copyright.** Only `Bitcoin Programming` is freely licensed (CC BY-SA). The rest is
  extracted locally for personal study, and the generated pages are `.gitignore`d, so the
  pushed repo carries the curriculum and the tooling, not the publishers' text.
- **Princeton file is an excerpt.** 26 pages, chapter 1 only. It is cited as such on Day 3.

## Change it

`hybrid-curriculum.json` is the source of truth. Add a day as one JSON entry, then
`python3 build_course.py build && ../../tools/mdbook/bin/mdbook build`.

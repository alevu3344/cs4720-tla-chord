# CS4720 TLA+ Chord Model

This repository contains a TLA+ model of the static Chord lookup protocol for
CS4720 Research in Software Analysis, project variant A.

Report draft:
https://www.overleaf.com/project/6a0357b148b03f2bd71e5f1e

## Query Abstraction

The variable `queries` is a global set of lookup records:

```tla
[origin |-> n, target |-> k, curr |-> n, result |-> NoResult]
```

- `origin`: node that started the lookup.
- `target`: key being resolved.
- `curr`: node currently handling the lookup.
- `result`: `NoResult` while unresolved, otherwise the resolved successor node.

This abstracts away concrete RPC messages. Each `AdvanceQuery` step represents
one lookup hop in the Chord paper's `find_successor` flow.

## Correctness Properties

The configs currently verify:

- `TypeOK`: all mutable state has the expected shape.
- `LookupCorrect`: every completed lookup resolves to `TrueSucc(target)`,
  the mathematically correct Chord successor for the static ring.

## Running TLC

Use the TLA+ Toolbox, the VS Code TLA+ extension, the `tlc` command, or
`tla2tools.jar`.

With the `tlc` command:

```sh
tlc -config ChordStatic.cfg ChordStatic.tla
tlc -config configs/static-m2-basic.cfg ChordStatic.tla
tlc -config configs/static-m3-one-query.cfg ChordStatic.tla
tlc -config configs/static-m3-wrap-one-query.cfg ChordStatic.tla
```

With `tla2tools.jar` from PowerShell:

```powershell
$env:TLA2TOOLS_JAR = "C:\path\to\tla2tools.jar"
java -cp $env:TLA2TOOLS_JAR tla2sany.SANY ChordStatic.tla
java -cp $env:TLA2TOOLS_JAR tlc2.TLC -config ChordStatic.cfg ChordStatic.tla
```

The default config uses:

```tla
M = 2
Nodes = {0, 2}
```

## Current TLC Results

| Config | Purpose | Result | Distinct states | Depth |
| --- | --- | --- | ---: | ---: |
| `ChordStatic.cfg` | default static configuration | passed | 20,736 | 21 |
| `configs/static-m2-basic.cfg` | basic static configuration | passed | 20,736 | 21 |
| `configs/static-m3-one-query.cfg` | three-node ring, one query at a time | passed | 67 | 5 |
| `configs/static-m3-wrap-one-query.cfg` | sparse wraparound ring, one query at a time | passed | 65 | 4 |

Unconstrained `M = 3` configs with all query records enabled grow into millions
of states, so larger verification runs should use `OneQueryConstraint` or a more
compact query abstraction.

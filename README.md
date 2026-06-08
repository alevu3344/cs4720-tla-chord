# CS4720 TLA+ Chord Model

This repository contains TLA+ models of the Chord protocol for CS4720 Research
in Software Analysis, project variant A.

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

## Dynamic Join Abstraction

`ChordDynamic.tla` models dynamic transitions:

- `Join(n)`: a configured joining node enters the active ring.
- `Stabilize(n)`: a node consults its successor's predecessor and sends an
  asynchronous notification.
- `DeliverNotify(msg)`: a notification message is delivered nondeterministically
  from the global `notifyMsgs` set.
- `FixFingers(n)`: a node repairs one finger-table slot and advances
  `nextFinger[n]`.

The dynamic model keeps the same bounded identifier-ring abstraction as the
static model. `notifyMsgs` abstracts RPC delivery and permits out-of-order
notification handling. In the Chord paper, a joining node asks a known contact
node to route `find_successor`. Here, `Join` directly uses the mathematical
successor in the active ring, while the static model separately covers
lookup-hop behavior. Consequently, the dynamic model does not capture a join
lookup being delayed, misrouted by stale routing information, or failing.

Dynamic configs enable deadlock checking because active nodes can always run
periodic stabilization or finger repair. Static configs disable it because their
bounded lookup experiments intentionally reach terminal completed states.

The liveness property is:

```tla
EventuallyStableAfterJoins == AllJoinsDone ~> StableRing
```

`Spec` adds weak fairness for each configured join, each node's `stabilize` and
`fix_fingers` actions, and each concrete notification message. 
Run the dynamic configs with:

```sh
tlc -config ChordDynamic.cfg ChordDynamic.tla
tlc -config configs/dynamic-m3-one-join.cfg ChordDynamic.tla
tlc -config configs/dynamic-m3-one-join-invariant.cfg ChordDynamic.tla
```

## Current Dynamic TLC Results

| Config | Purpose | Result | Distinct states | Depth |
| --- | --- | --- | ---: | ---: |
| `ChordDynamic.cfg` | one join with liveness | passed | 6,516 | 21 |
| `configs/dynamic-m3-one-join.cfg` | one join with liveness | passed | 6,516 | 21 |
| `configs/dynamic-m3-one-join-invariant.cfg` | one join, invariant only | passed | 6,516 | 21 |

The completed one-join runs also passed deadlock checking. The two-join
invariant reached more than 2,000,000 distinct states before completion and
must be rerun after the latest model changes.

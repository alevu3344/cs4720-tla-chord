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

| Config | Properties checked | Result | States generated | Distinct states | Depth | Runtime |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| `ChordStatic.cfg` | `TypeOK`; `LookupCorrect` | passed | 117,505 | 20,736 | 21 | 02s |
| `configs/static-m2-basic.cfg` | `TypeOK`; `LookupCorrect` | passed | 117,505 | 20,736 | 21 | 02s |
| `configs/static-m3-one-query.cfg` | `TypeOK`; `LookupCorrect` | passed | 1,585 | 67 | 5 | 01s |
| `configs/static-m3-wrap-one-query.cfg` | `TypeOK`; `LookupCorrect` | passed | 1,537 | 65 | 4 | 01s |

Unconstrained `M = 3` configs with all query records enabled grow into millions
of states, so larger verification runs should use `OneQueryConstraint` or a more
compact query abstraction.

The static configs disable TLC deadlock checking because query records are
retained after completion. Once the bounded workload has resolved, no further
transition is expected; this terminal state represents completion rather than a
protocol deadlock.

For a representative wraparound lookup with `M = 3` and
`Nodes = {1, 4, 6}`, a query from node `1` for target `0` is forwarded to node
`6`, which resolves it to successor node `1`.

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
tlc -config configs/dynamic-m3-two-joins-invariant.cfg ChordDynamic.tla
tlc -config configs/dynamic-m3-two-joins.cfg ChordDynamic.tla
```

## Current Dynamic TLC Results

| Config | Properties checked | Result | States generated | Distinct states | Depth | Runtime |
| --- | --- | --- | ---: | ---: | ---: | ---: |
| `configs/dynamic-m3-one-join.cfg` | `TypeOK`; deadlock; `EventuallyStableAfterJoins` | passed | 51,409 | 6,516 | 21 | 01s |
| `ChordDynamic.cfg` | `TypeOK`; deadlock; `EventuallyStableAfterJoins` | passed | 51,409 | 6,516 | 21 | 01s |
| `configs/dynamic-m3-one-join-invariant.cfg` | `TypeOK`; deadlock | passed | 51,409 | 6,516 | 21 | 00s |
| `configs/dynamic-m3-two-joins-invariant.cfg` | `TypeOK`; deadlock | passed | 25,309,837 | 2,345,796 | 35 | 49s |
| `configs/dynamic-m3-two-joins.cfg` | `TypeOK`; deadlock; `EventuallyStableAfterJoins` | passed | 25,309,837 | 2,345,796 | 35 | 21min 33s |

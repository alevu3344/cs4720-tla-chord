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

## Running The Smoke Test

Use the TLA+ Toolbox, the VS Code TLA+ extension, or `tla2tools.jar`.

With `tla2tools.jar` from PowerShell:

```powershell
$env:TLA2TOOLS_JAR = "C:\path\to\tla2tools.jar"
java -cp $env:TLA2TOOLS_JAR tla2sany.SANY ChordStatic.tla
java -cp $env:TLA2TOOLS_JAR tlc2.TLC -config ChordStatic.cfg ChordStatic.tla
```

The checked-in config uses:

```tla
M = 2
Nodes = {0, 2}
```

# Configuration Layout

The root configs are the canonical small defaults:

- `ChordStatic.cfg`: two-node static ring with the full bounded query workload.
- `ChordDynamic.cfg`: one join with safety, deadlock, and liveness checking.

Additional configs are grouped by purpose:

- `coverage/`: property-free action-coverage runs for SysMoBench.
- `examples/`: targeted examples that are useful outside the experiment matrix.
- `evaluation/dynamic/`: controlled join matrix for Phase 3.
- `evaluation/lookup/`: finger-table versus successor-only routing baselines.
- `evaluation/workload/`: query-workload abstraction baseline.

Evaluation filenames encode `M`, final node count `N`, join count `J`, and
verification mode where applicable. For example,
`evaluation/dynamic/m3-n4-j2-temporal.cfg` uses `M=3`, finishes with four
active nodes, allows two joins, and checks temporal convergence.

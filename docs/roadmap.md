# Project Roadmap

## 🗓️ Phase 1: Protocol Analysis, Abstraction, & Static Model

**Goal:** Understand the Chord paper, define a strictly scoped abstraction, and build a static TLA+ model of the Chord ring with working lookups.

### Daniel — Modeler

- Define the global states in TLA+:
  - Identifier ring using modulo arithmetic.
  - Active nodes.
  - Variables for successor, predecessor, and finger tables.
- Implement the base TLA+ transitions for a static ring with no joins yet:
  - Write the logic for `find_successor`.
  - Write the logic for `closest_preceding_finger`.
  - Base these on Figure 4 in the Chord paper.

### Alessandro — Verifier

- Set up the TLA+ Toolbox and TLC Model Checker.
- Define the initial safety property:
  - In a stable ring, every key `k` must resolve to the correct node, meaning the first node `>= k`.
- Run TLC on the static model to ensure lookups work correctly without deadlocks.

### Vincent — Evaluator & Scribe

- Draft Phase 1 requirements:
  - Project objective.
  - Study design.
  - Feasibility assessment.
- Rubric target: **Related Work — 10 pts**
  - Start researching 5+ related works to compare against Chord for the final report.
  - Examples:
    - Pastry
    - Kademlia
    - CAN
    - Apache Cassandra

## 🗓️ Phase 2: Dynamic Transitions, Liveness, & Model Checking

**Goal:** Introduce dynamic behavior with nodes joining, stabilize the ring, and run complex model checking.

### Alessandro — Modeler

- Implement the dynamic transitions from Figure 7 in the Chord paper:
  - `join(n')`
  - `stabilize()`
  - `notify()`
  - `fix_fingers()`
- Model the non-determinism of distributed systems:
  - Nodes can call `stabilize()` at any random time.
  - Network messages might arrive out of order.

### Vincent — Verifier

- Define liveness properties:
  - If a node joins, eventually all other nodes’ finger tables will correctly reflect the new node.
  - Use TLA+ temporal logic, such as `~>`.
- Run the TLC Model Checker on the dynamic model.
- Expect state explosions or deadlocks.
- Restrict the state space, for example:
  - Limit the number of joining nodes to 2.
- Start integrating SysMoBench quality metrics to analyze the model.

### Daniel — Evaluator & Scribe

- Rubric target: **Evaluation Setup — 5 pts**
  - Document the testing environment.
  - Document tools used, including TLA+ version and TLC parameters.
  - Justify why specific constants were chosen, such as `m = 3`.
- Begin writing the **Formal Modeling** section of the final report.
- Detail the model abstractions, for example:
  - How the model handles the absence of real IP addresses in TLA+.

## 🗓️ Phase 3: Performance Analysis, Baselines, & Final Report

**Goal:** Gather empirical data across different configurations, finalize the code, write the README, and polish the ACM report.

### Vincent — Modeler

- Rubric target: **Source Code — 5 pts**
  - Clean up the TLA+ code.
  - Add extensive comments explaining every transition.
  - Explain how each transition maps to the Chord paper.
  - Ensure the code exceeds minimal functionality.
- Write the **Limitations** section of the report.
- Discuss assumptions made, for example:
  - Why failures were not modeled.

### Daniel — Verifier

- Rubric target: **Empirical Evaluation — 20 pts**
  - Run TLC on different configurations, for example:
    - `N = 3` nodes vs. `N = 5` nodes.
    - Different `m` sizes.
  - Measure model checking performance:
    - Time to verify.
    - Number of distinct states.
  - Compare results against a baseline, for example:
    - A brute-force broadcast lookup model.
    - SysMoBench baselines.
  - Generate graphs and tables for the report.

### Alessandro — Evaluator & Scribe

- Rubric target: **README & Reproducibility — 5 pts**
  - Write a flawless README with step-by-step instructions on how to build, configure, and run the TLC Model Checker.
  - Ensure the README allows others to reproduce the results.
- Compile the final 4–8 page ACM double-column report.
- Ensure all 7 mandatory sections are included:
  - Introduction
  - Modeling
  - Correctness/Verification
  - Limitations
  - Related Work
  - GenAI Use
  - References
- Strengthen the argumentation for design choices.
- Prepare for presentation Q&A.

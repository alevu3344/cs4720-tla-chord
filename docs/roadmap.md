# Project Roadmap

## 🎭 Team Roles

To ensure even distribution, assign the following lead roles, though everyone will collaborate:

- **Member 1 — The Modeler:** Focuses on translating Chord’s pseudo-code, math, ring topology, and finger tables into TLA+ syntax.
- **Member 2 — The Verifier:** Focuses on defining invariants, liveness/safety properties, running the TLC Model Checker, and SysMoBench integration.
- **Member 3 — The Evaluator & Scribe:** Focuses on experimental setup, testing different parameters, comparing to baselines/related work, and assembling the ACM report.

## 🗓️ Week 1: Protocol Analysis, Abstraction, & Static Model

**Goal:** Understand the Chord paper, define a strictly scoped abstraction, and build a static TLA+ model of the Chord ring with working lookups.

### Team Discussion: Scope Definition

- Crucial for Variant A: Do not model the whole protocol.
- Restrict your identifier space, for example `m = 3`, meaning 8 possible IDs.
- Model base lookups, `join()`, and `stabilize()`.
- Ignore node failures and departures for now.
- Decide how to abstract network messages, for example:
  - Use a global message set.
  - Use shared variables instead of actual RPCs.

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
- Run TLC on Daniel’s static model to ensure lookups work correctly without deadlocks.

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

## 🗓️ Week 2: Dynamic Transitions, Liveness, & Model Checking

**Goal:** Introduce dynamic behavior with nodes joining, stabilize the ring, and run complex model checking.

### Member 1 — Modeler

- Implement the dynamic transitions from Figure 7 in the Chord paper:
  - `join(n')`
  - `stabilize()`
  - `notify()`
  - `fix_fingers()`
- Design challenge:
  - Model the non-determinism of distributed systems.
  - For example:
    - Nodes can call `stabilize()` at any random time.
    - Network messages might arrive out of order.

### Member 2 — Verifier

- Define liveness properties:
  - If a node joins, eventually all other nodes’ finger tables will correctly reflect the new node.
  - Use TLA+ temporal logic, such as `~>`.
- Run the TLC Model Checker on the dynamic model.
- Expect state explosions or deadlocks.
- Work with Member 1 to restrict the state space, for example:
  - Limit the number of joining nodes to 2.
- Start integrating SysMoBench quality metrics to analyze the model as required by the prompt.

### Member 3 — Evaluator & Scribe

- Rubric target: **Evaluation Setup — 5 pts**
  - Document the testing environment.
  - Document tools used, including TLA+ version and TLC parameters.
  - Justify why specific constants were chosen, such as `m = 3`.
- Begin writing the **Formal Modeling** section of the final report.
- Detail the abstractions made by Member 1 and Member 2, for example:
  - How the model handles the absence of real IP addresses in TLA+.

## 🗓️ Week 3: Performance Analysis, Baselines, & Final Report

**Goal:** Gather empirical data across different configurations, finalize the code, write the README, and polish the ACM report.

### Member 1 — Modeler

- Rubric target: **Source Code — 5 pts**
  - Clean up the TLA+ code.
  - Add extensive comments explaining every transition.
  - Explain how each transition maps to the Chord paper.
  - Ensure the code exceeds minimal functionality.
- Write the **Limitations** section of the report.
- Discuss assumptions made, for example:
  - Why failures were not modeled, if left out.

### Member 2 — Verifier

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

### Member 3 — Evaluator & Scribe

- Rubric target: **README & Reproducibility — 5 pts**
  - Write a flawless README with step-by-step instructions on how to build, configure, and run the TLC Model Checker.
  - Ensure the README allows others to reproduce Member 2’s results.
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

## 💡 Key Advice for High Marks

### 1. Threats to Validity — 10 pts

- Explicitly discuss what real-world Chord behaviors the TLA+ model fails to capture.
- Examples:
  - Network partitions.
  - Malicious nodes.
  - Node failures.
  - Node departures.
  - Message loss or delays.
- Explain how these omissions affect the conclusions.

### 2. Related Work — 10 pts

- Do not skip this section.
- The rubric explicitly asks for 5+ related works.
- Compare the pros and cons of Chord to protocols such as:
  - PBFT
  - Raft
  - Pastry
  - Kademlia
  - CAN
- Focus especially on verification complexity.

### 3. Reproducibility — 5 pts

- Graders will try to run the TLA+ code.
- If the code errors on load, easy points are lost.
- Provide a zipped repository with:
  - `.tla` files
  - `.cfg` files
  - Exact steps to run them in the TLA+ Toolbox
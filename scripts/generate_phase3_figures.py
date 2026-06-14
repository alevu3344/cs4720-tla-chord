import argparse
import csv
from pathlib import Path

import matplotlib.pyplot as plt


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def save_figure(fig: plt.Figure, output: Path, name: str) -> None:
    output.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    fig.savefig(output / f"{name}.png", bbox_inches="tight", dpi=200)
    plt.close(fig)


def dynamic_figures(rows: list[dict[str, str]], output: Path) -> None:
    dynamic = [row for row in rows if row["category"] == "dynamic_matrix"]
    scenarios = list(dict.fromkeys(row["scenario"] for row in dynamic))
    labels = {
        "M2-N3-J1": "M=2, N=3, J=1",
        "M3-N3-J1": "M=3, N=3, J=1",
        "M3-N4-J1": "M=3, N=4, J=1",
        "M3-N4-J2": "M=3, N=4, J=2",
    }

    invariant = {
        row["scenario"]: row
        for row in dynamic
        if row["verification_mode"] == "invariant"
    }
    temporal = {
        row["scenario"]: row
        for row in dynamic
        if row["verification_mode"] == "temporal"
    }

    fig, ax = plt.subplots(figsize=(6.8, 3.4))
    ax.bar(
        [labels[item] for item in scenarios],
        [int(invariant[item]["distinct_states"]) for item in scenarios],
        color="#2f6f8f",
    )
    ax.set_yscale("log")
    ax.set_ylabel("Distinct states (log scale)")
    ax.set_xlabel("Dynamic configuration")
    ax.grid(axis="y", which="both", alpha=0.25)
    ax.tick_params(axis="x", rotation=18)
    save_figure(fig, output, "dynamic-state-growth")

    x = range(len(scenarios))
    width = 0.36
    fig, ax = plt.subplots(figsize=(6.8, 3.4))
    ax.bar(
        [value - width / 2 for value in x],
        [float(invariant[item]["wall_seconds"]) for item in scenarios],
        width,
        label="Invariant only",
        color="#2f6f8f",
    )
    ax.bar(
        [value + width / 2 for value in x],
        [float(temporal[item]["wall_seconds"]) for item in scenarios],
        width,
        label="Temporal",
        color="#c75b39",
    )
    ax.set_yscale("log")
    ax.set_ylabel("Wall-clock time in seconds (log scale)")
    ax.set_xticks(list(x), [labels[item] for item in scenarios], rotation=18)
    ax.set_xlabel("Dynamic configuration")
    ax.legend(frameon=False)
    ax.grid(axis="y", which="both", alpha=0.25)
    save_figure(fig, output, "dynamic-runtime")

    fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.0))
    axes[0].bar(
        [labels[item] for item in scenarios],
        [int(invariant[item]["distinct_states"]) for item in scenarios],
        color="#2f6f8f",
    )
    axes[0].set_yscale("log")
    axes[0].set_ylabel("Distinct states (log scale)")
    axes[0].set_title("(a) State-space growth")
    axes[0].grid(axis="y", which="both", alpha=0.25)
    axes[0].tick_params(axis="x", rotation=25)

    axes[1].bar(
        [value - width / 2 for value in x],
        [float(invariant[item]["wall_seconds"]) for item in scenarios],
        width,
        label="Invariant only",
        color="#2f6f8f",
    )
    axes[1].bar(
        [value + width / 2 for value in x],
        [float(temporal[item]["wall_seconds"]) for item in scenarios],
        width,
        label="Temporal",
        color="#c75b39",
    )
    axes[1].set_yscale("log")
    axes[1].set_ylabel("Wall time in seconds (log scale)")
    axes[1].set_xticks(list(x), [labels[item] for item in scenarios], rotation=25)
    axes[1].set_title("(b) Verification runtime")
    axes[1].legend(frameon=False, fontsize=8)
    axes[1].grid(axis="y", which="both", alpha=0.25)
    save_figure(fig, output, "dynamic-evaluation")


def baseline_figures(rows: list[dict[str, str]], output: Path) -> None:
    lookup = [row for row in rows if row["category"] == "lookup_baseline"]
    scenarios = list(dict.fromkeys(row["scenario"] for row in lookup))
    finger = {
        row["scenario"]: row for row in lookup if row["routing_mode"] == "finger"
    }
    linear = {
        row["scenario"]: row
        for row in lookup
        if row["routing_mode"] == "successor-only"
    }
    x = range(len(scenarios))
    width = 0.36
    fig, ax = plt.subplots(figsize=(5.8, 3.2))
    ax.bar(
        [value - width / 2 for value in x],
        [int(finger[item]["depth"]) - 2 for item in scenarios],
        width,
        label="Finger routing",
        color="#2f6f8f",
    )
    ax.bar(
        [value + width / 2 for value in x],
        [int(linear[item]["depth"]) - 2 for item in scenarios],
        width,
        label="Successor only",
        color="#c75b39",
    )
    ax.set_ylabel("Maximum modeled lookup hops")
    ax.set_xticks(list(x), ["4 nodes", "8 nodes"])
    ax.set_xlabel("Static ring size")
    ax.legend(frameon=False)
    ax.grid(axis="y", alpha=0.25)
    save_figure(fig, output, "lookup-baseline-depth")

    workload = [row for row in rows if row["category"] == "workload_baseline"]
    workload.sort(key=lambda row: row["one_query_constraint"])
    fig, ax = plt.subplots(figsize=(4.8, 3.2))
    ax.bar(
        ["Unconstrained", "At most one query"],
        [
            int(
                next(
                    row["distinct_states"]
                    for row in workload
                    if row["one_query_constraint"] == "no"
                )
            ),
            int(
                next(
                    row["distinct_states"]
                    for row in workload
                    if row["one_query_constraint"] == "yes"
                )
            ),
        ],
        color=["#c75b39", "#2f6f8f"],
    )
    ax.set_yscale("log")
    ax.set_ylabel("Distinct states (log scale)")
    ax.grid(axis="y", which="both", alpha=0.25)
    save_figure(fig, output, "query-constraint-baseline")

    fig, axes = plt.subplots(1, 2, figsize=(7.2, 3.0))
    axes[0].bar(
        [value - width / 2 for value in x],
        [int(finger[item]["depth"]) - 2 for item in scenarios],
        width,
        label="Finger routing",
        color="#2f6f8f",
    )
    axes[0].bar(
        [value + width / 2 for value in x],
        [int(linear[item]["depth"]) - 2 for item in scenarios],
        width,
        label="Successor only",
        color="#c75b39",
    )
    axes[0].set_ylabel("Maximum lookup hops")
    axes[0].set_xticks(list(x), ["4 nodes", "8 nodes"])
    axes[0].set_title("(a) Lookup baseline")
    axes[0].legend(frameon=False, fontsize=8)
    axes[0].grid(axis="y", alpha=0.25)

    axes[1].bar(
        ["Unconstrained", "One query"],
        [
            int(
                next(
                    row["distinct_states"]
                    for row in workload
                    if row["one_query_constraint"] == "no"
                )
            ),
            int(
                next(
                    row["distinct_states"]
                    for row in workload
                    if row["one_query_constraint"] == "yes"
                )
            ),
        ],
        color=["#c75b39", "#2f6f8f"],
    )
    axes[1].set_yscale("log")
    axes[1].set_ylabel("Distinct states (log scale)")
    axes[1].set_title("(b) Workload abstraction")
    axes[1].grid(axis="y", which="both", alpha=0.25)
    save_figure(fig, output, "baseline-evaluation")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--results", type=Path, default=Path("evaluation/phase3_results.csv")
    )
    parser.add_argument(
        "--output", type=Path, default=Path("evaluation/figures")
    )
    args = parser.parse_args()

    rows = read_rows(args.results)
    dynamic_figures(rows, args.output)
    baseline_figures(rows, args.output)


if __name__ == "__main__":
    main()

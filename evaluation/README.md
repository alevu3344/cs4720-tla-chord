# Week 3 Evaluation Data

Run the complete controlled experiment matrix from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\run_week3_experiments.ps1 `
  -Tla2ToolsJar "C:\path\to\tla2tools.jar" `
  -MetaRoot "D:\tlc-chord-week3"
```

The runner fixes the JVM heap at 4 GiB, uses ParallelGC, runs TLC with one
worker, and uses `-lncheck final` so temporal properties are checked once after
the complete state graph has been generated. It writes:

- `environment.json`: machine and tool settings.
- `week3_results.csv`: parsed state counts, depth, wall time, and throughput.
- `logs/*.log`: complete TLC output for every run.

Generate the evaluation figures with:

```powershell
python -m pip install -r requirements-evaluation.txt
python scripts\generate_week3_figures.py
```

The two-join temporal experiment is intentionally included and may take
substantially longer than the other runs.

Use `-Only "<experiment-id>"` to reproduce one CSV row. For example:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\run_week3_experiments.ps1 `
  -Tla2ToolsJar "C:\path\to\tla2tools.jar" `
  -MetaRoot "D:\tlc-chord-week3" `
  -OutputDirectory "evaluation\reproduction" `
  -Only "static-m4-n8-linear"
```

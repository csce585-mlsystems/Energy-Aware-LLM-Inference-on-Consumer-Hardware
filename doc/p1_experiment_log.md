# Milestone P1 Experiment Log

| Date (2025) | Activity | Notes |
|-------------|----------|-------|
| Oct 4 | Compiled `llama.cpp` commit `c1a9bc7` with CUDA and CPU targets. | Verified binary paths recorded in `config/p1_runs.yaml`. |
| Oct 6 | Drafted prompt suites (SD/AR/NG) and added JSONL manifests. | Cross-checked dataset licenses; no restricted content retained. |
| Oct 8 | Implemented `run_session.py` orchestrator and dry-run validation. | Added `--suite` and `--backend` filters for partial reruns. |
| Oct 10 | Recorded three CPU/GPU trials per suite. | Stored summary stats under `data/measurements/p1/*/run_metrics.csv`. |
| Oct 11 | Ran `uv run python src/analysis/p1_summary.py` to regenerate plots and CSV tables. | Updated `doc/figures/p1_energy_per_token.html` and `doc/p1_metrics_summary.csv`. |
| Oct 13 | Proofread Milestone P1 report and checklist. | Confirmed references and added README reproduction section. |

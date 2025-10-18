"""Summarize Milestone P1 telemetry into CSV tables and plots."""
from __future__ import annotations

import argparse
from pathlib import Path
from typing import Dict, List

import pandas as pd
import plotly.express as px


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--input",
        type=Path,
        default=Path("data/measurements/p1"),
        help="Directory containing per-run measurement CSV files.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("doc/figures"),
        help="Destination directory for generated plots.",
    )
    parser.add_argument(
        "--summary-csv",
        type=Path,
        default=Path("doc/p1_metrics_summary.csv"),
        help="Where to store the aggregated metrics table.",
    )
    return parser.parse_args()


def collect_run_metrics(root: Path) -> pd.DataFrame:
    records: List[Dict[str, object]] = []
    for backend_dir in sorted(root.iterdir()):
        if not backend_dir.is_dir():
            continue
        backend = backend_dir.name
        for suite_dir in sorted(backend_dir.iterdir()):
            if not suite_dir.is_dir():
                continue
            suite = suite_dir.name
            csv_path = suite_dir / "run_metrics.csv"
            if not csv_path.exists():
                continue
            df = pd.read_csv(csv_path)
            df["backend"] = backend
            df["suite"] = suite
            df["edp"] = df["energy_j_per_token"] * df["avg_latency_ms_per_token"]
            records.append(df)
    if not records:
        raise FileNotFoundError(f"No run_metrics.csv files found under {root}")
    return pd.concat(records, ignore_index=True)


def summarize(df: pd.DataFrame) -> pd.DataFrame:
    grouped = df.groupby(["suite", "backend"])
    summary = grouped.agg(
        energy_mean=("energy_j_per_token", "mean"),
        energy_std=("energy_j_per_token", "std"),
        latency_mean=("avg_latency_ms_per_token", "mean"),
        latency_std=("avg_latency_ms_per_token", "std"),
        p95_mean=("p95_latency_ms_per_token", "mean"),
        p95_std=("p95_latency_ms_per_token", "std"),
        edp_mean=("edp", "mean"),
    ).reset_index()
    summary["suite"] = summary["suite"].str.upper()
    summary["edp_mean"] = summary["edp_mean"].round(1)
    return summary


def write_summary(summary: pd.DataFrame, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    summary.rename(
        columns={
            "suite": "Prompt Suite",
            "backend": "Backend",
            "energy_mean": "Energy (J/token)",
            "latency_mean": "Avg Latency (ms/token)",
            "p95_mean": "P95 Latency (ms/token)",
            "edp_mean": "EDP (J·ms/token)",
        }
    ).to_csv(path, index=False)
    print(f"✅ Summary written to {path}")


def build_plot(summary: pd.DataFrame, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    fig = px.bar(
        summary,
        x="suite",
        y="energy_mean",
        color="backend",
        barmode="group",
        error_y="energy_std",
        labels={"suite": "Prompt Suite", "energy_mean": "Energy (J/token)", "backend": "Backend"},
        title="Energy per Token by Prompt Suite and Backend",
    )
    html_path = output_dir / "p1_energy_per_token.html"
    fig.write_html(html_path)
    print(f"✅ Plot saved to {html_path}")


def main() -> None:
    args = parse_args()
    df = collect_run_metrics(args.input)
    summary = summarize(df)
    write_summary(summary, args.summary_csv)
    build_plot(summary, args.output)


if __name__ == "__main__":
    main()

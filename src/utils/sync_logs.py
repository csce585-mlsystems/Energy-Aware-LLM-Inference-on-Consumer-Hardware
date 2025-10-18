"""Synchronize CPU and GPU telemetry logs by aligning timestamps."""
from __future__ import annotations

import argparse
import datetime as dt
from pathlib import Path

import pandas as pd


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("cpu_log", type=Path, help="CSV file containing CPU telemetry samples")
    parser.add_argument("gpu_log", type=Path, help="CSV file containing GPU telemetry samples")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("data/measurements/p1/synchronized_power.csv"),
        help="Destination CSV for the aligned samples",
    )
    parser.add_argument(
        "--frequency-ms",
        type=int,
        default=200,
        help="Resampling frequency in milliseconds",
    )
    return parser.parse_args()


def parse_timestamp(value: str) -> dt.datetime:
    return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))


def synchronize(cpu_path: Path, gpu_path: Path, output: Path, frequency_ms: int) -> None:
    cpu = pd.read_csv(cpu_path)
    gpu = pd.read_csv(gpu_path)

    if "timestamp" not in cpu.columns or "timestamp" not in gpu.columns:
        raise RuntimeError("Both logs must include a 'timestamp' column")

    cpu["timestamp"] = cpu["timestamp"].apply(parse_timestamp)
    gpu["timestamp"] = gpu["timestamp"].apply(parse_timestamp)

    start = min(cpu["timestamp"].min(), gpu["timestamp"].min())
    end = max(cpu["timestamp"].max(), gpu["timestamp"].max())

    index = pd.date_range(start=start, end=end, freq=f"{frequency_ms}L", inclusive="both")

    cpu = cpu.set_index("timestamp").reindex(index, method="nearest", tolerance=pd.Timedelta(milliseconds=frequency_ms))
    gpu = gpu.set_index("timestamp").reindex(index, method="nearest", tolerance=pd.Timedelta(milliseconds=frequency_ms))

    merged = pd.concat({"cpu": cpu, "gpu": gpu}, axis=1)
    merged.index.name = "timestamp"
    output.parent.mkdir(parents=True, exist_ok=True)
    merged.reset_index().to_csv(output, index=False)
    print(f"✅ Synchronized logs written to {output}")


def main() -> None:
    args = parse_args()
    synchronize(args.cpu_log, args.gpu_log, args.output, args.frequency_ms)


if __name__ == "__main__":
    main()

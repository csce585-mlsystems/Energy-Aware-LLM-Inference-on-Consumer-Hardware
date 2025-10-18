"""Utility helpers for recording benchmark telemetry to CSV files."""
from __future__ import annotations

import csv
import datetime as dt
import subprocess
import tempfile
import shutil
import pandas as pd
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, Optional


@dataclass
class TelemetryLogger:
    """Append benchmark runs to latency and power CSV logs."""

    latency_path: Path = Path("data/latency_results.csv")
    power_path: Path = Path("data/power_logs.csv")
    powerlog_path: Path = Path(r"C:\Program Files\Intel\Power Gadget 3.7\PowerLog3.exe")

    _latency_headers: Iterable[str] = field(
        default_factory=lambda: (
            "timestamp",
            "backend",
            "prompt_id",
            "prompt_template",
            "prompt_length_chars",
            "latency_ms",
            "tokens_generated",
            "energy_joules",
            "notes",
        )
    )

    def __post_init__(self) -> None:
        self.latency_path.parent.mkdir(parents=True, exist_ok=True)
        self.power_path.parent.mkdir(parents=True, exist_ok=True)

    def log_latency(
        self,
        backend: str,
        prompt_id: str,
        prompt_template: str,
        prompt_length: int,
        latency_ms: Optional[float],
        tokens_generated: Optional[int] = None,
        energy_joules: Optional[float] = None,
        notes: str = "",
    ) -> None:
        """Record a single latency measurement."""
        record = {
            "timestamp": dt.datetime.utcnow().isoformat(timespec="milliseconds"),
            "backend": backend,
            "prompt_id": prompt_id,
            "prompt_template": prompt_template,
            "prompt_length_chars": prompt_length,
            "latency_ms": None if latency_ms is None else round(latency_ms, 3),
            "tokens_generated": tokens_generated,
            "energy_joules": None if energy_joules is None else round(energy_joules, 6),
            "notes": notes,
        }
        self._append_row(self.latency_path, self._latency_headers, record)

    def log_power_sample(self, sample: Dict[str, float]) -> None:
        """Append a raw power telemetry sample to ``power_logs.csv``."""
        headers = tuple(sample.keys())
        self._append_row(self.power_path, headers, sample)

    def _append_row(self, path: Path, headers: Iterable[str], row: Dict[str, object]) -> None:
        exists = path.exists()
        with path.open("a", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=headers)
            if not exists:
                writer.writeheader()
            writer.writerow(row)

    def record_cpu_power(self, duration: int = 5, notes: str = "") -> None:
        """Run Intel PowerLog for a duration and append results to power_logs.csv."""
        tmp_file = Path(tempfile.gettempdir()) / "powerlog_temp.csv"

        # 1. Launch PowerLog
        cmd = [str(self.powerlog_path), "-duration", str(duration), "-file", str(tmp_file)]
        subprocess.run(cmd, check=True)

        # 2. Read the generated CSV
        if not tmp_file.exists():
            print("⚠️ PowerLog did not produce a file")
            return

        df = pd.read_csv(tmp_file)

        # 3. Compute total energy (joules)
        if "Processor Power_0(Watt)" in df.columns:
            avg_watts = df["Processor Power_0(Watt)"].mean()
            joules = avg_watts * duration
        else:
            joules = None

        # 4. Append a summary row
        self.log_power_sample({
            "timestamp": dt.datetime.utcnow().isoformat(timespec="milliseconds"),
            "backend": "cpu",
            "energy_joules": joules,
            "notes": notes,
        })

        # 5. Save raw Intel log
        dest_raw = self.power_path.parent / f"raw_cpu_power_{dt.datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        shutil.move(str(tmp_file), dest_raw)
        print(f"✅ CPU power logged: {joules:.2f} J (raw CSV saved to {dest_raw})")


__all__ = ["TelemetryLogger"]

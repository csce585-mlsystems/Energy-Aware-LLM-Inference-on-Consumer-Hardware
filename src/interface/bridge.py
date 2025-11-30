import json
import csv
import datetime as dt
import glob
import os
import math
from pathlib import Path
from typing import List, Dict, Optional

# Configuration
DATA_DIR = Path("data")
LATENCY_FILE = DATA_DIR / "latency_results.csv"
OUTPUT_FILE = DATA_DIR / "gamemaker_export.json"

# Timezone offset (Intel Gadget is Local, Python is UTC)
# User metadata says -05:00.
LOCAL_TZ_OFFSET = dt.timedelta(hours=-5)

def parse_iso_utc(t_str: str) -> dt.datetime:
    """Parse ISO format timestamp (UTC)."""
    # Python 3.11+ supports fromisoformat with Z, but let's be safe
    return dt.datetime.fromisoformat(t_str)

def load_latency_runs() -> List[Dict]:
    """Load all runs from latency_results.csv."""
    runs = []
    if not LATENCY_FILE.exists():
        print(f"Warning: {LATENCY_FILE} not found.")
        return []

    with open(LATENCY_FILE, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                start_utc = parse_iso_utc(row["timestamp"])
                # Convert to naive local time for matching with Intel Gadget
                start_local = start_utc + LOCAL_TZ_OFFSET
                
                latency_ms = float(row["latency_ms"]) if row["latency_ms"] else 0.0
                end_local = start_local + dt.timedelta(milliseconds=latency_ms)

                runs.append({
                    "run_id": row["run_id"],
                    "backend": row["backend"],
                    "prompt_id": row["prompt_id"],
                    "latency_ms": latency_ms,
                    "energy_joules": float(row["energy_joules"]) if row["energy_joules"] else 0.0,
                    "start_local": start_local,
                    "end_local": end_local,
                    "power_trace": []  # To be filled
                })
            except ValueError:
                continue
    return runs

def parse_gadget_time(date_part: str, t_str: str) -> Optional[dt.datetime]:
    """Parse Intel Gadget time (HH:MM:SS:mmm) + Date."""
    try:
        parts = t_str.split(":")
        if len(parts) == 4:
            h, m, s, ms = int(parts[0]), int(parts[1]), int(parts[2]), int(parts[3])
            base_date = dt.datetime.strptime(date_part, "%Y%m%d")
            return base_date.replace(hour=h, minute=m, second=s, microsecond=ms*1000)
    except:
        pass
    return None

def find_cpu_trace(run: Dict) -> List[float]:
    """Find and extract CPU power trace for a specific run window."""
    files = sorted(glob.glob(str(DATA_DIR / "raw_cpu_power_*.csv")))
    best_trace = []
    
    for fpath in files:
        try:
            filename = os.path.basename(fpath)
            # raw_cpu_power_20251123_233510.csv
            parts = filename.split("_")
            if len(parts) < 4: continue
            date_part = parts[2] # 20251123
            
            with open(fpath, "r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                # Check headers
                if "System Time" not in reader.fieldnames or "Processor Power_0(Watt)" not in reader.fieldnames:
                    continue
                
                for row in reader:
                    t_val = parse_gadget_time(date_part, row["System Time"])
                    if t_val and run["start_local"] <= t_val <= run["end_local"]:
                        try:
                            val = float(row["Processor Power_0(Watt)"])
                            best_trace.append(val)
                        except ValueError:
                            pass
        except Exception:
            continue
            
    return best_trace

def find_gpu_trace(run: Dict) -> List[float]:
    """Find and extract GPU power trace."""
    files = sorted(glob.glob(str(DATA_DIR / "raw_gpu_power_*.csv")))
    best_trace = []
    
    # Convert run times back to UTC for GPU matching
    start_utc = run["start_local"] - LOCAL_TZ_OFFSET
    end_utc = run["end_local"] - LOCAL_TZ_OFFSET
    
    for fpath in files:
        try:
            with open(fpath, "r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                if "timestamp" not in reader.fieldnames or "power_w" not in reader.fieldnames:
                    continue
                
                for row in reader:
                    try:
                        t_val = parse_iso_utc(row["timestamp"])
                        if start_utc <= t_val <= end_utc:
                            val = float(row["power_w"])
                            best_trace.append(val)
                    except ValueError:
                        pass
        except Exception:
            continue
            
    return best_trace

def resample_trace(trace: List[float], target_points: int = 100) -> List[float]:
    """Resample a list of floats to a fixed size using linear interpolation."""
    if not trace:
        return [0.0] * target_points
    
    n = len(trace)
    if n == target_points:
        return trace
    
    # Linear interpolation
    resampled = []
    for i in range(target_points):
        # Map i (0..target_points-1) to x (0..n-1)
        x = i * (n - 1) / (target_points - 1)
        idx = int(x)
        frac = x - idx
        
        if idx >= n - 1:
            val = trace[-1]
        else:
            val = trace[idx] * (1.0 - frac) + trace[idx + 1] * frac
        resampled.append(val)
        
    return resampled

def main():
    print("Loading runs...")
    runs = load_latency_runs()
    print(f"Found {len(runs)} runs.")
    
    export_data = {"runs": []}
    
    for run in runs:
        print(f"Processing {run['run_id']} ({run['backend']})...")
        
        trace = []
        if run["backend"] == "cpu":
            trace = find_cpu_trace(run)
        elif run["backend"] == "gpu":
            trace = find_gpu_trace(run)
            
        if not trace:
            print(f"  ⚠️ No power trace found for {run['run_id']}")
            # Fallback: flat line
            if run["energy_joules"] and run["latency_ms"]:
                avg_watts = run["energy_joules"] / (run["latency_ms"] / 1000.0)
                trace = [avg_watts] * 10
            else:
                trace = [0.0] * 10
        
        smooth_trace = resample_trace(trace, 100)
        
        export_data["runs"].append({
            "run_id": run["run_id"],
            "backend": run["backend"],
            "latency_ms": run["latency_ms"],
            "energy_joules": run["energy_joules"],
            "power_trace": smooth_trace
        })
        
    print(f"Writing {OUTPUT_FILE}...")
    with open(OUTPUT_FILE, "w") as f:
        json.dump(export_data, f, indent=2)
    print("Done.")

if __name__ == "__main__":
    main()

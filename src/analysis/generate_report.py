import pandas as pd
from pathlib import Path

def generate_report():
    # Load data
    latency_df = pd.read_csv("data/latency_results.csv")
    power_df = pd.read_csv("data/power_logs.csv")

    # Convert timestamps to datetime
    latency_df["timestamp"] = pd.to_datetime(latency_df["timestamp"])
    power_df["timestamp"] = pd.to_datetime(power_df["timestamp"])

    # Filter out mock data
    cutoff_date = pd.Timestamp("2025-11-01")
    latency_df = latency_df[latency_df["timestamp"] > cutoff_date]
    power_df = power_df[power_df["timestamp"] > cutoff_date]

    print(f"Loaded {len(latency_df)} latency records and {len(power_df)} power records.")

    # --- 1. Latency Analysis ---
    # Group by backend and prompt_template (suite)
    latency_summary = latency_df.groupby(["backend", "prompt_template"]).agg(
        avg_latency_ms=("latency_ms", "mean"),
        p95_latency_ms=("latency_ms", lambda x: x.quantile(0.95)),
        count=("latency_ms", "count")
    ).reset_index()

    # --- 2. Energy Analysis ---
    # Extract suite from 'notes' field in power logs (e.g., "prompt=sd-001" -> "short_dialogue")
    # This is a bit tricky because power logs only have prompt ID. We map ID prefix to suite.
    def map_id_to_suite(note):
        if "sd-" in note: return "short_dialogue"
        if "ar-" in note: return "analytical_reasoning"
        if "ng-" in note: return "narrative_generation"
        return "unknown"

    power_df["suite"] = power_df["notes"].apply(map_id_to_suite)
    
    energy_summary = power_df.groupby(["backend", "suite"]).agg(
        avg_energy_joules=("energy_joules", "mean"),
        count=("energy_joules", "count")
    ).reset_index()

    # --- 3. Merge and Calculate EDP ---
    merged = pd.merge(
        latency_summary, 
        energy_summary, 
        left_on=["backend", "prompt_template"], 
        right_on=["backend", "suite"]
    )

    # EDP = Energy (J) * Latency (s)
    merged["edp"] = merged["avg_energy_joules"] * (merged["avg_latency_ms"] / 1000.0)

    # --- 4. Formatting ---
    print("\n=== Performance Report (Nov 2025) ===")
    print(f"{'Backend':<8} | {'Suite':<20} | {'Latency (ms)':<12} | {'Energy (J)':<10} | {'EDP (J*s)':<10}")
    print("-" * 75)
    
    for _, row in merged.iterrows():
        print(f"{row['backend']:<8} | {row['prompt_template']:<20} | {row['avg_latency_ms']:<12.2f} | {row['avg_energy_joules']:<10.2f} | {row['edp']:<10.2f}")

    # Save to file
    report_path = Path("doc/Report.md")
    with open(report_path, "w") as f:
        f.write("# Performance Report (Nov 2025)\n\n")
        f.write("| Backend | Suite | Latency (ms) | Energy (J) | EDP (J*s) |\n")
        f.write("|---------|-------|--------------|------------|-----------|\n")
        for _, row in merged.iterrows():
            f.write(f"| {row['backend']} | {row['prompt_template']} | {row['avg_latency_ms']:.2f} | {row['avg_energy_joules']:.2f} | {row['edp']:.2f} |\n")
    
    print(f"\nReport saved to {report_path}")

if __name__ == "__main__":
    generate_report()

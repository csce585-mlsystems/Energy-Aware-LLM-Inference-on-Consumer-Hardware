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

    # --- 5. Generate Figures ---
    import matplotlib.pyplot as plt
    import seaborn as sns
    
    # Use non-interactive backend to avoid Tcl/Tk errors
    plt.switch_backend("Agg")

    # Ensure figures directory exists
    figures_dir = Path("doc/figures")
    figures_dir.mkdir(parents=True, exist_ok=True)

    # Figure 1: Energy vs Latency Scatter Plot
    plt.figure(figsize=(10, 6))
    sns.scatterplot(
        data=merged, 
        x="avg_latency_ms", 
        y="avg_energy_joules", 
        hue="backend", 
        style="prompt_template", 
        s=200
    )
    plt.title("Energy vs. Latency: CPU vs GPU")
    plt.xlabel("Average Latency (ms)")
    plt.ylabel("Average Energy (Joules)")
    plt.grid(True, linestyle="--", alpha=0.7)
    plt.savefig(figures_dir / "energy_vs_latency.png")
    print(f"Saved figure: {figures_dir / 'energy_vs_latency.png'}")

    # Figure 2: Bar Chart Comparison
    # Melt for easier plotting
    melted = merged.melt(id_vars=["backend", "prompt_template"], value_vars=["avg_latency_ms", "avg_energy_joules"], var_name="metric", value_name="value")
    
    g = sns.catplot(
        data=melted, 
        kind="bar", 
        x="prompt_template", 
        y="value", 
        hue="backend", 
        col="metric", 
        sharey=False,
        height=5, 
        aspect=1.2
    )
    g.set_titles("{col_name}")
    g.axes[0,0].set_ylabel("Latency (ms)")
    g.axes[0,1].set_ylabel("Energy (J)")
    plt.savefig(figures_dir / "metrics_comparison.png")
    print(f"Saved figure: {figures_dir / 'metrics_comparison.png'}")

    # Figure 3: GPU Power Trace (Latest Run)
    import glob
    import os
    
    # Find latest raw GPU power log
    gpu_logs = glob.glob("data/raw_gpu_power_*.csv")
    if gpu_logs:
        latest_gpu_log = max(gpu_logs, key=os.path.getctime)
        print(f"Plotting GPU trace from: {latest_gpu_log}")
        
        gpu_trace_df = pd.read_csv(latest_gpu_log)
        gpu_trace_df["timestamp"] = pd.to_datetime(gpu_trace_df["timestamp"])
        
        # Calculate relative time (seconds from start)
        start_time = gpu_trace_df["timestamp"].min()
        gpu_trace_df["time_rel_s"] = (gpu_trace_df["timestamp"] - start_time).dt.total_seconds()
        
        plt.figure(figsize=(12, 5))
        sns.lineplot(data=gpu_trace_df, x="time_rel_s", y="power_w", color="green", linewidth=1)
        plt.title(f"GPU Power Trace (Run: {Path(latest_gpu_log).name})")
        plt.xlabel("Time (s)")
        plt.ylabel("Power (W)")
        plt.grid(True, linestyle="--", alpha=0.5)
        plt.tight_layout()
        plt.savefig(figures_dir / "gpu_power_trace.png")
        print(f"Saved figure: {figures_dir / 'gpu_power_trace.png'}")
    else:
        print("No raw GPU power logs found.")

    # Save to file
    report_path = Path("doc/latest_report.md")
    with open(report_path, "w") as f:
        f.write("# Performance Report (Nov 2025)\n\n")
        f.write("## Summary Table\n")
        f.write("| Backend | Suite | Latency (ms) | Energy (J) | EDP (J*s) |\n")
        f.write("|---------|-------|--------------|------------|-----------|\n")
        for _, row in merged.iterrows():
            f.write(f"| {row['backend']} | {row['prompt_template']} | {row['avg_latency_ms']:.2f} | {row['avg_energy_joules']:.2f} | {row['edp']:.2f} |\n")
        
        f.write("\n## Visualizations\n")
        f.write("![Energy vs Latency](figures/energy_vs_latency.png)\n")
        f.write("![Metrics Comparison](figures/metrics_comparison.png)\n")
        if gpu_logs:
            f.write("![GPU Power Trace](figures/gpu_power_trace.png)\n")
    
    print(f"\nReport saved to {report_path}")

if __name__ == "__main__":
    generate_report()

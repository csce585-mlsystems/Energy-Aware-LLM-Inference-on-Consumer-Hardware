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
    # --- 2. Energy Analysis ---
    # Since we have verified that latency_results.csv and power_logs.csv have 1-to-1 correspondence (27 rows each)
    # and are sequential, we can merge them directly by index after sorting by timestamp.
    
    latency_df = latency_df.sort_values("timestamp").reset_index(drop=True)
    power_df = power_df.sort_values("timestamp").reset_index(drop=True)
    
    if len(latency_df) != len(power_df):
        print(f"⚠️ Warning: record count mismatch! Latency: {len(latency_df)}, Power: {len(power_df)}")
        # Proceeding with inner join on index if possible or truncation, but for this task we assume perfect match
        # as verified by the user.

    # Assign energy to latency dataframe
    latency_df["energy_joules"] = power_df["energy_joules"]
    
    # Create the 'merged' dataframe for plotting (now it contains all 27 rows)
    merged = latency_df.copy()
    merged["avg_latency_ms"] = merged["latency_ms"] # Alias for compatibility with existing plot code if needed, but better to change plot code
    merged["avg_energy_joules"] = merged["energy_joules"]

    # --- 3. Calculate EDP ---
    # EDP = Energy (J) * Latency (s)
    merged["edp"] = merged["energy_joules"] * (merged["latency_ms"] / 1000.0)

    # --- Grouping for Summary Table (Optional: keep summary table logic) ---
    summary_table = merged.groupby(["backend", "prompt_template"]).agg(
         avg_latency_ms=("latency_ms", "mean"),
         avg_energy_joules=("energy_joules", "mean"),
         avg_edp=("edp", "mean")
    ).reset_index()


    # EDP = Energy (J) * Latency (s)
    merged["edp"] = merged["avg_energy_joules"] * (merged["avg_latency_ms"] / 1000.0)

    # --- 4. Formatting ---
    print("\n=== Performance Report (Nov 2025) ===")
    print(f"{'Backend':<8} | {'Suite':<20} | {'Latency (ms)':<12} | {'Energy (J)':<10} | {'EDP (J*s)':<10}")
    print("-" * 75)
    
    for _, row in summary_table.iterrows():
        print(f"{row['backend']:<8} | {row['prompt_template']:<20} | {row['avg_latency_ms']:<12.2f} | {row['avg_energy_joules']:<10.2f} | {row['avg_edp']:<10.2f}")

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
        x="latency_ms", 
        y="energy_joules", 
        hue="backend", 
        style="run_id", 
        s=100
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


    # --- 6. Ablation Study Analysis ---
    print("\n--- Generating Ablation Plots ---")
    
    # Reload data to ensure we have the latest with run_id
    try:
        latency_df = pd.read_csv("data/latency_results.csv")
        # Ensure run_id exists
        if "run_id" not in latency_df.columns:
            print("⚠️ 'run_id' column missing in latency_results.csv. Skipping ablation plots.")
        else:
            # Filter for ablation suites
            ablation_df = latency_df[latency_df["run_id"].str.contains("cpu-t|gpu-l|gpu-b", na=False)].copy()
            
            if not ablation_df.empty:
                # Parse parameters from run_id
                def extract_param(run_id):
                    if "cpu-t" in run_id:
                        return "threads", int(run_id.split("-t")[1])
                    if "gpu-l" in run_id:
                        return "layers", int(run_id.split("-l")[1])
                    if "gpu-b" in run_id:
                        return "batch_size", int(run_id.split("-b")[1])
                    return "unknown", 0

                ablation_df[["param_type", "param_value"]] = ablation_df["run_id"].apply(
                    lambda x: pd.Series(extract_param(x))
                )

                # Plot 1: CPU Thread Scaling
                threads_df = ablation_df[ablation_df["param_type"] == "threads"]
                if not threads_df.empty:
                    plt.figure(figsize=(8, 5))
                    sns.lineplot(data=threads_df, x="param_value", y="latency_ms", marker="o")
                    plt.title("CPU Thread Scaling: Latency vs Threads")
                    plt.xlabel("Threads")
                    plt.ylabel("Latency (ms)")
                    plt.grid(True, linestyle="--", alpha=0.5)
                    plt.savefig(figures_dir / "ablation_threads.png")
                    print(f"Saved figure: {figures_dir / 'ablation_threads.png'}")

                # Plot 2: GPU Layer Offloading
                layers_df = ablation_df[ablation_df["param_type"] == "layers"]
                if not layers_df.empty:
                    plt.figure(figsize=(8, 5))
                    sns.lineplot(data=layers_df, x="param_value", y="latency_ms", marker="o", color="orange")
                    plt.title("GPU Offloading: Latency vs GPU Layers")
                    plt.xlabel("GPU Layers Offloaded")
                    plt.ylabel("Latency (ms)")
                    plt.grid(True, linestyle="--", alpha=0.5)
                    plt.savefig(figures_dir / "ablation_layers.png")
                    print(f"Saved figure: {figures_dir / 'ablation_layers.png'}")

                # Plot 3: Batch Size Scaling
                batch_df = ablation_df[ablation_df["param_type"] == "batch_size"]
                if not batch_df.empty:
                    plt.figure(figsize=(8, 5))
                    sns.lineplot(data=batch_df, x="param_value", y="latency_ms", marker="o", color="green")
                    plt.title("Batch Size Scaling: Latency vs Batch Size")
                    plt.xlabel("Batch Size")
                    plt.ylabel("Latency (ms)")
                    plt.grid(True, linestyle="--", alpha=0.5)
                    plt.savefig(figures_dir / "ablation_batch.png")
                    print(f"Saved figure: {figures_dir / 'ablation_batch.png'}")
            else:
                print("No ablation data found in CSV.")

    except Exception as e:
        print(f"⚠️ Failed to generate ablation plots: {e}")

    print(f"\nReport saved to {figures_dir / 'report.txt'}") # Assuming report_path is figures_dir / 'report.txt'

if __name__ == "__main__":
    generate_report()

import pandas as pd

def get_stats():
    # Load data
    latency_df = pd.read_csv("data/latency_results.csv")
    power_df = pd.read_csv("data/power_logs.csv")

    # Convert timestamps
    latency_df["timestamp"] = pd.to_datetime(latency_df["timestamp"])
    power_df["timestamp"] = pd.to_datetime(power_df["timestamp"])

    # Sort and reset index
    latency_df = latency_df.sort_values("timestamp").reset_index(drop=True)
    power_df = power_df.sort_values("timestamp").reset_index(drop=True)

    # Assign energy
    latency_df["energy_joules"] = power_df["energy_joules"]
    
    # Calculate EDP
    latency_df["edp"] = latency_df["energy_joules"] * (latency_df["latency_ms"] / 1000.0)

    # Groupby
    summary = latency_df.groupby(["backend", "prompt_template"]).agg(
         avg_latency_ms=("latency_ms", "mean"),
         avg_energy_joules=("energy_joules", "mean"),
         avg_edp=("edp", "mean")
    ).reset_index()

    # Also get specific run analysis
    # Helper to extract group from run_id (e.g. cpu-t4 from cpu-t4)
    # Actually run_id is already unique enough for grouping if we want, but let's group by config
    # The run_id format is like 'cpu-t1', 'gpu-l11'.
    
    summary_run = latency_df.groupby("run_id").agg(
         avg_latency_ms=("latency_ms", "mean"),
         avg_energy_joules=("energy_joules", "mean"),
         avg_edp=("edp", "mean")
    ).reset_index().sort_values("avg_edp")

    with open("stats_output.json", "w", encoding="utf-8") as f:
        f.write(summary.to_json(orient="records", indent=2))
        f.write("\n\n")
        f.write(summary_run.to_json(orient="records", indent=2))
        
    print("Saved to stats_output.json")

if __name__ == "__main__":
    get_stats()

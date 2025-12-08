import pandas as pd

def check_plot_data():
    latency_df = pd.read_csv("data/latency_results.csv")
    power_df = pd.read_csv("data/power_logs.csv")
    
    # Filter mock data like in the script
    cutoff_date = pd.Timestamp("2025-11-01")
    latency_df["timestamp"] = pd.to_datetime(latency_df["timestamp"])
    power_df["timestamp"] = pd.to_datetime(power_df["timestamp"])
    latency_df = latency_df[latency_df["timestamp"] > cutoff_date]
    power_df = power_df[power_df["timestamp"] > cutoff_date]

    # Replicate the grouping logic from generate_report.py
    
    # Latency Grouping
    latency_summary = latency_df.groupby(["backend", "prompt_template"]).agg(
        avg_latency_ms=("latency_ms", "mean")
    ).reset_index()
    
    # Power Grouping
    def map_id_to_suite(note):
        if "sd-" in note: return "short_dialogue"
        return "unknown"
    
    power_df["suite"] = power_df["notes"].apply(map_id_to_suite)
    energy_summary = power_df.groupby(["backend", "suite"]).agg(
        avg_energy_joules=("energy_joules", "mean")
    ).reset_index()
    
    # Merge
    merged = pd.merge(
        latency_summary, 
        energy_summary, 
        left_on=["backend", "prompt_template"], 
        right_on=["backend", "suite"]
    )
    
    print(f"Total rows in Latency CSV (experiments): {len(latency_df)}")
    print(f"Total rows in 'merged' dataframe used for Figure 1: {len(merged)}")
    print("\nData in 'merged' (Points shown in plot):")
    print(merged)

if __name__ == "__main__":
    check_plot_data()

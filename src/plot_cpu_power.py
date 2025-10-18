import sys
import pandas as pd
import matplotlib.pyplot as plt

def main(csv_file: str):
    # Load Intel Power Gadget CSV
    df = pd.read_csv(csv_file)

    # Try to find the column with CPU power
    power_cols = [c for c in df.columns if "Power" in c and "W" in c]
    if not power_cols:
        raise RuntimeError(f"No power column found in {csv_file}")

    power_col = power_cols[0]  # just take the first match

    # Plot power vs time
    plt.figure(figsize=(10, 5))
    plt.plot(df.index, df[power_col], label=power_col)
    plt.xlabel("Time (samples)")
    plt.ylabel("Power (Watts)")
    plt.title("CPU Power Consumption Over Time")
    plt.legend()
    plt.grid(True)
    plt.savefig("data/cpu_power.png")  
    plt.show()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python -m src.plot_cpu_power <csv_file>")
        sys.exit(1)
    main(sys.argv[1])

import argparse
import json
import time
import random
import sys
import logging
import glob
import csv
import os
import datetime as dt
from flask import Flask, request, jsonify

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger("EnergyDemo")

app = Flask(__name__)

def get_latest_trace_file(backend):
    """Finds the most recent CSV file for the given backend."""
    search_pattern = f"data/raw_{backend}_power_*.csv"
    files = glob.glob(search_pattern)
    if not files: return None
    files.sort(key=os.path.getmtime, reverse=True)
    return files[0]

def parse_trace_csv(filepath):
    """Reads the CSV and returns the power trace and calculated energy."""
    trace = []
    try:
        with open(filepath, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                val = 0.0
                for key, v in row.items():
                    if "power" in key.lower() or "watt" in key.lower():
                        try: val = float(v); break
                        except: pass
                trace.append(val)
        
        if len(trace) > 200: trace = trace[::len(trace)//200]
        energy_joules = sum(trace) * 0.1 
        return trace, energy_joules
    except Exception as e:
        logger.error(f"Error parsing {filepath}: {e}")
        return [], 0.0

def load_csv_data(filepath):
    """Generic CSV loader."""
    data = []
    if not os.path.exists(filepath): return []
    try:
        with open(filepath, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader: data.append(row)
    except: pass
    return data

def parse_iso_time(iso_str):
    """Parses ISO timestamp to datetime object."""
    try:
        return dt.datetime.fromisoformat(iso_str)
    except:
        return dt.datetime.now() # Fallback

@app.route('/history', methods=['GET'])
def history():
    """Returns merged history from latency_results.csv and power_logs.csv."""
    logger.info("Fetching full history...")
    
    latencies = load_csv_data("data/latency_results.csv")
    powers = load_csv_data("data/power_logs.csv")
    
    merged_runs = []
    used_power_indices = set()  # Track which power logs we've matched
    
    # Phase 1: Process latency entries and try to match with power logs
    for lat in latencies:
        try:
            l_time = parse_iso_time(lat.get("timestamp", ""))
            l_backend = lat.get("backend", "unknown")
            l_val = float(lat.get("latency_ms", 0))
            
            # Find matching power log
            matched_energy = 0.0
            best_delta = 10.0
            best_power_idx = -1
            
            for idx, pow_log in enumerate(powers):
                if pow_log.get("backend") != l_backend: continue
                if idx in used_power_indices: continue  # Skip already matched
                
                p_time = parse_iso_time(pow_log.get("timestamp", ""))
                delta = abs((l_time - p_time).total_seconds())
                
                if delta < best_delta:
                    best_delta = delta
                    best_power_idx = idx
                    try: matched_energy = float(pow_log.get("energy_joules", 0))
                    except: matched_energy = 0.0
            
            # Mark this power log as used if we found a match
            if best_power_idx != -1:
                used_power_indices.add(best_power_idx)
            
            # If no match in power_logs, check if latency CSV has energy
            if matched_energy == 0.0:
                try: matched_energy = float(lat.get("energy_joules", 0))
                except: pass
                
            merged_runs.append({
                "run_id": lat.get("run_id", "unknown"),
                "backend": l_backend,
                "latency_ms": l_val,
                "energy_joules": matched_energy,
                "timestamp": lat.get("timestamp"),
                "power_trace": []
            })
            
        except Exception as e:
            logger.warning(f"Skipping malformed latency row: {e}")
            continue
    
    # Phase 2: Add unmatched power log entries (ones without corresponding latency data)
    for idx, pow_log in enumerate(powers):
        if idx in used_power_indices:
            continue  # Already matched with a latency entry
            
        try:
            p_time = parse_iso_time(pow_log.get("timestamp", ""))
            p_backend = pow_log.get("backend", "unknown")
            
            try: p_energy = float(pow_log.get("energy_joules", 0))
            except: p_energy = 0.0
            
            # Estimate latency from energy if not available (rough heuristic)
            # Or leave as 0 to indicate it's missing
            estimated_latency = 0.0
            
            merged_runs.append({
                "run_id": f"power_only_{idx}",
                "backend": p_backend,
                "latency_ms": estimated_latency,
                "energy_joules": p_energy,
                "timestamp": pow_log.get("timestamp"),
                "power_trace": []
            })
            
        except Exception as e:
            logger.warning(f"Skipping malformed power row: {e}")
            continue
            
    return jsonify({"runs": merged_runs})

@app.route('/latest_trace', methods=['GET'])
def latest_trace():
    backend = request.args.get("backend", "gpu")
    logger.info(f"Received request for latest {backend} trace.")
    
    filepath = get_latest_trace_file(backend)
    
    if not filepath:
        return jsonify({"error": "No data found", "message": "Run experiments first."}), 404
        
    logger.info(f"Serving file: {filepath}")
    trace, energy = parse_trace_csv(filepath)
    latency_ms = len(trace) * 100 # Approx
    
    response_data = {
        "runs": [{
            "run_id": os.path.basename(filepath),
            "backend": backend,
            "latency_ms": latency_ms,
            "energy_joules": round(energy, 2),
            "power_trace": trace,
            "text": f"Visualizing {os.path.basename(filepath)}"
        }]
    }
    
    time.sleep(0.5) # UI Delay
    return jsonify(response_data)

@app.route('/status', methods=['GET'])
def status():
    return jsonify({"status": "idle", "step": 0, "step_name": "Ready", "progress": 0.0})

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=5000)
    args = parser.parse_args()
    print(f"Starting Data Server on port {args.port}...")
    app.run(host='0.0.0.0', port=args.port)

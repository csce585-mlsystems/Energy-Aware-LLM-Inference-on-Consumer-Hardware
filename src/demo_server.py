import argparse
import json
import time
import random
import sys
import logging
from flask import Flask, request, jsonify

# Configure logging to show "Process Labels" clearly in the terminal
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger("EnergyDemo")

app = Flask(__name__)

# Progress tracking (shared state)
current_progress = {
    "status": "idle",      # idle, processing, complete
    "step": 0,             # 0-4
    "step_name": "Ready",
    "progress": 0.0        # 0.0 - 1.0
}

import glob
import csv

def get_real_trace(backend="gpu"):
    """Loads a random real power trace from the data directory."""
    try:
        # Find all CSVs for the requested backend
        file_pattern = f"data/raw_{backend}_power_*.csv"
        files = glob.glob(file_pattern)
        
        if not files:
            logger.warning(f"No real data found for {backend}, falling back to mock.")
            return generate_mock_trace()
            
        # Pick a random file
        selected_file = random.choice(files)
        logger.info(f"Loading real trace from: {selected_file}")
        
        trace = []
        with open(selected_file, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                # Parse power value (assuming column name 'Power(W)' or similar from Intel Power Gadget/NVML)
                # Adjust based on actual CSV format. 
                # NVML usually has ' power_draw_W' or similar.
                # Let's try to find a column that looks like power.
                for key, val in row.items():
                    if "power" in key.lower() or "watt" in key.lower():
                        try:
                            val = float(val)
                            if val > 0: # Filter out zeros if needed
                                trace.append(val)
                            break
                        except:
                            pass
                            
        if not trace:
            return generate_mock_trace()
            
        # Downsample if too large (GameMaker doesn't need 1000s of points)
        if len(trace) > 100:
            step = len(trace) // 100
            trace = trace[::step]
            
        return trace
        
    except Exception as e:
        logger.error(f"Error loading real trace: {e}")
        return generate_mock_trace()

def generate_mock_trace(duration_sec=2.0):
    """Generates a realistic-looking power trace for the demo (Fallback)."""
    points = int(duration_sec * 10) # 10 samples per second
    trace = []
    
    # Idle baseline
    trace.append(15.0)
    trace.append(16.2)
    
    # Ramp up
    trace.append(80.5)
    trace.append(150.0)
    
    # Sustained load (noisy)
    for _ in range(points - 4):
        trace.append(random.uniform(140.0, 160.0))
        
    # Ramp down
    trace.append(40.0)
    trace.append(16.0)
    
    return trace

@app.route('/generate', methods=['POST'])
def generate():
    global current_progress
    
    data = request.json or {}
    prompt = data.get("prompt", "Hello, world!")
    backend = data.get("backend", "gpu")
    
    # STEP 1: Request Received
    current_progress = {"status": "processing", "step": 1, "step_name": "Request Received", "progress": 0.0}
    print("\n" + "="*40)
    logger.info(f"[STEP 1] Request Received: '{prompt}'")
    logger.info(f"[STEP 1] Selected Backend: {backend.upper()}")
    print("="*40 + "\n")
    time.sleep(0.5)
    
    # STEP 2: Loading
    current_progress = {"status": "processing", "step": 2, "step_name": "Loading Model & Warming Up Sensors...", "progress": 0.25}
    logger.info("[STEP 2] Loading Model & Warming Up Sensors...")
    time.sleep(0.5)
    
    # STEP 3: Inference
    current_progress = {"status": "processing", "step": 3, "step_name": "Running Inference...", "progress": 0.5}
    logger.info("[STEP 3] Running Inference...")
    start_time = time.time()
    
    # --- SIMULATED REAL-TIME INFERENCE ---
    # Load the full trace first
    full_trace = get_real_trace(backend)
    
    # Calculate duration based on trace length (assuming 10Hz sampling = 0.1s per point)
    # Adjust this if your CSVs have different sampling rates.
    # NVML/PowerGadget usually ~10-20Hz.
    point_duration = 0.1 
    
    current_progress["status"] = "processing"
    current_progress["step"] = 3
    current_progress["step_name"] = "Running Inference..."
    
    live_trace = []
    
    # Stream the data!
    for i, power_val in enumerate(full_trace):
        live_trace.append(power_val)
        
        # Update global progress
        # We use a special key "partial_trace" for GameMaker to poll
        current_progress["progress"] = 0.3 + (0.6 * (i / len(full_trace))) # 30% to 90%
        current_progress["partial_trace"] = live_trace 
        
        # Simulate time passing
        time.sleep(point_duration)
        
    # ------------------------------------
    
    end_time = time.time()
    latency_ms = (end_time - start_time) * 1000
    
    # STEP 4: Complete
    current_progress = {"status": "processing", "step": 4, "step_name": "Inference Complete", "progress": 1.0, "partial_trace": live_trace}
    logger.info(f"[STEP 4] Inference Complete. Latency: {latency_ms:.2f} ms")
    
    energy_joules = sum(full_trace) * (point_duration) # Simple integral
    
    response_data = {
        "runs": [
            {
                "run_id": f"run_{int(time.time())}",
                "backend": backend,
                "latency_ms": round(latency_ms, 2),
                "energy_joules": round(energy_joules, 2),
                "power_trace": full_trace,
                "text": f"Generated response for '{prompt}' using {backend}..."
            }
        ]
    }
    
    logger.info(f"[DATA] Sending {len(full_trace)} power samples to GameMaker.")
    print("\n" + "="*40)
    
    # Reset to idle after a short delay so GameMaker can see the 100% state
    time.sleep(2.0)
    current_progress = {"status": "idle", "step": 0, "step_name": "Ready", "progress": 0.0}
    
    return jsonify(response_data)

@app.route('/status', methods=['GET'])
def status():
    return jsonify(current_progress)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="GameMaker Energy Demo Server")
    parser.add_argument("--mock", action="store_true", help="Run in mock mode (no real GPU needed)")
    parser.add_argument("--port", type=int, default=5000, help="Port to run server on")
    
    args = parser.parse_args()
    
    print(f"\nStarting Energy Demo Server on port {args.port}...")
    print("Use Ctrl+C to stop.\n")
    
    if args.mock:
        logger.warning("RUNNING IN MOCK MODE - No real hardware will be accessed.")
        
    app.run(host='0.0.0.0', port=args.port)

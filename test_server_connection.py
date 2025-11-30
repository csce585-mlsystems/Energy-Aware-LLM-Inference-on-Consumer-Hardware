import subprocess
import time
import requests
import sys
import os

def test_server():
    print("Starting server...")
    # Start the server in a separate process
    server_process = subprocess.Popen(
        [sys.executable, "src/demo_server.py", "--mock", "--port", "5001"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    
    try:
        # Wait for server to start
        time.sleep(2)
        
        print("Sending request...")
        url = "http://127.0.0.1:5001/generate"
        payload = {"prompt": "Test Prompt", "backend": "cpu"}
        
        response = requests.post(url, json=payload, timeout=20)
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Success!")
            # Check trace
            trace = data['runs'][0]['power_trace']
            print(f"\nTrace Length: {len(trace)}")
            if len(trace) > 0 and sum(trace) > 0:
                print(f"✅ Trace contains data (First 5: {trace[:5]})")
            else:
                print("❌ WARNING: Trace is empty or zero!")
        else:
            print(f"❌ Error: {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"Error: {e}")
    finally:
        print("Stopping server...")
        server_process.terminate()
        server_process.wait()

if __name__ == "__main__":
    test_server()

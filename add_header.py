import os

file_path = "data/latency_results.csv"
header = "timestamp,backend,prompt_id,prompt_template,prompt_length_chars,latency_ms,tokens_generated,energy_joules,notes\n"

if os.path.exists(file_path):
    with open(file_path, "r") as f:
        content = f.read()
    
    # Check if header already exists to avoid double writing
    if not content.startswith("timestamp,backend"):
        with open(file_path, "w") as f:
            f.write(header + content)
        print("Header added.")
    else:
        print("Header already exists.")
else:
    print("File not found.")

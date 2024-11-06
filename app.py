import subprocess
import os

# List of Flask apps with their corresponding ports and hosts
host = "192.168.100.28"
apps = [
    ("botflask.py", host, 5000),  # Runs on localhost:5000  
    ("statementflask.py", host, 5001),
    ("stock_predict.py", host, 5002),
    ("login_registerflask.py",host, 5003),
    ("managementflask.py", host, 5004),
    # Add more apps as needed, with desired host and port
]

# Loop through each app and start it
processes = []
for app, host, port in apps:
    process = subprocess.Popen(
        [
            "python", "-m", "flask", "run",
            "--host", host,              # Specify the host
            "--port", str(port)          # Specify the port
        ],
        env={"FLASK_APP": app, **os.environ}
    )
    processes.append(process)
    print(f"Started {app} on {host}:{port}")

# Optional: Wait for all processes to finish (or keep the script running)
try:
    for process in processes:
        process.wait()
except KeyboardInterrupt:
    print("Shutting down all Flask apps...")
    for process in processes:
        process.terminate()

#!/bin/bash

# Define variables
PYTHON_SCRIPT="run.py"   # Replace with the name of your Python script
CHECK_INTERVAL=10                # Time interval to check the repo for updates (in seconds)
EXIT_FLAG_FILE="/tmp/exit_flag"  # File used to indicate when the script should exit

# Ensure no leftover flag file exists
rm -f "$EXIT_FLAG_FILE"

# Function to run the Python script
run_python_script() {
    python3 "$PYTHON_SCRIPT" &
    PYTHON_PID=$!
    wait "$PYTHON_PID"
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "Python script exited with code $EXIT_CODE. Setting exit flag."
        echo "true" > "$EXIT_FLAG_FILE"
    fi
}

# Trap to clean up background processes on exit
trap "kill 0; rm -f \"$EXIT_FLAG_FILE\"" EXIT

# Start the Python script initially
run_python_script &

# Monitor the GitHub repo for updates
while :; do
    if [ -f "$EXIT_FLAG_FILE" ]; then
        echo "Exit flag is set. Exiting bash script."
        exit 1
    fi

    sleep "$CHECK_INTERVAL"
    git remote update > /dev/null 2>&1

    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})

    if [ "$LOCAL" != "$REMOTE" ]; then
        echo "Updates detected in the GitHub repository. Pulling changes..."
        git pull > /dev/null 2>&1

        echo "Kill python script with PID ${PYTHON_PID}"
        kill "$PYTHON_PID" 2>/dev/null
		echo "Relaunching the Python script..."
        run_python_script &
    fi

done

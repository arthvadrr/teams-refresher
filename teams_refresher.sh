#!/bin/bash

# Variables for inactivity and refresh time amounts in seconds
INACTIVITY_LIMIT=10800  # Time before script is killed (so it doesn't prevent sleep)
REFRESH_INTERVAL=20    # 5 minutes in seconds
IDLE_THRESHOLD=20      # Idle time threshold in seconds (5 minutes)
SHOULD_SLEEP=false      # Set to true to put the system to sleep after inactivity

# Function to check for user activity by checking idle time (in seconds)
get_system_idle_time() {
    ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}'
}

# Run caffeinate in the background
caffeinate -d &
caffeinate_pid=$!

# Start time to measure the inactivity limit
start_time=$(date +%s)

while true; do
    # Check how long the script has been running
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    # Kill the script after reaching the inactivity limit
    if [ "$elapsed_time" -ge "$INACTIVITY_LIMIT" ]; then
        echo "Script terminated after $((INACTIVITY_LIMIT / 60)) minutes of inactivity"
        kill $caffeinate_pid

        if [ "$SHOULD_SLEEP" = true ]; then
          echo "Putting the system to sleep..."
          pmset sleepnow
        fi

        exit 0
    fi

    # Check user activity (captures idle time in seconds)
    idle_time=$(get_system_idle_time)

    if [ "$idle_time" -ge "$IDLE_THRESHOLD" ]; then
        # If the system has been idle for the threshold time or more
        osascript -e 'tell application "Microsoft Teams" to activate'
        osascript -e 'tell application "System Events" to keystroke "2" using {command down}'
        echo "Teams Status Refreshed"
    else
        echo "User activity detected, no action taken"
    fi

    sleep $REFRESH_INTERVAL  # Wait for the next refresh check
done
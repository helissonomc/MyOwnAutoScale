#!/bin/bash

CONTAINER_NAME_PATTERN="webappname"

MEMORY_THRESHOLD=65

CHECK_INTERVAL=10

AUTOSCALE_SCRIPT="./autoscale.sh"

TIMESTAMP_FILE="/tmp/last_autoscale_time"

AUTOSCALE_COOLDOWN=600  # 10 minutes

get_memory_usage() {
    container_name=$1
    docker stats --no-stream --format "{{.MemUsage}}" "$container_name" | awk '{print $1}' | sed 's/[^0-9.]//g'
}

# Function to get the current Unix timestamp
current_time() {
    date +%s
}

# Function to check if autoscaling can happen based on the last autoscale time
can_autoscale() {
    if [ -f "$TIMESTAMP_FILE" ]; then
        last_autoscale_time=$(cat "$TIMESTAMP_FILE")
        current_time=$(current_time)
        time_diff=$((current_time - last_autoscale_time))

        if [ "$time_diff" -lt "$AUTOSCALE_COOLDOWN" ]; then
            echo "Autoscale triggered recently ($time_diff seconds ago). Waiting for cooldown."
            return 1  # Return false (can't autoscale)
        fi
    fi
    return 0  # Return true (can autoscale)
}

# Function to trigger autoscale and update the timestamp file
trigger_autoscale() {
    echo "Memory usage is above $MEMORY_THRESHOLD MiB, triggering autoscale."
    $AUTOSCALE_SCRIPT
    current_time=$(current_time)
    echo "$current_time" > "$TIMESTAMP_FILE"  # Store the current timestamp
    echo "Autoscale triggered at $current_time"
}

check_memory() {
    docker ps --format "{{.Names}}" | grep "$CONTAINER_NAME_PATTERN" | while read -r container_name; do
        echo "Checking memory usage for container: $container_name"
        mem_usage=$(get_memory_usage "$container_name")
        mem_usage_int=${mem_usage%.*}  # Convert to integer
        echo "Memory usage for $container_name: $mem_usage MiB"

        if [ "$mem_usage_int" -gt "$MEMORY_THRESHOLD" ]; then
            can_autoscale
            if [ $? -eq 0 ]; then
                trigger_autoscale
                return  # Exit after triggering autoscale (no need to check further containers)
            else
                echo "Skipping autoscale due to cooldown period."
            fi
        fi
    done
}


# Run the script in the background indefinitely
while true; do
    check_memory
    sleep $CHECK_INTERVAL
done

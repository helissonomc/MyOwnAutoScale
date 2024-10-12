#!/bin/bash

# Source the Nginx helper file
source ./nginx_helper.sh

# Function to get the highest number for autoscale-webapp
get_highest_number() {
    docker ps --format "{{.Names}}" | grep "webappname" | sed 's/.*-//' | sort -n | tail -1
}

# Function to increment the highest number by 1
increment_number() {
    local highest=$1
    echo $((highest + 1))
}

# Function to create and run the new container
run_new_container() {
    local new_number=$1
    local new_container_name="webappname-$new_number"
    local new_port=$((8080 + new_number))
    local network=$(docker ps --format "{{.Networks}}" | tail -1)
    local image=$(docker ps --format "{{.Image}}" | grep "webapp" | tail -1)

    docker run -d --network "$network" --name "$new_container_name" -p "$new_port:8080" $image bash -c "python mywebproject/manage.py runserver 0.0.0.0:8080"

    echo "Created new container with name: $new_container_name"
}

# Function to reload the Nginx server
reload_nginx() {
    local nginx_container=$(docker ps --format "{{.Names}}" | grep "nginx" | tail -1)
    echo "Reloading nginx server..."
    docker exec "$nginx_container" nginx -s reload
    echo "Nginx server reloaded"
}

# Main script execution
highest=$(get_highest_number)
new_number=$(increment_number "$highest")
run_new_container "$new_number"

# Nginx configuration update
upstream_block=$(generate_upstream_block)
server_block=$(generate_server_block)
update_nginx_config "$upstream_block" "$server_block"

reload_nginx

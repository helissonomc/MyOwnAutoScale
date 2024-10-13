#!/bin/bash

# Function to generate the Nginx upstream block
generate_upstream_block() {
    local containers=$(docker ps --format "{{.Names}}" | grep "webapp")
    local upstream_block="upstream django_app {\n"

    # Check if there are any containers
    if [[ -z "$containers" ]]; then
        # No containers found, use the default
        upstream_block+="    server webappname-1:8080;\n"
    else
        # Iterate over each container
        while IFS= read -r container; do
            upstream_block+="    server $container:8080;\n"
        done <<< "$containers"
    fi

    upstream_block+="} \n"
    echo -e "$upstream_block"
}

# Function to generate the Nginx server block
generate_server_block() {
    echo -e "
server {
    listen 80;

    location /static/ {
        alias /static/;
    }

    location / {
        proxy_pass http://django_app;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}"
}

# Function to update the Nginx configuration
update_nginx_config() {
    local upstream_block=$1
    local server_block=$2

    local file_content="$upstream_block"
    file_content+="$server_block"

    echo "$file_content" > ./nginx/default.conf
}

#!/bin/bash

# Get the highest number for autoscale-webapp
highest=$(docker ps --format "{{.Names}}" | grep "webappname" | sed 's/.*-//' | sort -n | tail -1)

# Increment the highest number by 1
new_number=$((highest + 1))

# Create the new container name
new_container_name="webappname-$new_number"
new_port=$((8080 + new_number))

network=$(docker ps --format "{{.Networks}}" | tail -1)
image=$(docker ps --format "{{.Image}}" | grep "webapp" | tail -1)
# Run the container with the new name (you can adjust the image, command, and options as needed)
docker run -d --network "$network" --name "$new_container_name" -p "$new_port:8080" $image bash -c "python mywebproject/manage.py runserver 0.0.0.0:8080"

echo "Created new container with name: $new_container_name"

containers=$(docker ps --format "{{.Names}}" | grep "webapp")

# Generate the upstream block with all running containers
upstream_block="upstream django_app {\n"
# Iterate over each container
while IFS= read -r container; do
    upstream_block+="    server $container:8080;\n"
done <<< "$containers"
upstream_block+="} \n"

server_block="
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

file_content=$upstream_block
file_content+=$server_block
echo $file_content > ./nginx/default.conf

echo "Reloading nginx server..."
docker exec autoscale-nginx-1 nginx -s reload
echo "Nginx server reloaded"

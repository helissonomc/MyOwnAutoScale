#!/bin/bash
source ./nginx_helper.sh
chmod +x ./autoscale.sh

# Nginx configuration update
upstream_block=$(generate_upstream_block)
server_block=$(generate_server_block)
update_nginx_config "$upstream_block" "$server_block"

docker-compose up -d

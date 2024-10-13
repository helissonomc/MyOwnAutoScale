# Web App with Nginx Proxy and Docker Compose
This project sets up a web application using Docker, Nginx as a reverse proxy, and manages static files. It provides an automated setup and configuration for running a Django-based app in a containerized environment.

## Project Structure
- Dockerfile: Defines the environment for the Django web application.
- docker-compose.yml: Manages multiple services including the Django app and Nginx proxy.
- nginx_helper.sh: Script for dynamically configuring the Nginx upstream block based on running containers.
- runserver.sh: Startup script that configures Nginx and launches the services.
- autoscale.sh: Once you have your servers running you can autoscale up the webapp horizontally by running this shell.

## How to run this project
1 - First Run the server, it will format the initial nginx configuration and it will start running both webapp service and nginx service
 ```
source ./runserver.sh
```
2 - After you have your server running you can can the script below, it will start a new container and update the nginx configuration to redirect traffic for this new container as well
```
source ./autoscale.sh
```
3 - Run the curl or go to your browser and start to create requests to the port 80 (where nginx is listening to) and check the logs of the webapp container you have running, you will see the request being balanced.
```
curl http://localhost/admin/
```

It is possible to run an job that runs the background and monitor the momeory (if can be implemented to check cpu too) and if it was not scaled up in the last 10 minutes and there is any container with the memore above a set number, it will autoscale automatically, but it has a limit of 10 containers, after this it will keep running, but will not increase the number of containers with the webserver:
```
chmod +x monitor_memory.sh
nohup ./monitor_memory.sh & 
```
this will make the monitor memory script to run in the background


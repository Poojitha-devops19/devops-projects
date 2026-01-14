# Dockerize-App ## 
## 📖 Description:
A simple Node.js application containerized with Docker to demonstrate containerization basics. This guide walks through building, running, and pushing Docker images.

## 📖 Project Overview:
This project demonstrates how to containerize a simple Node.js application using Docker. It covers building Docker images, running containers, pushing images to Docker Hub, and managing containers.

**Architecture diagram:**
![Architecture Diagram](Docker flow.png)

**##🛠️ Tools and Services Used:**

Docker → Containerization platform
Docker Hub → Public image registry for storing and sharing images
Node.js  18 Alpine → Lightweight base image for running the app
Yarn → Dependency manager for Node.js
Play with Docker → labs.play-with-docker.com (or)
Docker Desktop → docker.com/products/docker-desktop

**📋 Prerequisites:**
Download Docker desktop client
https://www.docker.com/products/docker-desktop/

**📂 Repo Structure**
Dockerizing-app/
│
├── Dockerfile          # Instructions to build the Docker image
├── .dockerignore       # Files excluded from the image
├── package.json        # Node.js dependencies
├── yarn.lock           # Dependency lock file
├── src/
│   └── index.js        # Application entry point
└── README.md           # Project documentation

🚀 Quick Commands

1.Build the docker image using the application code and Dockerfile
   docker build -t imagename .
2.Verify the image has been created and stored locally using the below command:
   docker images
3.Create a public repository on hub.docker.com and push the image to remote repo
   docker login
   docker tag imagename:latest username/new-reponame:tagname
   docker images
   docker push username/new-reponame:tagname
4.To pull the image to another environment , you can use below command
   docker pull username/new-reponame:tagname
5.To start the docker container, use below command
   docker run -dp 3000:3000 username/new-reponame:tagname
6.Verify your app. If you have followed the above steps correctly, your app should be listening on localhost:3000
7.To enter(exec) into the container, use the below command
    docker exec -it containername sh
     or
    docker exec -it containerid sh
 8.To view docker logs
    docker logs containername
    or
    docker logs containerid

**🐞 Issues & Fixes**
1.Port conflict-
   Issue: Port 3000 already in use.
   Fix: Changed port mapping (-p 4000:3000).

2.Large image size
   Issue: Unnecessary files copied into the image.
   Fix: Added .dockerignore to exclude node_modules, .git, logs.






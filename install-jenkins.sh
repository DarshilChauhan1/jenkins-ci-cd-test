#!/bin/bash
set -e

echo "[*] Creating Docker network 'jenkins'..."
docker network create jenkins || echo "Network 'jenkins' already exists."

echo "[*] Starting Docker-in-Docker container..."
docker run \
  --name jenkins-docker \
  --rm \
  --detach \
  --privileged \
  --network jenkins \
  --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume jenkins-docker-certs:/certs/client \
  --volume jenkins-data:/var/jenkins_home \
  --publish 2376:2376 \
  --publish 3000:3000 \
  docker:dind \
  --storage-driver overlay2

echo "[*] Building Jenkins Blue Ocean image..."
docker build -t myjenkins-blueocean:2.504.3-1 .

echo "[*] Removing old Jenkins Blue Ocean container (if exists)..."
docker rm -f jenkins-blueocean 2>/dev/null || true

echo "[*] Starting Jenkins Blue Ocean container..."
docker run --name jenkins-blueocean --restart=on-failure --detach \
  --network jenkins \
  --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client \
  --env DOCKER_TLS_VERIFY=1 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  --publish 8080:8080 --publish 50000:50000 \
  myjenkins-blueocean:2.504.3-1

echo "[✅] Jenkins is available at: http://localhost:8080"

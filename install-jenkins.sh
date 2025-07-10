#!/bin/bash
set -e

echo "[*] Creating Docker volume for Jenkins..."
docker volume inspect jenkins_home >/dev/null 2>&1 || docker volume create jenkins_home

echo "[*] Starting Jenkins container with access to host Docker..."
docker run -d \
  --name jenkins \
  --restart=unless-stopped \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

echo "[✅] Jenkins is running at: http://<EC2_PUBLIC_IP>:8080"
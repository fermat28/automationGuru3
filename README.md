# Video Streaming Platform Deployment

> This project sets up a 2-tier video streaming architecture on AWS using Terraform and Ansible.

## Table of Contents
* [General Information](#general-information)
* [Technologies Used](#technologies-used)
* [Architecture Overview](#architecture-overview)
* [Prerequisites](#prerequisites)
* [Setup](#setup)
* [How it Works](#how-it-works)
* [Security](#security)

## General Information
- This project automates the deployment of a basic live streaming platform with one public-facing frontend instance running NGINX and RTMP, and one private backend instance using FFmpeg for stream ingestion and processing.
- It demonstrates infrastructure as code (IaC) using Terraform and configuration management using Ansible.

## Technologies Used
- Terraform - v1.5+
- Ansible - v2.10+
- AWS EC2
- NGINX with RTMP module
- FFmpeg
- Certbot / Let's Encrypt

## Architecture Overview
- **Frontend (Public):**
  - Hosts NGINX with the RTMP module.
  - Accepts RTMP streams and serves HLS/DASH output.
  - HTTPS secured with Let's Encrypt certificates.

- **Backend (Private):**
  - Uses FFmpeg to push RTMP streams to the frontend.

- The frontend acts as a NAT instance to allow the private backend to access the internet if needed (e.g., to install packages).

## Prerequisites
- A Linux environment (Ubuntu or similar).
- AWS credentials configured (`aws configure`) with permissions to create EC2, VPC, etc.
- Terraform installed.
- Ansible installed.
- `dos2unix` installed.

## Setup
1. Clone the project:
   ```bash
   git clone https://github.com/fermat28/automationGuru3.git
   cd automationGuru3

2. Deploy Platform:  

   Make the script executable, convert it to Unix format, then run it:
    ```bash
    chmod +x deploy.sh
    dos2unix deploy.sh
    ./deploy.sh
    ```

## How It Works

When you execute the deployment script, the entire infrastructure and application setup process is automated through Terraform and Ansible playbooks working together. Here's a detailed explanation of what happens step-by-step:

### 1. Infrastructure Provisioning with Terraform

- **AWS resources are created:**
  - A VPC with a **public subnet** (for the frontend) and a **private subnet** (for the backend).
  - Security Groups configured to restrict access:
    - Frontend: public access to HTTP (80) for packages installation, HTTPS (443) for users public access, SSH (22) for administration.
    - Backend: SSH access limited only from frontend subnet, RTMP traffic allowed only between backend and frontend.
  - A NAT Gateway enabling the backend private subnet instances to access the internet securely for updates, without exposing them publicly.
  - EC2 instances:
    - **Frontend instance:** Ubuntu server in the public subnet with a public IP.
    - **Backend instance:** Ubuntu server in the private subnet without a public IP.
  - Route53 DNS record is created, pointing your domain to the frontend’s public IP.

- **Dynamic Ansible inventory and variable files generation:**
  - Terraform automatically generates the Ansible inventory file with the correct frontend public IP and backend private IP.
  - It also generates a generic variable file (`generic.yml`) containing the domain name, frontend private IP, and backend subnet CIDR, ensuring playbooks have up-to-date configuration.

---

### 2. Ansible Playbooks Execution

After infrastructure provisioning, the Ansible playbooks run to install, configure, and start all necessary services on the servers.

#### `frontend-install.yaml`

- **Goal:** Setup the frontend streaming server.
- **Actions performed:**
  - Installs packages: `nginx`, `ffmpeg`, and `libnginx-mod-rtmp` for RTMP support.
  - Creates necessary directories for streaming content (`/var/www/html/stream` with subfolders `hls` and `dash`), with proper ownership and permissions.
  - Removes the default NGINX site configuration to prevent conflicts.
  - Deploys customized NGINX main config and streaming virtual host configuration (`nginx.conf` and `streamer.conf`), enabling RTMP ingest and serving HLS/DASH streams.
  - Deploys a custom `index.html` as the homepage of the streaming site.
  - Restarts NGINX automatically when configurations change.

This configures the frontend as the main entry point for ingesting RTMP streams and distributing adaptive streaming content via HTTP(S).

---

#### `deploy-website.yaml`

- **Goal:** Setup the Streaming Web Page.
- **Actions performed:**
  - Deploys a custom `index.html` as the homepage of the streaming site.

This configures the frontend an adaptive webpage of the streaming platform allowing to update the design without impacting other services.

---

#### `deploy-certificate.yml`

- **Goal:** Enable HTTPS with a trusted SSL certificate on the frontend.
- **Actions performed:**
  - Installs `certbot` and the Route53 DNS plugin via Snap.
  - Configures certbot permissions to run smoothly.
  - Requests and installs a Let's Encrypt SSL certificate for the configured domain, automatically handling HTTP to HTTPS redirection.
  - Restarts NGINX to apply the SSL certificate.

This playbook secures the frontend website and streaming endpoints with SSL encryption.

---

#### `backend-install.yaml`

- **Goal:** Setup the backend streaming source server.
- **Actions performed:**
  - Installs backend packages: `ffmpeg` for video encoding and `unzip` for handling compressed video files.
  - Creates a `/videos` directory to store media.
  - Downloads a sample video (Big Buck Bunny) archive if not already present.
  - Extracts the video file to the `/videos` directory.
  - Creates a shell script that continuously streams the video using FFmpeg to the frontend’s RTMP server (`rtmp://<frontend_private_ip>:1935/live/stream`).
  - Defines and enables a systemd service to run the streaming script persistently, restarting automatically on failure or reboot.
  - Starts the streaming service.

This configures the backend as a dedicated video streamer, pushing a live stream continuously to the frontend RTMP endpoint.


## Security

Here are the main security measures implemented in this infrastructure:

- **Network isolation using VPC and public/private subnets**  
  The backend resides in a private subnet, inaccessible directly from the internet. The frontend is in a public subnet, accessible only through the necessary ports.

- **Strictly configured Security Groups**  
  - Frontend: HTTPS (443), HTTP (80), SSH (22) open for administration; RTMP (1935) only allowed from the private subnet (backend)   
  - Backend: SSH access limited to the public subnet (frontend), RTMP traffic allowed only to the frontend, outbound HTTP/HTTPS allowed for updates

- **NAT Gateway to allow the private backend to access the internet outbound only**  
  This prevents any unauthorized inbound access to the backend.

- **Secure SSH key management**  
  The SSH private key is dynamically generated by Terraform (`tls_private_key`), stored locally with strict permissions (`0600`), and the public key is registered on AWS (`aws_key_pair`).

- **Use of official, up-to-date Ubuntu AMIs**  
  Ensures the operating system is current with the latest security patches.

- **Route53 configured with a low TTL for the domain name**  
  Allows quick DNS routing control and facilitates fast updates in case of failover.

- **Source/destination check disabled on instances**  
  Necessary for NAT Gateway and routing, while maintaining control over traffic.


# Running Aider in gVisor: A Secure Alternative to MicroVMs

## Overview

This tutorial shows how to use gVisor as an alternative to the Firecracker microVM setup for running Aider in a secure, isolated environment. gVisor provides strong isolation similar to VMs but with the simplicity of containers and Docker Compose.

## Why gVisor as an Alternative?

**Advantages over Firecracker microVMs:**
- **Simpler setup**: No kernel images, no rootfs building, no Ansible playbooks
- **Docker-native**: Use familiar Docker Compose workflows
- **Faster setup**: Minutes instead of hours
- **Lower operational overhead**: No separate VM management, no Tailscale networking complexity
- **Same security model**: Application kernel isolation without VM overhead

**What you gain:**
- Simple `docker-compose up` to start Aider
- Automatic workspace mounting at same path
- Built-in networking (no bridge/NAT configuration)
- Easy API key management via environment files
- Browser-based chat interface

**What you keep:**
- Strong isolation (gVisor's application kernel)
- Secure API key handling
- Database access for testing
- GitHub SSH key injection

## Prerequisites

### 1. Install gVisor Runtime

```bash
# Install runsc (gVisor's OCI runtime)
(
  set -e
  ARCH=$(uname -m)
  URL=https://storage.googleapis.com/gvisor/releases/release/latest/${ARCH}
  wget ${URL}/runsc ${URL}/runsc.sha512 \
    ${URL}/containerd-shim-runsc-v1 ${URL}/containerd-shim-runsc-v1.sha512
  sha512sum -c runsc.sha512 \
    -c containerd-shim-runsc-v1.sha512
  rm -f *.sha512
  chmod a+rx runsc containerd-shim-runsc-v1
  sudo mv runsc containerd-shim-runsc-v1 /usr/local/bin
)
```

### 2. Configure Docker to Use gVisor

```bash
# Add gVisor runtime to Docker daemon
sudo tee /etc/docker/daemon.json <<EOF
{
  "runtimes": {
    "runsc": {
      "path": "/usr/local/bin/runsc",
      "runtimeArgs": [
        "--platform=systrap"
      ]
    }
  }
}
EOF

# Restart Docker
sudo systemctl restart docker

# Verify gVisor is available
docker run --rm --runtime=runsc hello-world
```

## Project Structure

```
aider-gvisor/
├── docker-compose.yml          # Main orchestration file
├── .env                        # API keys (gitignored)
├── Dockerfile.aider            # Custom Aider image
├── workspace/                  # Your code (mounted)
└── .ssh/                       # GitHub SSH keys (optional)
```

## Step 1: Create the Aider Dockerfile

Create `Dockerfile.aider`:

```dockerfile
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    openssh-client \
    build-essential \
    postgresql-client \
    redis-tools \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Aider and testing tools
RUN pip install --no-cache-dir \
    aider-chat \
    pytest \
    pytest-asyncio \
    pytest-cov \
    psycopg2-binary \
    redis \
    httpx

# Create non-root user
RUN useradd -m -s /bin/bash agent && \
    mkdir -p /workspace && \
    chown agent:agent /workspace

# Set up SSH directory
RUN mkdir -p /home/agent/.ssh && \
    chmod 700 /home/agent/.ssh && \
    chown agent:agent /home/agent/.ssh

USER agent
WORKDIR /workspace

# Expose port for Aider's browser interface
EXPOSE 8501

# Default command: run Aider in browser mode
CMD ["aider", "--browser"]
```

## Step 2: Create Docker Compose Configuration

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  aider:
    build:
      context: .
      dockerfile: Dockerfile.aider
    runtime: runsc  # Use gVisor for isolation
    container_name: aider-secure
    
    # Mount workspace at same absolute path as host
    volumes:
      - ${WORKSPACE_PATH}:${WORKSPACE_PATH}
      - ./ssh-keys:/home/agent/.ssh:ro  # Optional: GitHub SSH keys
    
    # Set working directory to match host path
    working_dir: ${WORKSPACE_PATH}
    
    # Environment variables for API keys
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      
      # Database connection (if needed for tests)
      - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/testdb
      - REDIS_URL=redis://redis:6379
      
      # Aider configuration
      - AIDER_MODEL=claude-sonnet-4-20250514
      - AIDER_DARK_MODE=true
    
    # Expose Aider's browser interface
    ports:
      - "8501:8501"  # Streamlit UI
    
    # Network access for API calls and database
    networks:
      - aider-network
    
    # Security options (gVisor provides isolation, but add defense-in-depth)
    security_opt:
      - no-new-privileges:true
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
    
    # Restart policy
    restart: unless-stopped

  # Optional: PostgreSQL for integration tests
  postgres:
    image: postgres:16-alpine
    runtime: runsc
    container_name: aider-postgres
    environment:
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=testdb
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - aider-network
    ports:
      - "5432:5432"

  # Optional: Redis for caching/testing
  redis:
    image: redis:7-alpine
    runtime: runsc
    container_name: aider-redis
    networks:
      - aider-network
    ports:
      - "6379:6379"

networks:
  aider-network:
    driver: bridge

volumes:
  postgres-data:
```

## Step 3: Create Environment Configuration

Create `.env` file (add to `.gitignore`):

```bash
# API Keys (never commit these!)
ANTHROPIC_API_KEY=sk-ant-xxxxx
OPENAI_API_KEY=sk-xxxxx
GITHUB_TOKEN=ghp_xxxxx

# Workspace path (absolute path on host)
WORKSPACE_PATH=/home/user/my-project

# Database password
POSTGRES_PASSWORD=secure_password_here
```

Create `.env.example` (safe to commit):

```bash
# API Keys
ANTHROPIC_API_KEY=your_anthropic_key_here
OPENAI_API_KEY=your_openai_key_here
GITHUB_TOKEN=your_github_token_here

# Workspace path (absolute path to your project)
WORKSPACE_PATH=/absolute/path/to/your/project

# Database password
POSTGRES_PASSWORD=your_secure_password
```

## Step 4: Set Up GitHub SSH Keys (Optional)

```bash
# Create SSH keys directory
mkdir -p ssh-keys

# Generate SSH key for GitHub access
ssh-keygen -t ed25519 -f ssh-keys/id_ed25519 -N "" -C "aider-gvisor"

# Create SSH config
cat > ssh-keys/config <<EOF
Host github.com
    HostName github.com
    User git
    IdentityFile /home/agent/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
EOF

# Set proper permissions
chmod 600 ssh-keys/id_ed25519
chmod 644 ssh-keys/id_ed25519.pub ssh-keys/config

# Add public key to GitHub
cat ssh-keys/id_ed25519.pub
# Go to https://github.com/settings/keys and add the key
```

## Step 5: Usage Examples

### Basic Usage: Start Aider with Browser Interface

```bash
# Set your workspace path
export WORKSPACE_PATH=$(pwd)/my-project

# Start Aider in gVisor container
docker-compose up -d

# View logs
docker-compose logs -f aider

# Open browser to http://localhost:8501
# You'll see Aider's chat interface
```

### Run Aider in Watch Mode

Modify `docker-compose.yml` to add watch mode:

```yaml
services:
  aider:
    # ... existing configuration ...
    command: ["aider", "--watch", "--yes-always", "--browser"]
```

Then:

```bash
docker-compose up -d
```

Aider will now:
- Watch for file changes in your workspace
- Automatically apply suggestions
- Show progress in browser interface

### Run Aider in CLI Mode (Interactive)

```bash
# Start container with CLI instead of browser
docker-compose run --rm aider aider --model claude-sonnet-4-20250514

# Or attach to running container
docker-compose exec aider bash
# Inside container:
aider --model claude-sonnet-4-20250514
```

### Run Tests with Database Access

```bash
# Start all services (including PostgreSQL)
docker-compose up -d

# Run pytest inside container
docker-compose exec aider pytest

# Or with specific test file
docker-compose exec aider pytest tests/test_integration.py -v
```

### Multiple Projects

Create separate compose files for each project:

```bash
# Project A
cd ~/project-a
cp ~/aider-gvisor/docker-compose.yml .
echo "WORKSPACE_PATH=$(pwd)" > .env
docker-compose up -d

# Project B
cd ~/project-b
cp ~/aider-gvisor/docker-compose.yml .
echo "WORKSPACE_PATH=$(pwd)" > .env
docker-compose up -d

# List all running Aider instances
docker ps --filter "name=aider"
```

## Comparison: MicroVM vs gVisor

### What This Replaces

**Firecracker MicroVM Approach:**
```bash
# Complex setup
cd build/playbooks/microvm
ansible-playbook build.yml  # 15+ minutes

# Start VM
microvm run aider ~/my-project

# Manage VMs
microvm ls
microvm stop my-project-aider
```

**gVisor Approach:**
```bash
# Simple setup
docker-compose up -d  # 30 seconds

# Manage containers
docker-compose ps
docker-compose stop
```

### Feature Comparison

| Feature | MicroVM (Firecracker) | gVisor (Docker) |
|---------|----------------------|-----------------|
| **Setup Time** | 15+ minutes (Ansible) | 2 minutes (Docker) |
| **Startup Time** | ~125ms | ~100ms |
| **Isolation** | Hardware VM | Application kernel |
| **Security** | Excellent | Excellent |
| **Complexity** | High (kernel, rootfs, network) | Low (Docker Compose) |
| **Workspace Sync** | virtio-fs/9p | Docker volumes |
| **Networking** | Tailscale/bridge | Docker networks |
| **API Keys** | Environment proxy | Environment variables |
| **Database Access** | Tailscale hostnames | Docker service names |
| **GitHub Access** | SSH key injection | SSH key mounting |
| **Resource Usage** | ~5MB overhead | ~5MB overhead |
| **Management** | Custom `microvm` CLI | Docker Compose |

## Advanced Configuration

### Custom Aider Configuration

Create `aider-config.yml` and mount it:

```yaml
# aider-config.yml
model: claude-sonnet-4-20250514
dark-mode: true
auto-commits: true
dirty-commits: false
attribute-author: true
attribute-committer: false
```

Update `docker-compose.yml`:

```yaml
services:
  aider:
    volumes:
      - ./aider-config.yml:/home/agent/.aider.conf.yml:ro
```

### Add More Development Tools

Extend `Dockerfile.aider`:

```dockerfile
# Add Node.js for frontend projects
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Add Rust for systems programming
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Add Go for backend services
RUN wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz && \
    rm go1.21.0.linux-amd64.tar.gz
```

### Enable gVisor Debug Mode

For troubleshooting, enable debug logging:

```yaml
services:
  aider:
    runtime: runsc
    security_opt:
      - "runsc-debug-log=/tmp/runsc/"
```

View logs:
```bash
sudo cat /tmp/runsc/runsc.log.*
```

### Resource Monitoring

Monitor gVisor container resources:

```bash
# Real-time stats
docker stats aider-secure

# Detailed inspection
docker inspect aider-secure

# gVisor-specific metrics
sudo runsc --root=/var/run/docker/runtime-runsc/moby \
  events --stats aider-secure
```

## Security Considerations

### What gVisor Provides

1. **Application Kernel Isolation**: System calls don't reach host kernel
2. **Memory Safety**: Written in Go, no buffer overflows
3. **Reduced Attack Surface**: Minimal host kernel interaction
4. **Seccomp Filtering**: Additional defense-in-depth

### Additional Hardening

```yaml
services:
  aider:
    # Read-only root filesystem
    read_only: true
    tmpfs:
      - /tmp
      - /home/agent/.cache
    
    # Drop all capabilities
    cap_drop:
      - ALL
    
    # No new privileges
    security_opt:
      - no-new-privileges:true
    
    # User namespace remapping
    user: "1000:1000"
```

### API Key Protection

Unlike the microVM environment proxy, gVisor uses standard Docker secrets:

```yaml
services:
  aider:
    environment:
      - ANTHROPIC_API_KEY_FILE=/run/secrets/anthropic_key
    secrets:
      - anthropic_key

secrets:
  anthropic_key:
    file: ./secrets/anthropic_api_key.txt
```

## Troubleshooting

### gVisor Not Working

```bash
# Check if runsc is installed
which runsc

# Test gVisor runtime
docker run --rm --runtime=runsc alpine echo "gVisor works!"

# Check Docker daemon configuration
cat /etc/docker/daemon.json

# View Docker logs
sudo journalctl -u docker -f
```

### Container Won't Start

```bash
# Check logs
docker-compose logs aider

# Inspect container
docker inspect aider-secure

# Check gVisor logs
sudo cat /tmp/runsc/runsc.log.*

# Try without gVisor to isolate issue
docker-compose run --rm --runtime=runc aider bash
```

### Workspace Not Syncing

```bash
# Verify volume mount
docker inspect aider-secure | jq '.[0].Mounts'

# Check permissions
ls -la ${WORKSPACE_PATH}

# Test write access
docker-compose exec aider touch /workspace/test.txt
ls -la ${WORKSPACE_PATH}/test.txt
```

### Performance Issues

```bash
# Switch to different gVisor platform
# Edit /etc/docker/daemon.json:
{
  "runtimes": {
    "runsc": {
      "path": "/usr/local/bin/runsc",
      "runtimeArgs": [
        "--platform=kvm"  # Use KVM instead of systrap
      ]
    }
  }
}

# Restart Docker
sudo systemctl restart docker
```

## Migration from MicroVM

### Step-by-Step Migration

1. **Export your current setup:**
```bash
# Document your microVM configuration
microvm inspect my-project-aider > microvm-config.json
```

2. **Create equivalent Docker Compose:**
```bash
# Use workspace path from microVM
export WORKSPACE_PATH=$(jq -r '.workspace' microvm-config.json)
```

3. **Copy SSH keys:**
```bash
# Extract SSH keys from microVM rootfs
mkdir -p ssh-keys
# Copy from your microVM setup
```

4. **Test gVisor setup:**
```bash
docker-compose up -d
docker-compose logs -f
```

5. **Verify functionality:**
```bash
# Test Aider works
docker-compose exec aider aider --help

# Test database access
docker-compose exec aider psql $DATABASE_URL -c "SELECT 1"

# Test GitHub access
docker-compose exec aider ssh -T git@github.com
```

6. **Optional: Clean up microVM:**
```bash
microvm stop my-project-aider
microvm rm my-project-aider
# Optional: remove microVM infrastructure
# rm -rf build/playbooks/microvm/.microvm
```

## When to Use Each Approach

### Use gVisor When:
- You want simplicity and Docker integration
- You're comfortable with container workflows
- You need quick setup and iteration
- You want to leverage existing Docker tooling
- You're running on a system with Docker already

### Use Firecracker MicroVMs When:
- You need true hardware virtualization
- You're building a multi-tenant platform
- You need the absolute strongest isolation
- You want fine-grained control over the kernel
- You're integrating with existing Tailscale infrastructure

## Next Steps

1. **Add CI/CD Integration:**
   - Use gVisor in GitHub Actions
   - Run tests in isolated containers
   - Deploy with Docker Compose

2. **Create Project Templates:**
   - Python projects with pytest
   - Node.js projects with Jest
   - Full-stack projects with multiple services

3. **Implement Monitoring:**
   - Add Prometheus metrics
   - Create Grafana dashboards
   - Set up alerting

4. **Scale Horizontally:**
   - Run multiple Aider instances
   - Load balance with Traefik
   - Share database across instances

## Conclusion

gVisor provides an excellent alternative to the Firecracker microVM setup with different trade-offs:

**gVisor Advantages:**
- ✅ **Simpler setup**: Docker Compose instead of Ansible
- ✅ **Faster workflow**: `docker-compose up` vs `microvm run`
- ✅ **Better integration**: Works with existing Docker tools
- ✅ **Lower complexity**: No kernel images, no rootfs building

**Firecracker Advantages:**
- ✅ **True hardware isolation**: Full VM security model
- ✅ **Tailscale integration**: Direct cluster access
- ✅ **Fine-grained control**: Custom kernel and rootfs
- ✅ **Production-proven**: Used by AWS Lambda

Both approaches provide strong isolation for agentic coding workloads. Choose based on your specific needs for simplicity vs. control.

## References

- [gVisor Documentation](https://gvisor.dev/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Aider Documentation](https://aider.chat/)
- [Firecracker MicroVM Setup](MICROVM_AGENTIC_CODING_SETUP.md)

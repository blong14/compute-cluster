# Compute Cluster Deployment Guide

## Overview

The compute cluster uses a custom Go CLI tool that wraps Ansible playbook execution to deploy and manage services across a 5-node hybrid infrastructure (1 AMD64 controller + 4 ARM64 Raspberry Pi workers). This guide explains how to deploy services like Ollama, PostgreSQL, JupyterHub, and the 20+ other services running on the cluster.

### Deployment Architecture

- **CLI Tool**: Go-based command-line interface (`cluster`)
- **Automation**: Ansible playbooks for service orchestration
- **Orchestration**: Kubernetes (K3s) for container management
- **Configuration**: Encrypted Ansible vault for sensitive data
- **Multi-Architecture**: Automatic ARM64/AMD64 build support
- **Package Management**: Helm charts for Kubernetes deployments

## Prerequisites

Before deploying services, ensure you have:

1. **Python Environment**
   ```bash
   source venv/bin/activate
   pip install -r requirements.txt -c constraints.txt
   ```

2. **Ansible Installation**
   - Ansible 12.3.0+ with ansible-core 2.19.5+ (included in requirements.txt)
   - Vault password access for encrypted services

3. **Cluster Access**
   - `kubectl` configured with cluster credentials
   - SSH access to cluster nodes (user: `pi`)
   - K3s kubeconfig at `/etc/rancher/k3s/k3s.yaml`
   - Appropriate permissions for deployment

4. **CLI Tool**
   - The `cluster` binary built and in your PATH
   - Configuration file properly set up

5. **Helm**
   - Helm 3.x installed on the controller node
   - Used for deploying services via charts

## Basic Deployment Command

The standard deployment syntax is:

```bash
cluster deploy <service-name>
```

### Example: Deploying Ollama

Here's a complete walkthrough of deploying the Ollama AI service:

```bash
# 1. Ensure prerequisites are met
source venv/bin/activate

# 2. Deploy Ollama
cluster deploy ollama

# 3. Verify deployment
kubectl get pods -l app=ollama

# 4. Check service status
kubectl get svc ollama
```

**What happens during deployment:**
1. CLI tool locates the playbook at `build/playbooks/ollama/build.yml`
2. Ansible connects to the `amd-build` host (controller node) as user `pi`
3. Repository is cloned/updated to `/home/pi/compute-cluster`
4. Helm installs/upgrades the Ollama chart from `build/charts/ollama`
5. Kubernetes resources are created/updated using K3s kubeconfig
6. Multi-architecture images are pulled for appropriate nodes
7. Service is exposed and health checks are performed

### Understanding the Ollama Deployment

The Ollama playbook demonstrates the standard deployment pattern:

```yaml
---
- name: Deploy ollama
  hosts: amd-build              # Targets the AMD64 controller
  remote_user: pi               # SSH user for connection
  tasks:
    - name: Ensure Helm
      become: yes
      become_method: sudo
      command: helm version     # Verify Helm is available
    
    - name: Copy src
      ansible.builtin.git:
        repo: https://github.com/blong14/compute-cluster.git
        dest: /home/pi/compute-cluster
        single_branch: yes
        version: main           # Always use main branch
    
    - name: Install ollama
      become: yes
      become_method: sudo
      command: |
        helm upgrade -i ollama compute-cluster/build/charts/ollama \
        --kubeconfig /etc/rancher/k3s/k3s.yaml
```

## Service Catalog

### AI/ML Services

#### Ollama
- **Description**: Local LLM inference server
- **Architecture**: Multi-arch (ARM64/AMD64)
- **Resources**: High memory requirement
- **Deployment**: Helm chart
- **Command**: `cluster deploy ollama`
- **Vault Required**: No
- **Chart Location**: `build/charts/ollama`

#### JupyterHub
- **Description**: Multi-user Jupyter notebook server
- **Architecture**: Multi-arch
- **Resources**: Medium CPU/memory
- **Command**: `cluster deploy jupyterhub`
- **Vault Required**: No

### Communication Services

#### Rocket.Chat
- **Description**: Team collaboration platform
- **Architecture**: AMD64 (requires MongoDB)
- **Resources**: Medium CPU/memory, high storage
- **Deployment**: Helm chart with MongoDB dependency
- **Command**: `cluster deploy rocket.chat`
- **Vault Required**: No
- **Special Notes**: 
  - Includes MongoDB with authentication
  - Node affinity set to AMD64 architecture
  - MongoDB credentials: user `rocketchat`, root password `rocketchatroot`

### Database Services

#### PostgreSQL
- **Description**: Relational database
- **Architecture**: Multi-arch
- **Resources**: Medium storage/memory
- **Command**: `cluster deploy postgres`
- **Vault Required**: No

#### CockroachDB
- **Description**: Distributed SQL database
- **Architecture**: Multi-arch
- **Resources**: High storage/CPU
- **Command**: `cluster deploy cockroach`
- **Vault Required**: No

#### RabbitMQ
- **Description**: Message queue broker
- **Architecture**: Multi-arch
- **Resources**: Medium memory
- **Command**: `cluster deploy rabbitmq`
- **Vault Required**: No

#### MongoDB (via Rocket.Chat)
- **Description**: Document database
- **Architecture**: AMD64
- **Resources**: Medium storage/memory
- **Deployment**: Embedded in Rocket.Chat chart
- **Authentication**: Enabled by default

### Monitoring & Management

#### Scrutiny
- **Description**: Hard drive health monitoring
- **Architecture**: Multi-arch
- **Resources**: Low
- **Command**: `cluster deploy scrutiny`
- **Vault Required**: Yes (encrypted config)

#### Collector
- **Description**: Metrics collection service
- **Architecture**: Multi-arch
- **Resources**: Low
- **Command**: `cluster deploy collector`
- **Vault Required**: Yes (encrypted config)

#### Mercure
- **Description**: Real-time communication hub
- **Architecture**: Multi-arch
- **Resources**: Low
- **Command**: `cluster deploy mercure`
- **Vault Required**: Yes (encrypted config)

#### LogConsumer
- **Description**: Log aggregation service
- **Architecture**: Multi-arch
- **Resources**: Medium
- **Command**: `cluster deploy logconsumer`
- **Vault Required**: Yes (encrypted config)

## Vault-Encrypted Services

Some services require Ansible vault passwords for encrypted configuration files. These services will prompt for the vault password during deployment:

- **collector**
- **logconsumer**
- **mercure**
- **scrutiny**

### Deploying Vault-Protected Services

```bash
# The CLI will automatically prompt for vault password
cluster deploy scrutiny

# Enter vault password when prompted
# Deployment proceeds with decrypted configuration
```

### Vault Configuration Location

Encrypted configs are stored at:
```
build/playbooks/<service>/cfg.enc
```

## Deployment Workflow

### Pre-Deployment Checklist

1. **Verify Cluster Health**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

2. **Check Resource Availability**
   ```bash
   kubectl top nodes
   kubectl describe nodes
   ```

3. **Review Service Dependencies**
   - Ensure dependent services are running
   - Check for required persistent volumes
   - Verify network policies
   - For Rocket.Chat: MongoDB will be deployed automatically

4. **Backup Existing Data** (if updating)
   ```bash
   # For databases and stateful services
   kubectl exec <pod-name> -- backup-command
   ```

5. **Verify Helm Installation**
   ```bash
   # On the controller node
   ssh pi@controller-node
   helm version
   ```

### Deployment Execution

1. **Activate Python Environment**
   ```bash
   source venv/bin/activate
   ```

2. **Run Deployment Command**
   ```bash
   cluster deploy <service-name>
   ```

3. **Monitor Deployment Progress**
   ```bash
   # Watch pod creation
   kubectl get pods -w
   
   # Check deployment status
   kubectl rollout status deployment/<service-name>
   
   # For Helm deployments, check release status
   helm list --kubeconfig /etc/rancher/k3s/k3s.yaml
   ```

### Post-Deployment Verification

1. **Check Pod Status**
   ```bash
   kubectl get pods -l app=<service-name>
   kubectl describe pod <pod-name>
   ```

2. **Verify Service Endpoints**
   ```bash
   kubectl get svc <service-name>
   kubectl get ingress
   ```

3. **Test Service Functionality**
   ```bash
   # Example for Ollama
   curl http://ollama-service:11434/api/tags
   
   # Example for PostgreSQL
   kubectl exec -it postgres-pod -- psql -U postgres -c '\l'
   
   # Example for Rocket.Chat
   curl http://rocket-chat-service:3000
   ```

4. **Check Logs**
   ```bash
   kubectl logs <pod-name>
   kubectl logs <pod-name> --previous  # For crashed pods
   
   # For Helm deployments
   kubectl logs -l app=<service-name>
   ```

5. **Verify Helm Release**
   ```bash
   helm status <service-name> --kubeconfig /etc/rancher/k3s/k3s.yaml
   ```

## Multi-Architecture Considerations

The cluster supports both AMD64 (controller) and ARM64 (Raspberry Pi workers) architectures.

### Node Affinity

Services can specify architecture requirements in their Helm values:

```yaml
# Example from Rocket.Chat values.yml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/arch
              operator: In
              values:
                - amd64  # Requires AMD64 architecture
```

**Architecture Assignment:**
- **Controller (AMD64)**: High-resource services, databases requiring AMD64, Rocket.Chat
- **Workers (ARM64)**: Distributed workloads, AI inference, multi-arch services

### Image Selection

Helm charts and playbooks automatically select the correct image architecture:
- Multi-arch manifests are preferred
- Architecture-specific images are used when necessary
- Kubernetes pulls the appropriate variant based on node architecture

### Resource Allocation

ARM64 workers have different resource profiles:
- **CPU**: 4 cores per Pi
- **Memory**: 8GB per Pi
- **Storage**: SD card or USB-attached

AMD64 controller typically has more resources for demanding services.

## Advanced Deployment Topics

### Custom Configuration with Helm Values

To customize a service deployment using Helm values:

1. **Locate the values file**
   ```bash
   cd build/playbooks/<service>/
   cat values.yml  # Or values.yml.enc for encrypted
   ```

2. **Review configuration options**
   ```yaml
   # Example: Rocket.Chat values.yml
   mongodb:
     enabled: true
     auth:
       passwords:
         - rocketchat
       rootPassword: rocketchatroot
   
   affinity:
     nodeAffinity:
       requiredDuringSchedulingIgnoredDuringExecution:
         nodeSelectorTerms:
           - matchExpressions:
               - key: kubernetes.io/arch
                 operator: In
                 values:
                   - amd64
   ```

3. **Modify values** (if not encrypted)
   ```yaml
   # Customize resource limits, replicas, etc.
   resources:
     limits:
       memory: "2Gi"
       cpu: "1000m"
   ```

4. **Deploy with custom config**
   ```bash
   cluster deploy <service>
   ```

### Managing Encrypted Configurations

#### Viewing Encrypted Config
```bash
ansible-vault view build/playbooks/<service>/cfg.enc
```

#### Editing Encrypted Config
```bash
ansible-vault edit build/playbooks/<service>/cfg.enc
```

#### Creating New Encrypted Config
```bash
ansible-vault create build/playbooks/<service>/cfg.enc
```

### Working with Helm Charts Directly

For advanced users who want to bypass the CLI:

```bash
# SSH to controller node
ssh pi@controller-node

# Navigate to chart directory
cd /home/pi/compute-cluster/build/charts/<service>

# Install/upgrade with custom values
sudo helm upgrade -i <service-name> . \
  --kubeconfig /etc/rancher/k3s/k3s.yaml \
  --values custom-values.yml

# Check release
sudo helm list --kubeconfig /etc/rancher/k3s/k3s.yaml
```

### Rolling Updates

To update a running service:

```bash
# 1. Deploy updated version
cluster deploy <service>

# 2. Monitor rollout
kubectl rollout status deployment/<service>

# 3. Verify new version
kubectl get pods -l app=<service> -o jsonpath='{.items[0].spec.containers[0].image}'

# 4. Check Helm release history
helm history <service> --kubeconfig /etc/rancher/k3s/k3s.yaml
```

### Rollback Procedures

If a deployment fails or causes issues:

#### Kubernetes Rollback
```bash
# 1. Rollback Kubernetes deployment
kubectl rollout undo deployment/<service>

# 2. Verify rollback
kubectl rollout status deployment/<service>

# 3. Check pod status
kubectl get pods -l app=<service>
```

#### Helm Rollback
```bash
# 1. SSH to controller
ssh pi@controller-node

# 2. View release history
sudo helm history <service> --kubeconfig /etc/rancher/k3s/k3s.yaml

# 3. Rollback to previous revision
sudo helm rollback <service> --kubeconfig /etc/rancher/k3s/k3s.yaml

# 4. Or rollback to specific revision
sudo helm rollback <service> <revision-number> --kubeconfig /etc/rancher/k3s/k3s.yaml
```

#### Complete Rollback with Configuration
```bash
# 1. Restore previous configuration from git
git checkout HEAD~1 build/playbooks/<service>/

# 2. Redeploy
cluster deploy <service>
```

## Deployment Order Recommendations

When deploying multiple services, follow this order to respect dependencies:

### Phase 1: Infrastructure Services
1. **Storage**: Persistent volume provisioners
2. **Networking**: Network policies, ingress controllers
3. **Secrets**: Vault, secret management

### Phase 2: Core Services
1. **Databases**: PostgreSQL, CockroachDB
2. **Message Queues**: RabbitMQ
3. **Monitoring**: Scrutiny, Collector

### Phase 3: Application Services
1. **AI/ML**: Ollama, JupyterHub
2. **Communication**: Rocket.Chat (includes MongoDB)
3. **Web Services**: Mercure, LogConsumer
4. **Custom Applications**: Your specific services

### Example Deployment Sequence
```bash
# Infrastructure
cluster deploy storage-provisioner
cluster deploy ingress-nginx

# Core services
cluster deploy postgres
cluster deploy rabbitmq
cluster deploy scrutiny

# Application services
cluster deploy ollama
cluster deploy rocket.chat  # Deploys MongoDB automatically
cluster deploy jupyterhub
```

## Troubleshooting

### Common Issues

#### Issue 1: Vault Password Prompt Not Appearing
**Symptoms**: Deployment fails with vault decryption error

**Solution**:
```bash
# Ensure you're in the correct Python environment
source venv/bin/activate

# Verify Ansible vault is accessible
ansible-vault --version

# Check Ansible version
ansible --version  # Should be 12.3.0+ with core 2.19.5+

# Try deployment again
cluster deploy <service>
```

#### Issue 2: Pod Stuck in Pending State
**Symptoms**: `kubectl get pods` shows pod in Pending status

**Diagnosis**:
```bash
kubectl describe pod <pod-name>
```

**Common Causes**:
- Insufficient resources on nodes
- Missing persistent volume claims
- Node affinity constraints not met (e.g., AMD64-only service on ARM64 node)

**Solution**:
```bash
# Check node resources
kubectl top nodes

# Check PVC status
kubectl get pvc

# Verify node labels match affinity requirements
kubectl get nodes --show-labels

# Adjust resource requests or node affinity in values.yml if needed
```

#### Issue 3: Image Pull Errors
**Symptoms**: Pod fails with ImagePullBackOff or ErrImagePull

**Diagnosis**:
```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

**Solution**:
```bash
# Verify image exists for target architecture
docker manifest inspect <image-name>

# Check image pull secrets
kubectl get secrets

# For ARM64 workers, ensure multi-arch or ARM64-specific images
# Update Helm chart values with correct image reference
```

#### Issue 4: Helm Installation Fails
**Symptoms**: Helm command fails during deployment

**Diagnosis**:
```bash
# SSH to controller
ssh pi@controller-node

# Check Helm version
helm version

# Verify kubeconfig access
sudo kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get nodes
```

**Solution**:
```bash
# Ensure Helm is installed
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify permissions
sudo chown pi:pi /etc/rancher/k3s/k3s.yaml
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

# Retry deployment
cluster deploy <service>
```

#### Issue 5: Service Not Accessible
**Symptoms**: Cannot connect to deployed service

**Diagnosis**:
```bash
# Check service endpoints
kubectl get svc <service-name>
kubectl get endpoints <service-name>

# Check pod status
kubectl get pods -l app=<service-name>

# Test from within cluster
kubectl run -it --rm debug --image=busybox --restart=Never -- wget -O- http://<service-name>:port
```

**Solution**:
- Verify service selector matches pod labels
- Check network policies
- Ensure ingress rules are configured
- For Rocket.Chat, verify MongoDB is running

#### Issue 6: MongoDB Connection Issues (Rocket.Chat)
**Symptoms**: Rocket.Chat pod fails to connect to MongoDB

**Diagnosis**:
```bash
# Check MongoDB pod status
kubectl get pods -l app=mongodb

# Check MongoDB logs
kubectl logs <mongodb-pod-name>

# Verify MongoDB service
kubectl get svc mongodb
```

**Solution**:
```bash
# Verify MongoDB credentials in values.yml
cat build/playbooks/rocket.chat/values.yml

# Ensure MongoDB is fully started before Rocket.Chat
kubectl wait --for=condition=ready pod -l app=mongodb --timeout=300s

# Restart Rocket.Chat deployment
kubectl rollout restart deployment rocket-chat
```

#### Issue 7: Deployment Hangs
**Symptoms**: `cluster deploy` command doesn't complete

**Diagnosis**:
```bash
# Check Ansible process
ps aux | grep ansible

# Review playbook execution
# Look for tasks waiting on user input or external resources
```

**Solution**:
```bash
# Cancel deployment (Ctrl+C)
# Check for stuck resources
kubectl get all -n <namespace>

# Check Helm releases
helm list --kubeconfig /etc/rancher/k3s/k3s.yaml

# Clean up if necessary
helm uninstall <service-name> --kubeconfig /etc/rancher/k3s/k3s.yaml

# Retry deployment
cluster deploy <service>
```

### Debug Mode

For detailed deployment information:

```bash
# Enable verbose Ansible output
export ANSIBLE_VERBOSITY=3
cluster deploy <service>

# Check Kubernetes events
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Review pod logs
kubectl logs <pod-name> --all-containers=true

# Check Helm release details
helm get all <service-name> --kubeconfig /etc/rancher/k3s/k3s.yaml
```

### Getting Help

1. **Check Documentation**
   - Review service-specific docs in `build/playbooks/<service>/`
   - Consult Helm chart documentation in `build/charts/<service>/`
   - Review Kubernetes documentation for resource issues

2. **Review Logs**
   ```bash
   # Deployment logs
   kubectl logs <pod-name>
   
   # Previous container logs (if crashed)
   kubectl logs <pod-name> --previous
   
   # All containers in pod
   kubectl logs <pod-name> --all-containers=true
   
   # Helm deployment logs
   helm get notes <service-name> --kubeconfig /etc/rancher/k3s/k3s.yaml
   ```

3. **Inspect Resources**
   ```bash
   # Detailed pod information
   kubectl describe pod <pod-name>
   
   # Deployment status
   kubectl describe deployment <service-name>
   
   # Service configuration
   kubectl describe svc <service-name>
   
   # Helm release manifest
   helm get manifest <service-name> --kubeconfig /etc/rancher/k3s/k3s.yaml
   ```

## Integration with AI Development Tools

The deployment system integrates with AI-assisted development workflows:

### Using Aider for Deployment Planning
```bash
# Plan new service deployment
aider --architect build/playbooks/

# Ask: "I want to deploy a new Redis service. What's the best approach 
#      following the existing patterns from Ollama and Rocket.Chat?"
```

### Using Avante for Playbook Editing
- Open playbook in Neovim
- Use `<leader>aa`: "Add health checks and resource limits to this deployment"
- Review and apply AI suggestions

### Creating New Service Deployments
```bash
# Use Aider to generate new service structure
aider build/playbooks/ollama/build.yml build/playbooks/rocket.chat/values.yml

# Ask: "Create a new service deployment for Redis following these patterns,
#      including Helm chart integration and multi-arch support"
```

See [ANSIBLE_AI_INTEGRATION_GUIDE.md](ANSIBLE_AI_INTEGRATION_GUIDE.md) for detailed AI workflow integration.

## Related Documentation

- **[Getting Started Guide](GETTING_STARTED.md)**: Initial setup and prerequisites
- **[Ansible AI Integration](ANSIBLE_AI_INTEGRATION_GUIDE.md)**: AI-powered infrastructure automation
- **[Aider Terminal Guide](AIDER_TERMINAL_GUIDE.md)**: Using Aider for infrastructure planning
- **[Memory Store Implementation](MEMORY_STORE_IMPLEMENTATION_GUIDE.md)**: Deploying the documentation search system

## Best Practices

1. **Always test in staging first** - If available, deploy to a test environment
2. **Review playbooks before deployment** - Understand what will be changed
3. **Monitor during deployment** - Watch for errors and resource issues
4. **Verify after deployment** - Don't assume success, test functionality
5. **Document custom changes** - Keep notes on configuration modifications
6. **Use version control** - Commit playbook changes before deploying
7. **Backup before updates** - Especially for stateful services
8. **Follow dependency order** - Deploy services in the correct sequence
9. **Check resource availability** - Ensure cluster has capacity
10. **Keep vault passwords secure** - Never commit unencrypted secrets
11. **Use Helm for complex services** - Leverage Helm's templating and versioning
12. **Respect architecture constraints** - Deploy AMD64-only services to controller
13. **Monitor Helm releases** - Track deployment history for easy rollbacks
14. **Test MongoDB separately** - For services with database dependencies

## Quick Reference

### Essential Commands
```bash
# Deploy service
cluster deploy <service-name>

# Check deployment status
kubectl get pods -l app=<service-name>
kubectl rollout status deployment/<service-name>

# View logs
kubectl logs <pod-name>

# Rollback deployment
kubectl rollout undo deployment/<service-name>

# Helm-specific commands (on controller node)
sudo helm list --kubeconfig /etc/rancher/k3s/k3s.yaml
sudo helm status <service> --kubeconfig /etc/rancher/k3s/k3s.yaml
sudo helm rollback <service> --kubeconfig /etc/rancher/k3s/k3s.yaml

# Check cluster health
kubectl get nodes
kubectl top nodes

# View service endpoints
kubectl get svc <service-name>
```

### File Locations
- **Playbooks**: `build/playbooks/<service>/build.yml`
- **Helm Values**: `build/playbooks/<service>/values.yml`
- **Encrypted Configs**: `build/playbooks/<service>/cfg.enc`
- **Helm Charts**: `build/charts/<service>/`
- **CLI Source**: `src/cmd/deploy.go`
- **K3s Kubeconfig**: `/etc/rancher/k3s/k3s.yaml` (on controller)

### Vault-Protected Services
- collector
- logconsumer
- mercure
- scrutiny

### Architecture-Specific Services
- **AMD64 Only**: Rocket.Chat (with MongoDB)
- **Multi-Arch**: Ollama, most other services

---

**Next Steps**: After deploying services, consider setting up the [Memory Store](MEMORY_STORE_IMPLEMENTATION_GUIDE.md) for intelligent documentation search across your cluster.

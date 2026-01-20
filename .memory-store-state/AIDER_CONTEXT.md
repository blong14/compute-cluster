# Aider Context for Memory Store Implementation

## Project Structure
This is a compute cluster management project with:
- Go CLI tool using Cobra framework
- Kubernetes deployments via Helm charts
- Ansible playbooks for deployment automation
- PostgreSQL database already deployed

## Established Patterns

### Helm Charts (`build/charts/`)
- Standard Kubernetes resources (Deployment, Service, Ingress)
- ARM64 node affinity for compute nodes
- PVC support for persistent storage
- Configurable resource limits
- Ingress with cluster domain pattern

### Ansible Playbooks (`build/playbooks/`)
- Copy source code to build nodes
- Apply Kubernetes manifests
- Use sudo for privileged operations
- Target `amd-build` hosts

### Go CLI (`src/`)
- Cobra command structure
- Viper for configuration
- klog for logging
- Module name: `cluster`

## Memory Store Requirements
- PostgreSQL with pgvector for vector storage
- Voyage AI for embeddings (not Ollama)
- Document processing pipeline
- Semantic search capabilities
- Integration with existing CLI
- ARM64 compatibility

## Implementation Approach
1. Extend PostgreSQL with pgvector
2. Create memory-store Helm chart
3. Add CLI commands for search
4. Create document processor service
5. Deploy via Ansible following existing patterns


# Compute Cluster Playbooks

This directory contains Ansible playbooks for deploying and managing services in the compute cluster.

## Standardized Patterns

All services deployed through these playbooks follow standardized patterns for:

### 1. Resource Limits

All services have consistent resource requests and limits:
- CPU requests: 100m
- Memory requests: 128Mi
- CPU limits: 500m
- Memory limits: 512Mi

These can be adjusted per service by modifying the variables in the playbook.

### 2. Node Affinity

Services are deployed with node affinity rules to ensure they run on the appropriate architecture:
- Node selector for architecture (arm64 or amd64)
- Preferred scheduling on worker nodes

### 3. Monitoring Integration

All services are configured with Prometheus monitoring annotations:
- prometheus.io/scrape: "true"
- prometheus.io/port: (service-specific metrics port)
- prometheus.io/path: (service-specific metrics path, defaults to "/metrics")

## Usage

To deploy a service with these standardized patterns:

```bash
ansible-playbook build/playbooks/<service>/build.yml
```

## Common Templates

Common templates are stored in `build/playbooks/common/templates.yml` and are included in all service playbooks.

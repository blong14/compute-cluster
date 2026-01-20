# Compute Cluster CLI 🚀

Welcome to the command-line interface for managing our 5-node hybrid compute cluster! This tool is your one-stop-shop for deploying, managing, and interacting with the 22+ services running on our AMD64 controller and ARM64 Raspberry Pi workers.

## Quick Start

```bash
CLI for the compute cluster...

Usage:
  cluster [command]

Available Commands:
  completion  Generate the autocompletion script for the specified shell
  deploy      Deploy a service to the cluster
  help        Help about any command
  run         Run a job in the cluster
  search      Search documentation using semantic search (coming soon)

Flags:
  -h, --help   help for cluster

Use "cluster [command] --help" for more information about a command.
```

## Installation

```bash
source venv/bin/activate
pip install -r requirements.txt -c constraints.txt
```

## Memory Store Implementation

This repository includes an AI-powered memory store system for semantic documentation search. The implementation uses:

- **PostgreSQL with pgvector** for vector storage
- **Voyage AI** for embeddings generation  
- **Aider + Avante** for AI-assisted development
- **Docker Compose** for local development
- **Kubernetes** for production deployment

### Getting Started with Memory Store

```bash
# Initialize the implementation
python detect-next-task.py

# Start implementation with Aider
aider --config .aider.memory-store.yml --message "continue with the plan"

# Check progress
cat .memory-store-state/CURRENT_TASK.md

# Update progress after completing steps
python update-progress.py "step-name" "completed" "100" "Step completed successfully"
```

### Development Workflow

The memory store implementation uses an AI-assisted workflow:

1. **State Tracking**: Progress tracked in `.memory-store-state/` directory
2. **Task Detection**: `detect-next-task.py` identifies next implementation step
3. **Aider Integration**: `aider --message "continue with the plan"` reads context and implements
4. **Progress Updates**: `update-progress.py` tracks completion and updates state

See `MEMORY_STORE_IMPLEMENTATION_GUIDE.md` for detailed implementation instructions.

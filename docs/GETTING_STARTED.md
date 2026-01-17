# Compute Cluster CLI 🚀

Welcome to the command-line interface for managing our 5-node hybrid compute cluster! This tool is your one-stop-shop for deploying, managing, and interacting with the 22+ services running on our AMD64 controller and ARM64 Raspberry Pi workers.

Our development workflow is supercharged with AI, using tools like **Aider** and **Avante** to accelerate everything from feature architecture to infrastructure automation.

## Quick Start

### Prerequisites
- Python 3.x & `pip`
- Ansible

### Installation
1.  Clone this repository.
2.  Set up the Python virtual environment and install dependencies:
    ```bash
    source venv/bin/activate
    pip install -r requirements.txt -c constraints.txt
    ```

## Usage

Here are the primary commands available. For detailed options, use `cluster [command] --help`.

```bash
CLI for the compute cluster...

Usage:
  cluster [command]

Available Commands:
  completion  Generate the autocompletion script for the specified shell
  deploy      Deploy a service to the cluster
  help        Help about any command
  run         Run a job in the cluster

Flags:
  -h, --help   help for cluster

Use "cluster [command] --help" for more information about a command.
```

### Examples

Deploy a new service to the cluster:
```bash
cluster deploy ollama
```

Run a one-off diagnostic job:
```bash
cluster run diagnostics --check-network
```

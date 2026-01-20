# Cluster Management CLI

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

## Services

### Document Processor Service

A Go service that processes documents, generates embeddings using Voyage AI, and stores them in PostgreSQL.

#### Features

- Document processing and storage
- Voyage AI embedding generation
- PostgreSQL storage with JSON support
- RESTful API for document processing and search
- Docker support

#### Environment Variables

- `DATABASE_URL`: PostgreSQL connection string (default: `postgres://user:password@localhost/memorystore?sslmode=disable`)
- `VOYAGE_API_KEY`: Your Voyage AI API key (required)
- `VOYAGE_MODEL`: Voyage AI model to use (default: `voyage-large-2`)
- `PORT`: Server port (default: `8080`)

#### API Endpoints

**Process Document**
```bash
POST /process
Content-Type: application/json

{
  "id": "doc1",
  "content": "This is the document content to be processed",
  "title": "Document Title",
  "metadata": "{\"author\": \"John Doe\"}"
}
```

**Search Documents**
```bash
GET /search?q=search%20query&limit=10
```

**Health Check**
```bash
GET /health
```

#### Running the Processor

```bash
# Set environment variables
export VOYAGE_API_KEY=your_api_key_here
export DATABASE_URL=postgres://user:password@localhost/memorystore?sslmode=disable

# Build and run
go build -o bin/processor src/cmd/processor/main.go
./bin/processor
```

## Dependency Management

### Setup

1. **Create virtual environment with dependencies:**
   ```bash
   cluster run install
   ```

2. **Install Go dependencies:**
   ```bash
   go mod tidy
   ```


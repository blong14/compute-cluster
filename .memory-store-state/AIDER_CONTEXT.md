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

## Memory Store Implementation Status

### ✅ COMPLETED COMPONENTS (Phase 1 & 2)

#### 1. Database Foundation (`memory-store/init.sql`)
- PostgreSQL with pgvector extension
- Optimized schema with `documents` and `document_chunks` tables
- Vector similarity search functions
- Performance indexes for hybrid search
- Full-text search capabilities

#### 2. Document Processing Service (`memory-store/services/processor/`)
- **Files**: `document_processor.py`, `Dockerfile`, `requirements.txt`
- Intelligent markdown chunking with code block preservation
- HTTP health monitoring server (port 8080)
- Batch processing capabilities
- Error handling and comprehensive logging
- Containerized with Python 3.11

#### 3. Search API Service (`memory-store/services/api/`)
- **Files**: `search_api.py`, `Dockerfile`, `requirements.txt`
- FastAPI with semantic, full-text, and hybrid search endpoints
- PostgreSQL pgvector integration
- Health checks and statistics endpoint
- Comprehensive error handling
- Containerized with Python 3.11

#### 4. Self-hosted Embedding Service (`memory-store/services/embedding-service/`)
- **Files**: `embedding_server.py`, `Dockerfile`, `requirements.txt`, `test_embedding_server.py`
- Sentence-transformers with multiple model options
- FastAPI REST API for local embeddings
- No external API dependencies
- Health checks and model management
- Containerized with Python 3.11

#### 5. Docker Integration (`memory-store/docker-compose.yml`)
- Complete service orchestration
- Custom networking with proper dependencies
- Enhanced health checks
- Volume management for persistent data
- Logging configuration
- Service dependency chain: postgres → processor → API

#### 6. CLI Integration (`src/cmd/search.go`)
- **Commands implemented**:
  - `cluster search [query]` - Semantic and hybrid search
  - `cluster memory-store status` - Service statistics
  - `cluster memory-store health` - Health checks
- HTTP client integration with search API
- Result formatting and display
- Configurable search parameters (limit, hybrid mode)

#### 7. Local Testing (`memory-store/test-local.sh`)
- Comprehensive deployment validation script
- Health checks for all services
- Database schema verification
- API endpoint testing
- Service status monitoring
- Error logging and debugging

### 🔄 REMAINING TASKS (Phase 3)

#### 1. Kubernetes Deployment (HIGH PRIORITY)
**Missing**: Helm chart in `build/charts/memory-store/`
- **Need**: Standard K8s resources (Deployment, Service, Ingress)
- **Need**: ConfigMaps for service configuration
- **Need**: Secrets for API keys and database credentials
- **Need**: PVC for PostgreSQL data persistence
- **Need**: ARM64 node affinity following project patterns
- **Need**: Resource limits and requests
- **Need**: Health checks and readiness probes

#### 2. Ansible Deployment Automation (HIGH PRIORITY)
**Missing**: Playbook in `build/playbooks/memory-store/`
- **Need**: `build.yml` following existing patterns
- **Need**: Copy source code to build nodes
- **Need**: Apply Kubernetes manifests
- **Need**: Target `amd-build` hosts
- **Need**: Environment variable management

#### 3. CLI Document Processing Commands (MEDIUM PRIORITY)
**Missing**: Document ingestion commands in Go CLI
- **Need**: `cluster memory-store process [path]` command
- **Need**: Batch processing support
- **Need**: Progress monitoring
- **Need**: Integration with processor service HTTP API

#### 4. Production Configuration (MEDIUM PRIORITY)
**Missing**: Production-ready configurations
- **Need**: Environment-specific configs (.env.production)
- **Need**: Logging configuration for Kubernetes
- **Need**: Monitoring and metrics integration
- **Need**: Backup and recovery procedures

#### 5. Documentation (LOW PRIORITY)
**Missing**: User and deployment documentation
- **Need**: README.md for memory-store
- **Need**: API documentation
- **Need**: Deployment guide
- **Need**: Troubleshooting guide

## Key Integration Points

### Service Architecture
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Go CLI Tool   │───▶│   Search API     │───▶│   PostgreSQL    │
│  (port: N/A)    │    │  (port: 8000)    │    │  (port: 5432)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │ Document Processor│───▶│ Embedding Service│
                       │  (port: 8080)    │    │  (port: 8001)   │
                       └──────────────────┘    └─────────────────┘
```

### API Endpoints
- **Search API**: `http://localhost:8000`
  - `/health` - Health check
  - `/stats` - Service statistics
  - `/search/semantic` - Semantic search
  - `/search/hybrid` - Hybrid search
  - `/docs` - API documentation

- **Document Processor**: `http://localhost:8080`
  - `/health` - Health check
  - Processing via direct Python execution

- **Embedding Service**: `http://localhost:8001`
  - `/health` - Health check
  - `/embed` - Generate embeddings

## Next Steps for Completion
1. **Create Helm chart** following existing patterns in `build/charts/`
2. **Create Ansible playbook** following existing patterns in `build/playbooks/`
3. **Add document processing CLI commands** to integrate with processor service
4. **Test full deployment** on Kubernetes cluster
5. **Add production configurations** and monitoring

## Development Workflow
- Local development: Use `memory-store/test-local.sh`
- Service logs: `docker-compose logs [service-name]`
- Database access: `docker exec memory-store-postgres psql -U memory_user -d memory_store`
- API testing: Visit `http://localhost:8000/docs` for interactive API docs

## Task State Tracking
Based on `.memory-store-state/task-state.json`, the following tasks are **COMPLETED**:
- ✅ `phase1_foundation.directory_structure` - Basic directory structure created
- ✅ `phase1_foundation.database_schema` - PostgreSQL schema with pgvector extension
- ✅ `phase1_foundation.environment_config` - Environment configuration templates
- ✅ `phase2_services.document_processor` - Document processing service with chunking
- ✅ `phase2_services.search_api` - FastAPI search service with multiple endpoints
- ✅ `phase2_services.docker_integration` - Complete Docker Compose orchestration
- ✅ `phase2_services.embedding_service` - Self-hosted embedding service

**Current Phase**: `phase2_services` (COMPLETED)
**Next Phase**: `phase3_deployment` (Kubernetes & Ansible integration)

## Critical Implementation Notes

### Service Dependencies
The services have a specific startup order that must be maintained:
1. PostgreSQL (with pgvector extension)
2. Embedding Service (optional, for self-hosted embeddings)
3. Document Processor (depends on database and embeddings)
4. Search API (depends on database and embeddings)

### Configuration Management
- Environment variables are managed through `.env` files
- Docker Compose uses custom networking (`memory-store-network`)
- All services use health checks for proper orchestration
- Persistent volumes are configured for PostgreSQL data

### Testing Status
- Local deployment testing is implemented and working
- Health checks are comprehensive across all services
- API endpoints are validated through automated tests
- Database schema and pgvector extension are verified

### Known Limitations
1. **No Kubernetes deployment** - Helm chart and manifests missing
2. **No Ansible automation** - Deployment playbook missing
3. **Limited CLI integration** - Only search commands, no document processing
4. **No production configs** - Only development environment setup
5. **Missing documentation** - No user guides or API docs

## Immediate Next Steps for Aider
1. **Create Helm Chart** (`build/charts/memory-store/`)
   - Follow existing chart patterns (see `build/charts/ollama/` as reference)
   - Include all 4 services: postgres, processor, api, embedding-service
   - Add proper ConfigMaps, Secrets, and PVCs
   - Configure ingress and service discovery

2. **Create Ansible Playbook** (`build/playbooks/memory-store/`)
   - Follow existing playbook patterns (see `build/playbooks/ollama/build.yml`)
   - Target `amd-build` hosts
   - Copy source code and apply manifests
   - Handle environment variables and secrets

3. **Extend CLI Commands** (`src/cmd/`)
   - Add `cluster memory-store process [path]` command
   - Integrate with document processor HTTP API
   - Add progress monitoring and batch processing

## File Structure Summary
```
memory-store/
├── init.sql                           # PostgreSQL schema with pgvector
├── docker-compose.yml                 # Complete service orchestration
├── test-local.sh                      # Local deployment validation
├── services/
│   ├── api/
│   │   ├── search_api.py              # FastAPI search service
│   │   ├── Dockerfile                 # API container
│   │   └── requirements.txt           # API dependencies
│   ├── processor/
│   │   ├── document_processor.py      # Document processing service
│   │   ├── Dockerfile                 # Processor container
│   │   └── requirements.txt           # Processor dependencies
│   └── embedding-service/
│       ├── embedding_server.py        # Self-hosted embeddings
│       ├── test_embedding_server.py   # Embedding tests
│       ├── Dockerfile                 # Embedding container
│       └── requirements.txt           # Embedding dependencies
```

## Missing Components for Full Deployment
```
build/
├── charts/memory-store/               # ❌ MISSING - Helm chart needed
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── configmap.yaml
│       ├── secret.yaml
│       └── ingress.yaml
└── playbooks/memory-store/            # ❌ MISSING - Ansible playbook needed
    ├── build.yml
    └── values.yml

src/cmd/
└── process.go                         # ❌ MISSING - Document processing CLI
```

## Environment Configuration Status
- ✅ Docker Compose environment configured
- ✅ Service networking and dependencies set up
- ✅ Health checks implemented across all services
- ❌ Kubernetes ConfigMaps and Secrets not created
- ❌ Production environment variables not configured
- ❌ Ingress and service discovery not set up

## Testing and Validation Status
- ✅ Local Docker deployment fully tested
- ✅ All service health endpoints working
- ✅ Database schema and pgvector verified
- ✅ API endpoints tested and documented
- ❌ Kubernetes deployment not tested
- ❌ Production readiness not validated
- ❌ Document processing workflow not tested end-to-end

This context should provide Aider with everything needed to complete the memory store implementation efficiently.

## Additional Context for Aider

### Current Implementation Strengths
1. **Complete Local Development Stack**: All services are containerized and orchestrated with Docker Compose
2. **Production-Ready Services**: FastAPI with proper error handling, health checks, and logging
3. **Flexible Embedding Options**: Both external (Voyage AI) and self-hosted (sentence-transformers) embedding support
4. **Robust Database Design**: Optimized PostgreSQL schema with pgvector for high-performance vector search
5. **CLI Integration**: Basic search functionality already integrated into the Go CLI tool
6. **Comprehensive Testing**: Local deployment validation with health checks and API testing

### Key Technical Decisions Made
1. **Python Services**: All backend services use Python 3.11 for consistency and ML library compatibility
2. **FastAPI Framework**: Chosen for automatic API documentation and async support
3. **pgvector Extension**: PostgreSQL extension for native vector operations and similarity search
4. **Docker Networking**: Custom network (`memory-store-network`) for service isolation
5. **Health Check Strategy**: HTTP endpoints for all services with proper dependency management
6. **Embedding Strategy**: Dual support for external APIs and self-hosted models for flexibility

### Service Communication Patterns
- **CLI → Search API**: HTTP REST calls for search operations
- **Search API → PostgreSQL**: Direct database connections with connection pooling
- **Document Processor → Embedding Service**: HTTP calls for embedding generation
- **Document Processor → PostgreSQL**: Direct database connections for document storage
- **All Services**: Health check endpoints for orchestration and monitoring

### Configuration Management Strategy
- **Development**: `.env` files with Docker Compose
- **Production**: Will use Kubernetes ConfigMaps and Secrets (to be implemented)
- **Service Discovery**: Currently localhost-based, needs Kubernetes service discovery
- **Environment Variables**: Comprehensive set defined for all services

### Performance Considerations
- **Database Indexes**: Optimized for both vector similarity and full-text search
- **Connection Pooling**: Implemented in Python services
- **Async Operations**: FastAPI with async/await for non-blocking operations
- **Batch Processing**: Document processor supports batch operations
- **Resource Limits**: To be defined in Kubernetes deployment

### Security Considerations
- **API Keys**: Managed through environment variables
- **Database Credentials**: Separate user with limited permissions
- **Network Isolation**: Services communicate through custom Docker network
- **Input Validation**: Implemented in FastAPI endpoints
- **Health Endpoints**: No sensitive information exposed

### Monitoring and Observability
- **Health Checks**: All services have `/health` endpoints
- **Statistics**: Search API provides `/stats` endpoint for metrics
- **Logging**: Structured logging implemented across all services
- **Error Handling**: Comprehensive error handling with proper HTTP status codes

### Deployment Architecture
```
Development (Current):
Docker Compose → Local Services → Local PostgreSQL

Production (Target):
Ansible → Kubernetes → Helm Charts → Pod Services → PostgreSQL PVC
```

### Next Phase Priorities
1. **Kubernetes Deployment** (Critical Path)
   - Helm chart creation is the highest priority
   - Blocks production deployment and testing
   - Required for integration with existing cluster infrastructure

2. **Ansible Integration** (Critical Path)
   - Enables automated deployment following project patterns
   - Required for CI/CD integration
   - Blocks production rollout

3. **CLI Enhancement** (Feature Complete)
   - Document processing commands needed for full workflow
   - Currently only search is implemented
   - Blocks end-to-end user experience

### Reference Implementations
- **Helm Chart Reference**: `build/charts/ollama/` - Similar service with multiple components
- **Ansible Reference**: `build/playbooks/ollama/build.yml` - Similar deployment pattern
- **CLI Reference**: `src/cmd/search.go` - Existing memory store commands

This comprehensive context should enable Aider to efficiently complete the remaining implementation tasks.


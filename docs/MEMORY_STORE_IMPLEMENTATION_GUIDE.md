# Memory Store Documentation

## Overview

The Memory Store is a semantic search system that enables intelligent search across your compute cluster documentation. It indexes all markdown files and provides semantic search capabilities using vector embeddings, full-text search, and hybrid search that combines both approaches.

## What is the Memory Store?

The Memory Store transforms your static documentation into an intelligent, searchable knowledge base. Instead of manually browsing through files or using basic text search, you can ask natural language questions and find relevant information across all your documentation.

### Key Capabilities

- **Semantic Search** - Find conceptually related content, not just keyword matches
- **Intelligent Understanding** - Understands context and meaning, not just exact words
- **Cross-Document Search** - Search across all documentation simultaneously
- **Instant Results** - Sub-second response times for most queries
- **CLI Integration** - Search directly from your existing cluster CLI tool

## Architecture

The Memory Store consists of four integrated services:

1. **PostgreSQL with pgvector** - Stores document embeddings and enables vector similarity search
2. **Document Processor** - Intelligently processes and chunks markdown files
3. **Search API** - Provides REST endpoints for search operations
4. **Embedding Service** - Generates vector embeddings using sentence-transformers
5. **CLI Integration** - Seamlessly integrated into your cluster CLI

### How It Works

```
Documentation Files → Document Processor → Vector Embeddings → PostgreSQL
                                                                     ↓
CLI Search Query → Search API → Vector Search + Full-Text → Results
```

## Search Types

### Semantic Search

Finds content based on meaning and context, not just keywords:

```bash
cluster search "troubleshooting deployment issues"
# Finds: error resolution guides, debugging steps, common problems
```

### Full-Text Search

Traditional keyword-based search for exact matches:

```bash
cluster search "docker-compose up"
# Finds: exact command references and usage examples
```

### Hybrid Search

Combines semantic understanding with keyword matching for best results:

```bash
cluster search "ansible automation best practices"
# Uses both semantic similarity and keyword relevance
```

## Using the Memory Store

### CLI Commands

The Memory Store is integrated into your existing cluster CLI tool:

```bash
# Basic semantic search
cluster search "your question or topic"

# Search with custom result limit
cluster search "ansible playbooks" --limit 10

# Check system status
cluster memory-store status
cluster memory-store health
```

### Search Examples

Based on your actual documentation, here are practical search examples:

#### Finding Development Workflows
```bash
cluster search "aider development workflow"
# Returns: AIDER_TERMINAL_GUIDE.md, WORKFLOW_EXAMPLES.md sections
```

#### Security and Installation Guidance
```bash
cluster search "secure installation alternatives"
# Returns: AVANTE_SECURITY_ALTERNATIVES.md content
```

#### Infrastructure Automation
```bash
cluster search "ansible AI integration"
# Returns: ANSIBLE_AI_INTEGRATION_GUIDE.md sections
```

#### Database Operations
```bash
cluster search "mongodb upgrade compatibility"
# Returns: MONGO8_UPGRADE.md upgrade procedures
```

#### Practical Development Examples
```bash
cluster search "REST API authentication workflow"
# Returns: WORKFLOW_EXAMPLES.md authentication scenarios
```

### Search Tips

1. **Use Natural Language** - Ask questions as you would to a colleague
2. **Be Specific** - More specific queries return more targeted results
3. **Try Different Phrasings** - The semantic search understands various ways to express concepts
4. **Combine Topics** - Search for multiple related concepts together

## What Gets Indexed

The Memory Store automatically processes and indexes:

- **All Markdown Files** - Complete documentation in `.md` format
- **Code Examples** - Preserves code blocks and syntax
- **Configuration Files** - YAML, JSON, and other config examples
- **Command References** - CLI commands and usage examples
- **Troubleshooting Guides** - Error messages and solutions

### Intelligent Processing

The system understands document structure:

- **Headers and Sections** - Maintains document hierarchy
- **Code Blocks** - Preserves formatting and syntax highlighting
- **Tables and Lists** - Keeps structured data intact
- **Cross-References** - Understands relationships between documents

## Search Results

### What You Get

Each search returns relevant document chunks with:

- **Content Preview** - The relevant text section
- **Source Location** - Exact file and section
- **Relevance Score** - How well it matches your query
- **Context** - Surrounding content for better understanding

### Result Quality

The Memory Store provides high-quality results by:

- **Understanding Context** - Knows the difference between "deployment" in different contexts
- **Ranking Relevance** - Most relevant results appear first
- **Avoiding Duplicates** - Consolidates similar content
- **Maintaining Accuracy** - Results directly from your documentation

## System Status

### Health Monitoring

Check system health with:

```bash
cluster memory-store health
# Shows: Database connectivity, API responsiveness, processing status

cluster memory-store status  
# Shows: Document count, recent activity, performance metrics
```

### What's Monitored

- **Document Processing** - How many files are indexed
- **Search Performance** - Response times and query success rates
- **Service Health** - All components running properly
- **Data Freshness** - When documents were last updated

## Benefits

### For Daily Work

- **Faster Information Discovery** - Find answers in seconds, not minutes
- **Better Context** - Understand how concepts relate across documents
- **Reduced Cognitive Load** - No need to remember exact file locations
- **Improved Productivity** - Spend time solving problems, not searching for solutions

### For Team Knowledge

- **Institutional Memory** - Capture and search tribal knowledge
- **Onboarding** - New team members can quickly find relevant information
- **Documentation ROI** - Make existing documentation more valuable
- **Knowledge Sharing** - Discover related information you didn't know existed

## Real-World Use Cases

### Development Workflows
```bash
cluster search "setting up development environment"
# Finds setup guides, tool configurations, troubleshooting steps
```

### Infrastructure Operations
```bash
cluster search "service deployment failed"
# Finds debugging guides, common issues, resolution steps
```

### Security and Compliance
```bash
cluster search "security best practices authentication"
# Finds security guides, configuration examples, compliance requirements
```

### Learning and Reference
```bash
cluster search "how to use aider with ansible"
# Finds workflow examples, integration guides, practical tips
```

The Memory Store transforms your documentation from a static collection of files into an intelligent, searchable knowledge base that understands context and provides relevant answers to your questions.




#### 2. Implementation State Schema

```json
{
  "implementation_id": "memory-store-impl-2024-001",
  "started_at": "2024-01-15T10:30:00Z",
  "last_updated": "2024-01-15T14:22:00Z",
  "current_phase": "local-development",
  "overall_progress": 0.35,
  "phases": {
    "planning": {
      "status": "completed",
      "progress": 1.0,
      "completed_at": "2024-01-15T11:00:00Z",
      "artifacts": ["architecture-decisions.md", "service-structure.json"],
      "validation": "passed"
    },
    "local-development": {
      "status": "in-progress",
      "progress": 0.6,
      "started_at": "2024-01-15T11:15:00Z",
      "current_step": "database-schema",
      "steps": {
        "docker-compose": {
          "status": "completed",
          "artifacts": ["docker-compose.yml"],
          "validation": "passed"
        },
        "database-schema": {
          "status": "in-progress",
          "progress": 0.8,
          "artifacts": ["init.sql"],
          "validation": "pending"
        },
        "document-processor": {
          "status": "pending",
          "dependencies": ["database-schema"]
        }
      }
    },
    "service-implementation": {
      "status": "pending",
      "dependencies": ["local-development"]
    },
    "kubernetes-deployment": {
      "status": "pending",
      "dependencies": ["service-implementation"]
    },
    "integration-testing": {
      "status": "pending",
      "dependencies": ["kubernetes-deployment"]
    }
  },
  "environment": {
    "working_directory": "/workspace/memory-store",
    "tools_available": ["aider", "avante", "kubectl", "docker-compose"],
    "api_keys_configured": ["VOYAGE_API_KEY"],
    "cluster_access": true
  },
  "blockers": [],
  "next_actions": [
    {
      "action": "complete_database_schema",
      "tool": "avante",
      "file": "init.sql",
      "description": "Add remaining indexes and triggers"
    }
  ]
}
```

#### 3. Checkpoint System

Each major step creates a checkpoint with validation:

```json
{
  "checkpoint_id": "step-3-processor-v1",
  "timestamp": "2024-01-15T13:45:00Z",
  "step": "document-processor-implementation",
  "status": "completed",
  "validation": {
    "syntax_check": "passed",
    "unit_tests": "passed",
    "integration_test": "passed",
    "code_review": "passed"
  },
  "artifacts": {
    "files_created": [
      "services/memory-store/processor/document_processor.py",
      "services/memory-store/processor/Dockerfile",
      "services/memory-store/processor/requirements.txt"
    ],
    "files_modified": [
      "docker-compose.yml"
    ],
    "configurations": [
      "processor-config.json"
    ]
  },
  "rollback_info": {
    "git_commit": "abc123def456",
    "backup_files": ["processor-backup-v1.tar.gz"]
  },
  "next_checkpoint": "step-4-search-api"
}
```

### Durability Implementation

#### 1. State Persistence Functions

```python
# state_manager.py - Core durability functions
import json
import os
from datetime import datetime
from typing import Dict, List, Optional
from pathlib import Path

class ImplementationStateManager:
    def __init__(self, workspace_dir: str = "/workspace"):
        self.workspace_dir = Path(workspace_dir)
        self.state_dir = self.workspace_dir / ".memory-store-state"
        self.state_file = self.state_dir / "implementation-state.json"
        self.checkpoints_dir = self.state_dir / "checkpoints"
        self.artifacts_dir = self.state_dir / "artifacts"
        self.logs_dir = self.state_dir / "logs"
        
        # Ensure directories exist
        for dir_path in [self.state_dir, self.checkpoints_dir, 
                        self.artifacts_dir, self.logs_dir]:
            dir_path.mkdir(parents=True, exist_ok=True)
    
    def load_state(self) -> Dict:
        """Load current implementation state"""
        if self.state_file.exists():
            with open(self.state_file, 'r') as f:
                return json.load(f)
        return self._create_initial_state()
    
    def save_state(self, state: Dict) -> None:
        """Save implementation state with timestamp"""
        state['last_updated'] = datetime.utcnow().isoformat() + 'Z'
        with open(self.state_file, 'w') as f:
            json.dump(state, f, indent=2)
        
        # Also save to timestamped backup
        backup_file = self.state_dir / f"state-backup-{int(datetime.utcnow().timestamp())}.json"
        with open(backup_file, 'w') as f:
            json.dump(state, f, indent=2)
    
    def create_checkpoint(self, step_id: str, artifacts: List[str], 
                         validation_results: Dict) -> str:
        """Create a checkpoint for current step"""
        checkpoint_id = f"{step_id}-{int(datetime.utcnow().timestamp())}"
        checkpoint = {
            "checkpoint_id": checkpoint_id,
            "timestamp": datetime.utcnow().isoformat() + 'Z',
            "step": step_id,
            "status": "completed" if validation_results.get("overall") == "passed" else "failed",
            "validation": validation_results,
            "artifacts": {
                "files_created": artifacts,
                "git_commit": self._get_current_git_commit(),
            },
            "environment_snapshot": self._capture_environment()
        }
        
        checkpoint_file = self.checkpoints_dir / f"{checkpoint_id}.json"
        with open(checkpoint_file, 'w') as f:
            json.dump(checkpoint, f, indent=2)
        
        return checkpoint_id
    
    def get_resume_point(self) -> Dict:
        """Determine where to resume implementation"""
        state = self.load_state()
        current_phase = state.get("current_phase")
        
        if not current_phase:
            return {"phase": "planning", "step": "architecture", "action": "start"}
        
        phase_info = state["phases"].get(current_phase, {})
        
        if phase_info.get("status") == "completed":
            # Move to next phase
            next_phase = self._get_next_phase(current_phase)
            return {"phase": next_phase, "step": "start", "action": "begin_phase"}
        
        # Resume current phase
        current_step = phase_info.get("current_step")
        if current_step:
            step_info = phase_info.get("steps", {}).get(current_step, {})
            if step_info.get("status") == "in-progress":
                return {
                    "phase": current_phase,
                    "step": current_step,
                    "action": "resume",
                    "progress": step_info.get("progress", 0)
                }
        
        return {"phase": current_phase, "step": "start", "action": "begin_phase"}
    
    def log_action(self, action: str, details: Dict) -> None:
        """Log agent actions for debugging and recovery"""
        log_entry = {
            "timestamp": datetime.utcnow().isoformat() + 'Z',
            "action": action,
            "details": details
        }
        
        log_file = self.logs_dir / "agent-actions.log"
        with open(log_file, 'a') as f:
            f.write(json.dumps(log_entry) + '\n')
```

#### 2. Agent Resume Logic

```python
# agent_resume.py - Logic for agents to resume work
class AgentResumeManager:
    def __init__(self, state_manager: ImplementationStateManager):
        self.state_manager = state_manager
    
    def get_next_task(self) -> Dict:
        """Get the next task for the agent to work on"""
        resume_point = self.state_manager.get_resume_point()
        state = self.state_manager.load_state()
        
        # Check for blockers
        blockers = state.get("blockers", [])
        if blockers:
            return {
                "type": "resolve_blocker",
                "blocker": blockers[0],
                "priority": "high"
            }
        
        # Get next action from state
        next_actions = state.get("next_actions", [])
        if next_actions:
            return {
                "type": "execute_action",
                "action": next_actions[0],
                "resume_point": resume_point
            }
        
        # Determine next step based on resume point
        return self._determine_next_step(resume_point)
    
    def validate_environment(self) -> Dict:
        """Validate that the environment is ready for work"""
        validation = {
            "workspace_exists": os.path.exists("/workspace"),
            "tools_available": {},
            "api_keys_configured": {},
            "cluster_access": False
        }
        
        # Check tool availability
        tools = ["aider", "kubectl", "docker-compose"]
        for tool in tools:
            validation["tools_available"][tool] = self._check_tool_available(tool)
        
        # Check API keys
        api_keys = ["VOYAGE_API_KEY"]
        for key in api_keys:
            validation["api_keys_configured"][key] = bool(os.getenv(key))
        
        # Check cluster access
        try:
            result = os.system("kubectl cluster-info > /dev/null 2>&1")
            validation["cluster_access"] = result == 0
        except:
            validation["cluster_access"] = False
        
        return validation
    
    def recover_from_failure(self, error: Exception) -> Dict:
        """Attempt to recover from failures"""
        self.state_manager.log_action("error_encountered", {
            "error_type": type(error).__name__,
            "error_message": str(error),
            "recovery_attempted": True
        })
        
        # Try to rollback to last checkpoint
        checkpoints = list(self.state_manager.checkpoints_dir.glob("*.json"))
        if checkpoints:
            latest_checkpoint = max(checkpoints, key=os.path.getctime)
            return {
                "action": "rollback_to_checkpoint",
                "checkpoint": latest_checkpoint.stem,
                "reason": str(error)
            }
        
        return {
            "action": "restart_from_beginning",
            "reason": f"No checkpoints available, error: {str(error)}"
        }
```

#### 3. Integration with Implementation Steps

Update each implementation step to include state tracking:

```python
# Example: Document Processor Implementation with State Tracking
def implement_document_processor():
    state_manager = ImplementationStateManager()
    state = state_manager.load_state()
    
    # Update state to show we're starting this step
    state["phases"]["local-development"]["steps"]["document-processor"] = {
        "status": "in-progress",
        "started_at": datetime.utcnow().isoformat() + 'Z',
        "progress": 0.0
    }
    state_manager.save_state(state)
    
    try:
        # Step 1: Create processor file
        state_manager.log_action("create_file", {
            "file": "services/memory-store/processor/document_processor.py",
            "tool": "avante"
        })
        
        # Use Avante to implement
        # ... implementation code ...
        
        # Update progress
        state["phases"]["local-development"]["steps"]["document-processor"]["progress"] = 0.5
        state_manager.save_state(state)
        
        # Step 2: Create Dockerfile
        # ... more implementation ...
        
        # Validate implementation
        validation_results = validate_processor_implementation()
        
        # Create checkpoint
        artifacts = [
            "services/memory-store/processor/document_processor.py",
            "services/memory-store/processor/Dockerfile",
            "services/memory-store/processor/requirements.txt"
        ]
        checkpoint_id = state_manager.create_checkpoint(
            "document-processor", artifacts, validation_results
        )
        
        # Mark step as completed
        state["phases"]["local-development"]["steps"]["document-processor"] = {
            "status": "completed",
            "completed_at": datetime.utcnow().isoformat() + 'Z',
            "progress": 1.0,
            "checkpoint": checkpoint_id,
            "validation": "passed"
        }
        
        # Set next action
        state["next_actions"] = [{
            "action": "implement_search_api",
            "tool": "avante",
            "description": "Create FastAPI search service"
        }]
        
        state_manager.save_state(state)
        
    except Exception as e:
        # Handle failure
        state["phases"]["local-development"]["steps"]["document-processor"]["status"] = "failed"
        state["blockers"].append({
            "type": "implementation_error",
            "step": "document-processor",
            "error": str(e),
            "timestamp": datetime.utcnow().isoformat() + 'Z'
        })
        state_manager.save_state(state)
        raise
```

### Agent Startup Protocol

#### 1. Agent Initialization Script

```bash
#!/bin/bash
# agent-startup.sh - Run this when agent starts/restarts

echo "🤖 Memory Store Implementation Agent Starting..."

# Check if state directory exists
if [ ! -d ".memory-store-state" ]; then
    echo "📁 Creating state directory..."
    mkdir -p .memory-store-state/{checkpoints,artifacts,logs}
fi

# Initialize Python environment
python3 -c "
from state_manager import ImplementationStateManager, AgentResumeManager

# Initialize managers
state_manager = ImplementationStateManager()
resume_manager = AgentResumeManager(state_manager)

# Validate environment
env_validation = resume_manager.validate_environment()
print('🔍 Environment Validation:', env_validation)

# Get resume point
resume_point = state_manager.get_resume_point()
print('📍 Resume Point:', resume_point)

# Get next task
next_task = resume_manager.get_next_task()
print('📋 Next Task:', next_task)

# Log startup
state_manager.log_action('agent_startup', {
    'environment': env_validation,
    'resume_point': resume_point,
    'next_task': next_task
})
"

echo "✅ Agent initialization complete!"
```

#### 2. Continuous Execution Loop

```python
# agent_main.py - Main agent execution loop
def main():
    state_manager = ImplementationStateManager()
    resume_manager = AgentResumeManager(state_manager)
    
    print("🚀 Starting Memory Store Implementation Agent")
    
    while True:
        try:
            # Get next task
            task = resume_manager.get_next_task()
            
            if task["type"] == "complete":
                print("🎉 Implementation complete!")
                break
            
            print(f"📋 Executing task: {task}")
            
            # Execute task based on type
            if task["type"] == "execute_action":
                execute_implementation_action(task["action"])
            elif task["type"] == "resolve_blocker":
                resolve_blocker(task["blocker"])
            elif task["type"] == "validate_step":
                validate_implementation_step(task["step"])
            
            # Brief pause between tasks
            time.sleep(2)
            
        except KeyboardInterrupt:
            print("🛑 Agent stopped by user")
            break
        except Exception as e:
            print(f"❌ Error: {e}")
            recovery_action = resume_manager.recover_from_failure(e)
            print(f"🔄 Recovery action: {recovery_action}")
            
            if recovery_action["action"] == "restart_from_beginning":
                print("🔄 Restarting implementation from beginning...")
                # Reset state and continue
            elif recovery_action["action"] == "rollback_to_checkpoint":
                print(f"⏪ Rolling back to checkpoint: {recovery_action['checkpoint']}")
                # Rollback logic here
```

### Validation and Testing

#### 1. State Validation

```python
def validate_implementation_state():
    """Validate that the current state is consistent"""
    state_manager = ImplementationStateManager()
    state = state_manager.load_state()
    
    validation_results = {
        "state_file_valid": True,
        "checkpoints_consistent": True,
        "artifacts_exist": True,
        "dependencies_satisfied": True,
        "issues": []
    }
    
    # Validate state file structure
    required_fields = ["implementation_id", "current_phase", "phases"]
    for field in required_fields:
        if field not in state:
            validation_results["state_file_valid"] = False
            validation_results["issues"].append(f"Missing required field: {field}")
    
    # Validate checkpoints
    for checkpoint_file in state_manager.checkpoints_dir.glob("*.json"):
        try:
            with open(checkpoint_file, 'r') as f:
                checkpoint = json.load(f)
            # Validate checkpoint structure
            if "artifacts" not in checkpoint:
                validation_results["checkpoints_consistent"] = False
                validation_results["issues"].append(f"Invalid checkpoint: {checkpoint_file}")
        except json.JSONDecodeError:
            validation_results["checkpoints_consistent"] = False
            validation_results["issues"].append(f"Corrupted checkpoint: {checkpoint_file}")
    
    return validation_results
```

#### 2. Recovery Testing

```python
def test_agent_recovery():
    """Test agent recovery from various failure scenarios"""
    scenarios = [
        "network_interruption",
        "file_system_full",
        "api_key_expired",
        "kubernetes_unavailable",
        "corrupted_state_file"
    ]
    
    for scenario in scenarios:
        print(f"🧪 Testing recovery from: {scenario}")
        # Simulate failure and test recovery
        simulate_failure(scenario)
        recovery_result = test_recovery_mechanism()
        print(f"✅ Recovery test result: {recovery_result}")
```

### Monitoring and Observability

#### 1. Progress Monitoring

```python
def get_implementation_progress():
    """Get detailed progress information"""
    state_manager = ImplementationStateManager()
    state = state_manager.load_state()
    
    progress_info = {
        "overall_progress": state.get("overall_progress", 0),
        "current_phase": state.get("current_phase"),
        "phases_completed": 0,
        "total_phases": len(state.get("phases", {})),
        "current_step_progress": 0,
        "estimated_completion": None,
        "blockers": len(state.get("blockers", [])),
        "last_activity": state.get("last_updated")
    }
    
    # Calculate phases completed
    for phase_name, phase_info in state.get("phases", {}).items():
        if phase_info.get("status") == "completed":
            progress_info["phases_completed"] += 1
    
    # Get current step progress
    current_phase = state.get("current_phase")
    if current_phase and current_phase in state.get("phases", {}):
        phase_info = state["phases"][current_phase]
        current_step = phase_info.get("current_step")
        if current_step and current_step in phase_info.get("steps", {}):
            progress_info["current_step_progress"] = phase_info["steps"][current_step].get("progress", 0)
    
    return progress_info
```

#### 2. Health Checks

```python
def agent_health_check():
    """Comprehensive health check for the agent"""
    health = {
        "status": "healthy",
        "checks": {
            "state_file_accessible": False,
            "workspace_writable": False,
            "tools_available": False,
            "api_connectivity": False,
            "cluster_accessible": False
        },
        "issues": [],
        "recommendations": []
    }
    
    # Check state file
    try:
        state_manager = ImplementationStateManager()
        state = state_manager.load_state()
        health["checks"]["state_file_accessible"] = True
    except Exception as e:
        health["issues"].append(f"State file issue: {e}")
        health["status"] = "degraded"
    
    # Check workspace
    try:
        test_file = Path("/workspace/.health_check")
        test_file.write_text("test")
        test_file.unlink()
        health["checks"]["workspace_writable"] = True
    except Exception as e:
        health["issues"].append(f"Workspace not writable: {e}")
        health["status"] = "unhealthy"
    
    return health
```

This durability system ensures that agents can:

1. **Resume from interruptions** - Always know where they left off
2. **Recover from failures** - Rollback to known good states
3. **Track progress** - Detailed progress monitoring and reporting
4. **Validate consistency** - Ensure state and artifacts are consistent
5. **Handle dependencies** - Understand what needs to be completed before proceeding
6. **Log everything** - Comprehensive logging for debugging and auditing

The system is designed to work in any containerized environment, including Kubernetes AI sandboxes, and provides the durability needed for reliable incremental implementation of complex systems.

## Local Development Setup

### Docker Compose Configuration

Create a `docker-compose.yml` file for local testing:

```yaml
version: '3.8'

services:
  postgres-vector:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_DB: memory_store
      POSTGRES_USER: memory_user
      POSTGRES_PASSWORD: memory_pass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U memory_user -d memory_store"]
      interval: 5s
      timeout: 5s
      retries: 5

  document-processor:
    build:
      context: ./services/memory-store/processor
      dockerfile: Dockerfile
    depends_on:
      postgres-vector:
        condition: service_healthy
    environment:
      - DATABASE_URL=postgresql://memory_user:memory_pass@postgres-vector:5432/memory_store
      - VOYAGE_API_KEY=${VOYAGE_API_KEY}
      - DOCS_PATH=/app/docs
    volumes:
      - ./docs:/app/docs:ro
      - ./services/memory-store/processor:/app
    restart: unless-stopped

  search-api:
    build:
      context: ./services/memory-store/api
      dockerfile: Dockerfile
    depends_on:
      postgres-vector:
        condition: service_healthy
    environment:
      - DATABASE_URL=postgresql://memory_user:memory_pass@postgres-vector:5432/memory_store
      - VOYAGE_API_KEY=${VOYAGE_API_KEY}
    ports:
      - "8000:8000"
    volumes:
      - ./services/memory-store/api:/app
    restart: unless-stopped

volumes:
  postgres_data:
```

### Database Initialization

Create `init.sql` for setting up the database schema:

```sql
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create documents table
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    file_path TEXT UNIQUE NOT NULL,
    title TEXT,
    content TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create document chunks table with vector embeddings
CREATE TABLE document_chunks (
    id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    content TEXT NOT NULL,
    embedding vector(1024), -- voyage-large-2-instruct produces 1024-dimensional vectors
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for efficient searching
CREATE INDEX ON document_chunks USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX ON document_chunks (document_id);
CREATE INDEX ON documents (file_path);
CREATE INDEX ON documents USING GIN (metadata);

-- Create full-text search index
ALTER TABLE document_chunks ADD COLUMN content_tsvector tsvector;
CREATE INDEX ON document_chunks USING GIN (content_tsvector);

-- Function to update tsvector automatically
CREATE OR REPLACE FUNCTION update_content_tsvector() RETURNS trigger AS $$
BEGIN
    NEW.content_tsvector := to_tsvector('english', NEW.content);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update tsvector
CREATE TRIGGER update_content_tsvector_trigger
    BEFORE INSERT OR UPDATE ON document_chunks
    FOR EACH ROW EXECUTE FUNCTION update_content_tsvector();
```

### Quick Start Commands

```bash
# Start local development environment
docker-compose up -d

# Wait for services to be healthy
docker-compose ps

# Set up API keys (create .env file)
echo "VOYAGE_API_KEY=your_voyage_api_key" >> .env

# Process initial documents
docker-compose exec document-processor python process_docs.py

# Test search API
curl "http://localhost:8000/search/semantic?query=ansible%20integration&limit=5"
```

## Implementation Steps

### Step 1: Service Architecture Planning (Aider)

```bash
# Start architectural planning session
aider --architect

# Discussion prompt:
# "Design a memory store system for documentation search that integrates 
#  with our existing compute cluster. Include Qdrant vector DB, document 
#  processing pipeline, and search API following our established patterns."
```

**Expected Aider Output:**
- Service deployment patterns matching your existing infrastructure
- Multi-architecture considerations (ARM64 workers)
- Integration points with Ollama and existing services
- Security and configuration management approach

### Step 2: Create Service Structure (Aider)

```bash
# Generate complete service structure
aider --message "Create memory-store service following the established patterns from ollama and postgres, including encrypted configs, multi-arch support, and Kubernetes deployment"
```

This will create the foundational files following your established conventions.

### Step 3: Document Processor Implementation (Avante)

Create the core document processing service:

**File: `services/memory-store/processor/document_processor.py`**

Key features to implement with Avante:
- Markdown-aware chunking that respects document structure
- Metadata extraction (file path, headers, timestamps)
- Incremental processing for changed documents only
- Integration with your existing Ollama instance

**Avante Implementation:**
1. Open the processor file in Neovim
2. Use `<leader>aa`: "Implement a document processor that chunks markdown files intelligently, preserving code blocks and section context, and generates embeddings using Ollama"

### Step 4: Qdrant Vector Database Deployment (Avante)

**File: `build/playbooks/memory-store/qdrant-deployment.yml`**

Configure Qdrant for your cluster:
- ARM64 compatibility
- Persistent storage configuration
- Resource limits appropriate for your workers
- Service discovery integration

**Avante Implementation:**
1. Open the deployment file
2. Use `<leader>ae`: "Create Qdrant deployment with persistent volumes, ARM64 node affinity, and resource limits suitable for documentation search"

### Step 5: Search API Development (Avante)

**File: `services/memory-store/api/search_api.py`**

Build FastAPI service with:
- Semantic search using vector similarity
- Full-text search capabilities
- Hybrid search combining both approaches
- Context-aware response formatting

**Avante Implementation:**
1. Open the API file
2. Use `<leader>aa`: "Create FastAPI search service with semantic, full-text, and hybrid search endpoints, including proper error handling and response formatting"

## Technical Implementation Details

### Document Processing Pipeline

```python
# Core processor structure
import psycopg2
from pgvector.psycopg2 import register_vector
import requests
import json

class DocumentProcessor:
    def __init__(self):
        self.db_url = os.getenv("DATABASE_URL")
        self.voyage_api_key = os.getenv("VOYAGE_API_KEY")
        self.embedding_model = "voyage-large-2-instruct"  # Best for document search
        self.voyage_url = "https://api.voyageai.com/v1/embeddings"
        self.conn = psycopg2.connect(self.db_url)
        register_vector(self.conn)
        
    def process_document(self, file_path: str):
        """Process a single markdown document"""
        # 1. Parse markdown with metadata extraction
        # 2. Intelligent chunking preserving context
        # 3. Generate embeddings via Ollama
        # 4. Store in PostgreSQL with pgvector
        
    def chunk_markdown(self, content: str, file_path: str):
        """Intelligent markdown chunking"""
        # Preserve code blocks intact
        # Maintain header hierarchy context
        # Respect list and table structures
        # Optimal chunk size for embeddings
        
    def generate_embedding(self, text: str) -> list:
        """Generate embedding using Voyage AI"""
        headers = {
            "Authorization": f"Bearer {self.voyage_api_key}",
            "Content-Type": "application/json"
        }
        
        response = requests.post(
            self.voyage_url,
            headers=headers,
            json={
                "input": [text],
                "model": self.embedding_model
            }
        )
        
        if response.status_code != 200:
            raise Exception(f"Voyage API error: {response.text}")
            
        return response.json()["data"][0]["embedding"]
        
    def store_document_chunks(self, document_id: int, chunks: list):
        """Store document chunks with embeddings in PostgreSQL"""
        with self.conn.cursor() as cur:
            for i, chunk in enumerate(chunks):
                embedding = self.generate_embedding(chunk["content"])
                cur.execute("""
                    INSERT INTO document_chunks 
                    (document_id, chunk_index, content, embedding, metadata)
                    VALUES (%s, %s, %s, %s, %s)
                """, (
                    document_id, 
                    i, 
                    chunk["content"], 
                    embedding, 
                    json.dumps(chunk["metadata"])
                ))
            self.conn.commit()
```

### Search API Structure

```python
# FastAPI search endpoints
from fastapi import FastAPI, HTTPException
import psycopg2
from pgvector.psycopg2 import register_vector
import requests
import os

app = FastAPI()

class SearchAPI:
    def __init__(self):
        self.db_url = os.getenv("DATABASE_URL")
        self.voyage_api_key = os.getenv("VOYAGE_API_KEY")
        self.embedding_model = "voyage-large-2-instruct"
        self.voyage_url = "https://api.voyageai.com/v1/embeddings"
        self.conn = psycopg2.connect(self.db_url)
        register_vector(self.conn)
        
    def generate_embedding(self, text: str) -> list:
        """Generate embedding using Voyage AI"""
        headers = {
            "Authorization": f"Bearer {self.voyage_api_key}",
            "Content-Type": "application/json"
        }
        
        response = requests.post(
            self.voyage_url,
            headers=headers,
            json={
                "input": [text],
                "model": self.embedding_model
            }
        )
        
        return response.json()["data"][0]["embedding"]

@app.post("/search/semantic")
async def semantic_search(query: str, limit: int = 5):
    """Semantic search using vector similarity with pgvector"""
    search_api = SearchAPI()
    
    # Generate query embedding
    embedding = search_api.generate_embedding(query)
    
    # Search PostgreSQL vectors using cosine similarity
    with search_api.conn.cursor() as cur:
        cur.execute("""
            SELECT 
                dc.content,
                d.file_path,
                d.title,
                dc.metadata,
                1 - (dc.embedding <=> %s) as similarity
            FROM document_chunks dc
            JOIN documents d ON dc.document_id = d.id
            ORDER BY dc.embedding <=> %s
            LIMIT %s
        """, (embedding, embedding, limit))
        
        results = cur.fetchall()
    
    return {
        "results": [
            {
                "content": row[0],
                "file_path": row[1],
                "title": row[2],
                "metadata": row[3],
                "similarity": float(row[4])
            }
            for row in results
        ]
    }
    
@app.post("/search/hybrid")
async def hybrid_search(query: str, limit: int = 10):
    """Hybrid search combining semantic + full-text"""
    search_api = SearchAPI()
    
    # Generate query embedding for semantic search
    embedding = search_api.generate_embedding(query)
    
    # Combine vector and full-text search
    with search_api.conn.cursor() as cur:
        cur.execute("""
            WITH semantic_results AS (
                SELECT 
                    dc.id,
                    dc.content,
                    d.file_path,
                    d.title,
                    dc.metadata,
                    (1 - (dc.embedding <=> %s)) * 0.7 as semantic_score
                FROM document_chunks dc
                JOIN documents d ON dc.document_id = d.id
                ORDER BY dc.embedding <=> %s
                LIMIT %s
            ),
            fulltext_results AS (
                SELECT 
                    dc.id,
                    dc.content,
                    d.file_path,
                    d.title,
                    dc.metadata,
                    ts_rank(dc.content_tsvector, plainto_tsquery('english', %s)) * 0.3 as fulltext_score
                FROM document_chunks dc
                JOIN documents d ON dc.document_id = d.id
                WHERE dc.content_tsvector @@ plainto_tsquery('english', %s)
                ORDER BY fulltext_score DESC
                LIMIT %s
            )
            SELECT DISTINCT
                COALESCE(s.content, f.content) as content,
                COALESCE(s.file_path, f.file_path) as file_path,
                COALESCE(s.title, f.title) as title,
                COALESCE(s.metadata, f.metadata) as metadata,
                COALESCE(s.semantic_score, 0) + COALESCE(f.fulltext_score, 0) as combined_score
            FROM semantic_results s
            FULL OUTER JOIN fulltext_results f ON s.id = f.id
            ORDER BY combined_score DESC
            LIMIT %s
        """, (embedding, embedding, limit, query, query, limit, limit))
        
        results = cur.fetchall()
    
    return {
        "results": [
            {
                "content": row[0],
                "file_path": row[1],
                "title": row[2],
                "metadata": row[3],
                "score": float(row[4])
            }
            for row in results
        ]
    }
    
```

### Kubernetes Deployment Configuration

```yaml
# postgres-vector-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-vector
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-vector
  template:
    metadata:
      labels:
        app: postgres-vector
    spec:
      nodeSelector:
        kubernetes.io/arch: arm64
      containers:
      - name: postgres
        image: pgvector/pgvector:pg16
        env:
        - name: POSTGRES_DB
          value: "memory_store"
        - name: POSTGRES_USER
          valueFrom:
            secretKeyRef:
              name: postgres-vector-secret
              key: username
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-vector-secret
              key: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        - name: init-scripts
          mountPath: /docker-entrypoint-initdb.d
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-vector-pvc
      - name: init-scripts
        configMap:
          name: postgres-init-scripts
---
# memory-store-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: memory-store-processor
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: memory-store-processor
  template:
    metadata:
      labels:
        app: memory-store-processor
    spec:
      nodeSelector:
        kubernetes.io/arch: arm64
      containers:
      - name: processor
        image: memory-store-processor:latest
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: postgres-vector-secret
              key: database_url
        - name: VOYAGE_API_KEY
          valueFrom:
            secretKeyRef:
              name: memory-store-secrets
              key: voyage_api_key
        - name: DOCS_PATH
          value: "/app/docs"
        volumeMounts:
        - name: docs-volume
          mountPath: /app/docs
          readOnly: true
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: docs-volume
        hostPath:
          path: /path/to/your/docs
          type: Directory
```

## Integration with Existing Infrastructure

### CLI Extension

Extend your Go CLI tool to include memory store commands:

```go
// cmd/search.go
func searchCmd() *cobra.Command {
    cmd := &cobra.Command{
        Use:   "search [query]",
        Short: "Search documentation using semantic search",
        Args:  cobra.ExactArgs(1),
        Run: func(cmd *cobra.Command, args []string) {
            query := args[0]
            results := searchDocumentation(query)
            displayResults(results)
        },
    }
    return cmd
}

func searchDocumentation(query string) []SearchResult {
    // Call memory store search API
    // Format and return results
}
```

### Monitoring Integration

Add health checks and monitoring:

```yaml
# Health check endpoint
apiVersion: v1
kind: Service
metadata:
  name: memory-store-health
spec:
  selector:
    app: memory-store-api
  ports:
  - port: 8080
    targetPort: 8080
    name: health
```

Integrate with your existing monitoring stack:
- **Scrutiny**: Monitor storage health for Qdrant
- **Uptime Kuma**: API endpoint availability
- **Custom metrics**: Search performance and index freshness

## Configuration Management

### Encrypted Configuration (values.yml.enc)

```yaml
# Encrypted with ansible-vault
memory_store:
  postgres:
    database: "memory_store"
    username: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      [encrypted_username]
    password: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      [encrypted_password]
    host: "postgres-vector-service"
    port: 5432
  voyage:
    api_key: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      [encrypted_voyage_key]
    embedding_model: "voyage-large-2-instruct"
    endpoint: "https://api.voyageai.com/v1/embeddings"
  processing:
    chunk_size: 512
    chunk_overlap: 50
    batch_size: 10
    vector_dimensions: 1024  # voyage-large-2-instruct dimensions
  search:
    max_results: 20
    similarity_threshold: 0.7
    hybrid_semantic_weight: 0.7
    hybrid_fulltext_weight: 0.3
```

### Environment-Specific Settings

```yaml
# group_vars/all.yml
memory_store_config:
  deployment:
    replicas: 1
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "1Gi"
        cpu: "1000m"
  storage:
    size: "10Gi"
    class: "local-storage"
```

## Deployment Workflow

### Phase 1: Local Development Setup

```bash
# Start local development environment
docker-compose up -d

# Wait for services to be healthy
docker-compose ps

# Verify PostgreSQL with pgvector is working
docker-compose exec postgres-vector psql -U memory_user -d memory_store -c "SELECT version();"
docker-compose exec postgres-vector psql -U memory_user -d memory_store -c "SELECT * FROM pg_extension WHERE extname = 'vector';"

# Verify API keys are set
docker-compose exec document-processor env | grep -E "(VOYAGE|ANTHROPIC)_API_KEY"
```

### Phase 2: Production Infrastructure Setup

```bash
# Deploy PostgreSQL with pgvector
cluster deploy postgres-vector

# Verify PostgreSQL is running
kubectl get pods -l app=postgres-vector

# Deploy document processor
cluster deploy memory-store-processor

# Deploy search API
cluster deploy memory-store-api
```

### Phase 2: Initial Indexing

```bash
# Trigger initial document indexing
cluster index-docs

# Monitor indexing progress
cluster memory-store status

# Verify search functionality
cluster search "ansible integration"
```

### Phase 3: Integration Testing

```bash
# Test various search queries
cluster search "security best practices"
cluster search "workflow examples"
cluster search "mongodb upgrade"

# Test hybrid search
cluster search --hybrid "aider avante integration"

```

## Search Capabilities

### Semantic Search Examples

After implementation, you'll be able to perform searches like:

```bash
# Find related concepts
cluster search "ansible automation"
# Returns: ANSIBLE_AI_INTEGRATION_GUIDE.md sections

# Find security information
cluster search "secure installation"
# Returns: AVANTE_SECURITY_ALTERNATIVES.md content

# Find workflow guidance
cluster search "development workflow"
# Returns: WORKFLOW_EXAMPLES.md, AIDER_TERMINAL_GUIDE.md sections

# Find specific procedures
cluster search "mongodb upgrade process"
# Returns: MONGO8_UPGRADE.md with upgrade steps
```


## Performance Optimization

### Embedding Configuration

```python
# Optimized for documentation search with Voyage AI
EMBEDDING_CONFIG = {
    "model": "voyage-large-2-instruct",  # Best for document search
    "dimensions": 1024,                  # Voyage vector size
    "chunk_size": 512,                   # Optimal for documentation
    "chunk_overlap": 50,                 # Maintain context
    "batch_size": 10,                    # Efficient processing
    "max_tokens": 32000,                 # Voyage model limit
}

# API rate limiting
VOYAGE_CONFIG = {
    "requests_per_minute": 300,          # Voyage rate limit
    "batch_size": 128,                   # Max batch size for embeddings
    "retry_attempts": 3,                 # Retry failed requests
    "timeout": 30,                       # Request timeout
}


# PostgreSQL pgvector configuration
PGVECTOR_CONFIG = {
    "index_type": "ivfflat",      # Index type for vector search
    "lists": 100,                 # Number of lists for IVFFlat index
    "distance_metric": "cosine",  # Distance metric for similarity
    "ef_construction": 64,        # Build-time parameter
    "ef_search": 40,             # Search-time parameter
}
```

### Search Optimization

```python
# Search performance tuning for PostgreSQL
SEARCH_CONFIG = {
    "vector_search_limit": 20,        # Initial vector results
    "rerank_limit": 10,               # Final reranked results
    "similarity_threshold": 0.7,      # Minimum similarity (1 - cosine distance)
    "hybrid_semantic_weight": 0.7,    # Weight for semantic search
    "hybrid_fulltext_weight": 0.3,    # Weight for full-text search
    "connection_pool_size": 10,       # PostgreSQL connection pool
    "query_timeout": 30,              # Query timeout in seconds
}

# PostgreSQL-specific optimizations
POSTGRES_OPTIMIZATIONS = {
    "shared_preload_libraries": "vector",
    "max_connections": 100,
    "shared_buffers": "256MB",
    "effective_cache_size": "1GB",
    "work_mem": "64MB",
    "maintenance_work_mem": "256MB",
}
```

### Caching Strategy

```python
# Implement caching for frequent queries
from functools import lru_cache

@lru_cache(maxsize=100)
def cached_search(query: str, search_type: str):
    """Cache frequent search queries"""
    return perform_search(query, search_type)
```

## Maintenance and Updates

### Incremental Updates

```python
# Monitor file changes and update incrementally with PostgreSQL
class DocumentWatcher:
    def __init__(self):
        self.observer = Observer()
        self.db_url = os.getenv("DATABASE_URL")
        self.conn = psycopg2.connect(self.db_url)
        register_vector(self.conn)
        
    def on_modified(self, event):
        if event.src_path.endswith('.md'):
            self.process_updated_document(event.src_path)
            
    def process_updated_document(self, file_path):
        """Update document in PostgreSQL with new embeddings"""
        with self.conn.cursor() as cur:
            # Remove old document and chunks
            cur.execute("""
                DELETE FROM documents WHERE file_path = %s
            """, (file_path,))
            
            # Process and store updated content
            document_id = self.store_document(file_path)
            chunks = self.chunk_markdown_file(file_path)
            self.store_document_chunks(document_id, chunks)
            
            self.conn.commit()
            print(f"Updated document: {file_path}")
            
    def store_document(self, file_path: str) -> int:
        """Store document metadata and return document ID"""
        with open(file_path, 'r') as f:
            content = f.read()
            
        # Extract title from first header or filename
        title = self.extract_title(content, file_path)
        metadata = {
            "file_size": os.path.getsize(file_path),
            "last_modified": os.path.getmtime(file_path),
            "file_type": "markdown"
        }
        
        with self.conn.cursor() as cur:
            cur.execute("""
                INSERT INTO documents (file_path, title, content, metadata)
                VALUES (%s, %s, %s, %s)
                RETURNING id
            """, (file_path, title, content, json.dumps(metadata)))
            
            return cur.fetchone()[0]
```

### Health Monitoring

```bash
# Add health check commands to CLI
cluster memory-store health
cluster memory-store metrics
cluster memory-store reindex

# Monitor key metrics
- Document count in index
- Search response times
- Embedding generation rate
- Storage usage
```

## Troubleshooting

### Common Issues

1. **Slow Search Performance**
   - Check PostgreSQL resource allocation and connection pooling
   - Optimize pgvector index parameters (lists, ef_search)
   - Review chunk size and overlap settings
   - Monitor query execution plans with EXPLAIN ANALYZE

2. **Missing Documents**
   - Verify file monitoring is working
   - Check document processor logs
   - Manually trigger reindexing
   - Verify PostgreSQL connectivity and permissions

3. **Poor Search Results**
   - Adjust embedding model or vector dimensions
   - Tune hybrid search weights (semantic vs full-text)
   - Review document chunking strategy
   - Check pgvector index quality and rebuild if necessary

4. **PostgreSQL-Specific Issues**
   - Monitor connection pool exhaustion
   - Check pgvector extension installation
   - Verify vector index creation and usage
   - Monitor disk space for vector storage

### Debug Commands

```bash
# Debug search issues
cluster memory-store debug-search "query"
cluster memory-store list-documents
cluster memory-store check-embeddings
cluster memory-store reprocess-document "file.md"

# PostgreSQL-specific debugging
cluster memory-store check-postgres-connection
cluster memory-store verify-pgvector-extension
cluster memory-store analyze-vector-index
cluster memory-store check-embedding-dimensions

# Local development debugging
docker-compose exec postgres-vector psql -U memory_user -d memory_store -c "SELECT COUNT(*) FROM documents;"
docker-compose exec postgres-vector psql -U memory_user -d memory_store -c "SELECT COUNT(*) FROM document_chunks;"
docker-compose logs document-processor
docker-compose logs search-api
```

## Security Considerations

### Access Control

```yaml
# Restrict access to memory store services
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: memory-store-policy
spec:
  podSelector:
    matchLabels:
      app: memory-store
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: cluster-cli
```

### Data Privacy

- Ensure sensitive information is not indexed
- Implement access controls for search API
- Use encrypted storage for vector database
- Regular security audits of indexed content

## Future Enhancements

### Phase 2 Features

1. **Advanced Search**
   - Faceted search by document type
   - Time-based filtering
   - Author-based filtering

2. **Integration Enhancements**
   - Slack bot integration
   - Web interface
   - IDE plugins

3. **AI Enhancements**
   - Question answering with citations
   - Document summarization
   - Automated documentation updates

### Scaling Considerations

- PostgreSQL read replicas for search queries
- Connection pooling with PgBouncer
- Distributed processing with multiple document processors
- Load balancing for search API
- Horizontal scaling of processors
- PostgreSQL partitioning for large document collections
- Caching layer (Redis) for frequent queries
- Asynchronous processing queues for document updates


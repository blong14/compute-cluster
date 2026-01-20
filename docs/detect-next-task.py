#!/usr/bin/env python3
import os
import glob
from pathlib import Path

def detect_next_task():
    """Analyze current state and suggest next task for Aider"""
    
    # Check what files exist
    memory_store_dir = Path("memory-store")
    
    if not memory_store_dir.exists():
        return {
            "task": "Create initial memory-store directory structure",
            "command": "aider --message 'Create memory-store directory with docker-compose.yml and init.sql following the implementation plan'",
            "files": [],
            "priority": "high",
            "description": "Set up the foundational directory structure and configuration files"
        }
    
    # Check docker-compose.yml
    if not (memory_store_dir / "docker-compose.yml").exists():
        return {
            "task": "Create docker-compose.yml for local development",
            "command": "aider memory-store/ --message 'Create docker-compose.yml with PostgreSQL pgvector, document processor, and search API services'",
            "files": ["memory-store/"],
            "priority": "high",
            "description": "Set up local development environment with all required services"
        }
    
    # Check init.sql
    if not (memory_store_dir / "init.sql").exists():
        return {
            "task": "Create PostgreSQL schema with pgvector",
            "command": "aider memory-store/init.sql --message 'Create PostgreSQL schema with pgvector extension, documents table, and vector indexes'",
            "files": ["memory-store/init.sql"],
            "priority": "high",
            "description": "Set up database schema with vector search capabilities"
        }
    
    # Check processor service
    processor_dir = memory_store_dir / "processor"
    if not processor_dir.exists() or not (processor_dir / "document_processor.py").exists():
        return {
            "task": "Create document processor service",
            "command": "aider memory-store/processor/ --message 'Create document processor service with Voyage AI embeddings and PostgreSQL storage'",
            "files": ["memory-store/processor/"],
            "priority": "medium",
            "description": "Implement service to process markdown files and generate embeddings"
        }
    
    # Check API service
    api_dir = memory_store_dir / "api"
    if not api_dir.exists() or not (api_dir / "search_api.py").exists():
        return {
            "task": "Create search API service",
            "command": "aider memory-store/api/ --message 'Create FastAPI search service with semantic and hybrid search endpoints'",
            "files": ["memory-store/api/"],
            "priority": "medium",
            "description": "Implement REST API for semantic and full-text search"
        }
    
    # Check Kubernetes deployments
    k8s_dir = memory_store_dir / "kubernetes"
    if not k8s_dir.exists():
        return {
            "task": "Create Kubernetes deployment configurations",
            "command": "aider memory-store/kubernetes/ --message 'Create Kubernetes deployments for production memory store services'",
            "files": ["memory-store/kubernetes/"],
            "priority": "low",
            "description": "Set up production deployment configurations"
        }
    
    return {
        "task": "Implementation appears complete - run tests and integration",
        "command": "aider memory-store/ --message 'Review and test the complete memory store implementation, add any missing components'",
        "files": ["memory-store/"],
        "priority": "low",
        "description": "Final review and testing of the complete system"
    }

def update_next_actions():
    """Update NEXT_ACTIONS.md with detected task"""
    task_info = detect_next_task()
    
    next_actions = f"""# Next Actions for Aider

## Immediate Next Task: {task_info['task']}
**Priority:** {task_info['priority']}
**Description:** {task_info['description']}

**Command to run:**
```bash
{task_info['command']}
```

**Files to work with:**
{chr(10).join(f'- {f}' for f in task_info['files']) if task_info['files'] else '- (Aider will determine based on task)'}

## Context
Read CURRENT_TASK.md for detailed context about what we're building.
Follow the patterns established in AIDER_CONTEXT.md.
Reference MEMORY_STORE_IMPLEMENTATION_GUIDE.md for technical details.

## Implementation Guidelines
1. Use PostgreSQL with pgvector extension (not Qdrant)
2. Integrate with Voyage AI for embeddings (not Ollama)
3. Follow existing compute cluster service patterns
4. Include proper error handling and logging
5. Add health checks and monitoring
6. Support multi-architecture deployment (ARM64)

## After completing this task:
1. Test your implementation with provided validation steps
2. Run `python update-progress.py <step> completed <progress> "<notes>"`
3. Run `python detect-next-task.py` to get the next task
4. Continue with `aider --message "continue with the plan"`

## Validation
Each implementation should include:
- Working code with proper error handling
- Docker/docker-compose configuration
- Test commands to verify functionality
- Clear next steps or completion criteria
"""
    
    os.makedirs('.memory-store-state', exist_ok=True)
    with open('.memory-store-state/NEXT_ACTIONS.md', 'w') as f:
        f.write(next_actions)
    
    print(f"📋 Next task detected: {task_info['task']}")
    print(f"🔧 Run: {task_info['command']}")
    return task_info

if __name__ == "__main__":
    update_next_actions()

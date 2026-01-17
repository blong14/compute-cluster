#!/usr/bin/env python3
import os
import json
from datetime import datetime

def update_progress(step_name, status, progress=None, notes=None):
    """Update implementation progress in Aider-readable format"""
    
    # Ensure state directory exists
    os.makedirs('.memory-store-state', exist_ok=True)
    
    # Update the current task file
    current_task = f"""# Current Implementation Task

## Phase: Local Development Setup
## Step: {step_name}
## Status: {status}
## Progress: {progress or 'N/A'}% complete
## Last Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

### Notes:
{notes or 'No additional notes'}

### Files being worked on:
{get_current_files()}

### What needs to be done next:
{get_next_steps(step_name, status)}

### Context for Aider:
This is part of implementing a memory store system for documentation search. 
We're using PostgreSQL with pgvector instead of Qdrant, and Voyage AI for embeddings.
The system will index markdown documentation and provide semantic search.

### Validation criteria:
{get_validation_criteria(step_name)}
"""
    
    with open('.memory-store-state/CURRENT_TASK.md', 'w') as f:
        f.write(current_task)
    
    # Update completed steps
    if status == "completed":
        add_completed_step(step_name)
    
    print(f"✅ Progress updated: {step_name} - {status}")

def get_current_files():
    """Get list of files currently being worked on"""
    try:
        with open('.memory-store-state/context/current-files.txt', 'r') as f:
            return f.read().strip()
    except FileNotFoundError:
        return "No files specified"

def get_next_steps(step_name, status):
    """Get next steps based on current step and status"""
    if status == "completed":
        return "Run `python detect-next-task.py` to get the next task"
    elif "database" in step_name.lower():
        return "Complete PostgreSQL schema with pgvector indexes and triggers"
    elif "processor" in step_name.lower():
        return "Implement document chunking and embedding generation"
    elif "api" in step_name.lower():
        return "Create search endpoints with semantic and hybrid search"
    else:
        return "Continue with current implementation"

def get_validation_criteria(step_name):
    """Get validation criteria for the current step"""
    if "database" in step_name.lower():
        return """- [ ] PostgreSQL starts with pgvector extension
- [ ] All tables and indexes created correctly
- [ ] Docker compose connects successfully
- [ ] Init script runs without errors"""
    elif "processor" in step_name.lower():
        return """- [ ] Document processor reads markdown files
- [ ] Voyage AI embeddings generated successfully
- [ ] Documents stored in PostgreSQL
- [ ] Service starts without errors"""
    elif "api" in step_name.lower():
        return """- [ ] Search API starts successfully
- [ ] Semantic search returns results
- [ ] Full-text search works
- [ ] API endpoints respond correctly"""
    else:
        return "- [ ] Implementation step completed successfully"

def add_completed_step(step_name):
    """Add step to completed list"""
    completed_file = '.memory-store-state/COMPLETED_STEPS.md'
    
    if os.path.exists(completed_file):
        with open(completed_file, 'r') as f:
            content = f.read()
    else:
        content = "# Completed Implementation Steps\n\n"
    
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    content += f"- [x] {step_name} (completed: {timestamp})\n"
    
    with open(completed_file, 'w') as f:
        f.write(content)

if __name__ == "__main__":
    import sys
    if len(sys.argv) >= 3:
        step = sys.argv[1]
        status = sys.argv[2]
        progress = sys.argv[3] if len(sys.argv) > 3 else None
        notes = sys.argv[4] if len(sys.argv) > 4 else None
        update_progress(step, status, progress, notes)
    else:
        print("Usage: python update-progress.py <step_name> <status> [progress] [notes]")
        print("Example: python update-progress.py 'database-schema' 'completed' '100' 'PostgreSQL schema created successfully'")

#!/usr/bin/env python3                                                                                                                                                        
"""                                                                                                                                                                           
Comprehensive task tracking script for memory store implementation.                                                                                                           
Provides visual progress tracking, dependency management, and workflow integration.                                                                                           
"""                                                                                                                                                                           
                                                                                                                                                                              
import json                                                                                                                                                                   
import argparse                                                                                                                                                               
from datetime import datetime                                                                                                                                                 
from pathlib import Path                                                                                                                                                      
from typing import Dict, List, Optional, Tuple                                                                                                                                

                                                                                                                                                                              
class TaskTracker:                                                                                                                                                            
    def __init__(self):                                                                                                                                                       
        self.state_dir = Path('.memory-store-state')                                                                                                                          
        self.state_file = self.state_dir / 'task-state.json'                                                                                                                  
        self.state_dir.mkdir(exist_ok=True)                                                                                                                                   
                                                                                                                                                                              
        # Define all implementation tasks across 5 phases                                                                                                                     
        self.tasks = {                                                                                                                                                        
            "phase1_foundation": {                                                                                                                                            
                "name": "Phase 1: Foundation Setup",                                                                                                                          
                "description": "Set up basic infrastructure and configuration",                                                                                               
                "tasks": {                                                                                                                                                    
                    "directory_structure": {                                                                                                                                  
                        "name": "Create memory-store directory structure",                                                                                                    
                        "description": "Set up foundational directories and files",                                                                                           
                        "files": ["memory-store/", "memory-store/docker-compose.yml"],                                                                                        
                        "command": "aider memory-store/ --config .aider.memory-store.yml --message 'Create memory-store directory with docker-compose.yml and basic structure'",                                                                                                                                                                  
                        "validation": ["Directory exists", "Docker compose file created"],                                                                                    
                        "dependencies": [],                                                                                                                                   
                    },                                                                                                                                                        
                    "database_schema": {                                                                                                                                      
                        "name": "Create PostgreSQL schema with pgvector",                                                                                                     
                        "description": "Set up database schema with vector search capabilities",                                                                              
                        "files": ["memory-store/init.sql"],                                                                                                                   
                        "command": "aider memory-store/init.sql --config .aider.memory-store.yml --message 'Create PostgreSQL schema with pgvector extension, documents table, and vector indexes'",                                                                                                                                                         
                        "validation": ["init.sql created", "pgvector extension enabled", "Tables and indexes defined"],                                                       
                        "dependencies": ["directory_structure"],                                                                                                              
                    },                                                                                                                                                        
                    "environment_config": {                                                                                                                                   
                        "name": "Set up environment configuration",                                                                                                           
                        "description": "Create environment files and configuration templates",                                                                                
                        "files": ["memory-store/.env.example", "memory-store/config/"],                                                                                       
                        "command": "aider memory-store/ --config .aider.memory-store.yml --message 'Create environment configuration files and templates for API keys and database settings'",                                                                                                                                                          
                        "validation": ["Environment templates created", "Configuration documented"],                                                                          
                        "dependencies": ["directory_structure"],                                                                                                              
                    }                                                                                                                                                         
                }                                                                                                                                                             
            },                                                                                                                                                                
            "phase2_services": {                                                                                                                                              
                "name": "Phase 2: Core Services",                                                                                                                             
                "description": "Implement document processor and search API services",                                                                                        
                "tasks": {                                                                                                                                                    
                    "document_processor": {                                                                                                                                   
                        "name": "Create document processor service",                                                                                                          
                        "description": "Implement service to process markdown files and generate embeddings",                                                                 
                        "files": ["memory-store/processor/", "memory-store/processor/document_processor.py", "memory-store/processor/Dockerfile"],                            
                        "command": "aider memory-store/processor/ --config .aider.memory-store.yml --message 'Create document processor service with Voyage AI embeddings, PostgreSQL storage, and intelligent markdown chunking'",                                                                                                                      
                        "validation": ["Processor service created", "Dockerfile configured", "Requirements defined"],                                                         
                        "dependencies": [
                            "phase1_foundation.database_schema",
                            "phase1_foundation.environment_config",
                        ],                                                                                            
                    },                                                                                                                                                        
                    "search_api": {                                                                                                                                           
                        "name": "Create search API service",                                                                                                                  
                        "description": "Implement FastAPI service for semantic and hybrid search",                                                                            
                        "files": ["memory-store/api/", "memory-store/api/search_api.py", "memory-store/api/Dockerfile"],                                                      
                        "command": "aider memory-store/api/ --config .aider.memory-store.yml --message 'Create FastAPI search service with semantic, full-text, and hybrid search endpoints'",                                                                                                                                                           
                        "validation": ["API service created", "Search endpoints implemented", "Health checks added"],                                                         
                        "dependencies": [
                            "phase1_foundation.database_schema",
                            "phase1_foundation.environment_config",
                        ],                                                                                            
                    },                                                                                                                                                        
                    "docker_integration": {                                                                                                                                   
                        "name": "Integrate services with Docker Compose",                                                                                                     
                        "description": "Update docker-compose.yml with all services and dependencies",                                                                        
                        "files": ["memory-store/docker-compose.yml"],                                                                                                         
                        "command": "aider memory-store/docker-compose.yml --config .aider.memory-store.yml --message 'Update docker-compose.yml to include processor and API services with proper dependencies and networking'",                                                                                                                           
                        "validation": ["All services defined", "Dependencies configured", "Health checks included"],                                                          
                        "dependencies": [
                            "phase2_services.embedding_service",
                            "phase2_services.document_processor",
                            "phase2_services.search_api",
                        ],                                                                                                 
                    }                                                                                                                                                         
                }                                                                                                                                                             
            },                                                                                                                                                                
            "phase3_testing": {                                                                                                                                               
                "name": "Phase 3: Local Testing",                                                                                                                             
                "description": "Test services locally and validate functionality",                                                                                            
                "tasks": {                                                                                                                                                    
                    "local_deployment": {                                                                                                                                     
                        "name": "Deploy and test local environment",                                                                                                          
                        "description": "Start services locally and verify they work together",                                                                                
                        "files": ["memory-store/test-local.sh"],                                                                                                              
                        "command": "aider memory-store/ --config .aider.memory-store.yml --message 'Create test script to deploy locally and validate all services are working'",                                                                                                                                                                    
                        "validation": ["Services start successfully", "Database connections work", "API endpoints respond"],                                                  
                        "dependencies": ["phase2_services.docker_integration"],                                                                                                               
                    },                                                                                                                                                        
                    "document_processing_test": {                                                                                                                             
                        "name": "Test document processing pipeline",                                                                                                          
                        "description": "Process sample documents and verify embeddings are generated",                                                                        
                        "files": ["memory-store/test-docs/", "memory-store/test-processing.sh"],                                                                              
                        "command": "aider memory-store/ --config .aider.memory-store.yml --message 'Create test documents and scripts to verify document processing and embedding generation'",                                                                                                                                                       
                        "validation": ["Sample docs processed", "Embeddings generated", "Database populated"],                                                                
                        "dependencies": ["phase3_testing.local_deployment"],                                                                                                                 
                    },                                                                                                                                                        
                    "search_functionality_test": {                                                                                                                            
                        "name": "Test search functionality",                                                                                                                  
                        "description": "Verify semantic and hybrid search work correctly",                                                                                    
                        "files": ["memory-store/test-search.sh"],                                                                                                             
                        "command": "aider memory-store/ --config .aider.memory-store.yml --message 'Create search tests to verify semantic, full-text, and hybrid search functionality'",                                                                                                                                                              
                        "validation": ["Semantic search works", "Full-text search works", "Hybrid search works"],                                                             
                        "dependencies": ["phase3_testing.document_processing_test"],                                                                                                         
                    }                                                                                                                                                         
                }                                                                                                                                                             
            },                                                                                                                                                                
            "phase4_kubernetes": {                                                                                                                                            
                "name": "Phase 4: Kubernetes Deployment",                                                                                                                     
                "description": "Create production Kubernetes deployments",                                                                                                    
                "tasks": {                                                                                                                                                    
                    "helm_chart_update": {                                                                                                                                    
                        "name": "Update Helm chart with new services",                                                                                                        
                        "description": "Add processor and API services to existing Helm chart",                                                                               
                        "files": ["build/charts/memory-store/templates/", "build/charts/memory-store/values.yaml"],                                                           
                        "command": "aider build/charts/memory-store/ --config .aider.memory-store.yml --message 'Update Helm chart to include processor and API deployments with proper ARM64 affinity'",                                                                                                                                                 
                        "validation": ["Deployments added", "Services configured", "ARM64 affinity set"],                                                                     
                        "dependencies": ["phase3_testing.search_functionality_test"],                                                                                                        
                    },                                                                                                                                                        
                    "ansible_playbook_update": {                                                                                                                              
                        "name": "Update Ansible deployment playbook",                                                                                                         
                        "description": "Update build.yml to deploy memory store services",                                                                                    
                        "files": ["build/playbooks/memory-store/build.yml"],                                                                                                  
                        "command": "aider build/playbooks/memory-store/build.yml --config .aider.memory-store.yml --message 'Update Ansible playbook to deploy memory store with proper secrets and configuration'",                                                                                                                                      
                        "validation": ["Playbook updated", "Secrets handling added", "Deployment steps defined"],                                                             
                        "dependencies": ["phase4_kubernetes.helm_chart_update"],                                                                                                                
                    },                                                                                                                                                        
                    "production_deployment": {                                                                                                                                
                        "name": "Deploy to production cluster",                                                                                                               
                        "description": "Deploy memory store to the actual Kubernetes cluster",                                                                                
                        "files": [],                                                                                                                                          
                        "command": "ansible-playbook build/playbooks/memory-store/build.yml -i inventory",                                                                    
                        "validation": ["Services deployed", "Pods running", "Ingress accessible"],                                                                            
                        "dependencies": ["phase4_kubernetes.ansible_playbook_update"],                                                                                                          
                    }                                                                                                                                                         
                }                                                                                                                                                             
            },                                                                                                                                                                
            "phase5_integration": {                                                                                                                                           
                "name": "Phase 5: CLI Integration",                                                                                                                           
                "description": "Integrate search functionality with existing CLI",                                                                                            
                "tasks": {                                                                                                                                                    
                    "cli_commands_update": {                                                                                                                                  
                        "name": "Update CLI search commands",                                                                                                                 
                        "description": "Enhance existing search.go with new functionality",                                                                                   
                        "files": ["src/cmd/search.go"],                                                                                                                       
                        "command": "aider src/cmd/search.go --config .aider.memory-store.yml --message 'Update search commands to use the new memory store API with better error handling and output formatting'",                                                                                                                                       
                        "validation": ["Commands updated", "Error handling improved", "Output formatted"],                                                                    
                        "dependencies": ["phase4_kubernetes.production_deployment"],                                                                                                            
                    },                                                                                                                                                        
                    "cli_testing": {                                                                                                                                          
                        "name": "Test CLI integration",                                                                                                                       
                        "description": "Test search commands work with deployed services",                                                                                    
                        "files": ["test-cli-search.sh"],                                                                                                                      
                        "command": "aider --config .aider.memory-store.yml --message 'Create test script to verify CLI search commands work with deployed memory store'",     
                        "validation": ["CLI commands work", "Search results returned", "Error handling works"],                                                               
                        "dependencies": ["phase5_integration.cli_commands_update"],                                                                                                              
                    },                                                                                                                                                        
                    "documentation_update": {                                                                                                                                 
                        "name": "Update documentation",                                                                                                                       
                        "description": "Update README and documentation with new search capabilities",                                                                        
                        "files": ["README.md", "docs/SEARCH_USAGE.md"],                                                                                                       
                        "command": "aider README.md docs/ --config .aider.memory-store.yml --message 'Update documentation to include memory store search capabilities and usage examples'",                                                                                                                                                             
                        "validation": ["README updated", "Usage docs created", "Examples provided"],                                                                          
                        "dependencies": ["phase5_integration.cli_testing"],                                                                                                                      
                    }                                                                                                                                                         
                }                                                                                                                                                             
            }                                                                                                                                                                 
        }                                                                                                                                                                     
                                                                                                                                                                              
    def load_state(self) -> Dict:                                                                                                                                             
        """Load current task state"""                                                                                                                                         
        if self.state_file.exists():                                                                                                                                          
            with open(self.state_file, 'r') as f:                                                                                                                             
                return json.load(f)                                                                                                                                           
        return {                                                                                                                                                              
            "started_at": datetime.now().isoformat(),                                                                                                                         
            "last_updated": datetime.now().isoformat(),                                                                                                                       
            "completed_tasks": {},                                                                                                                                            
            "current_phase": "phase1_foundation",                                                                                                                             
            "notes": {}                                                                                                                                                       
        }                                                                                                                                                                     
                                                                                                                                                                              
    def save_state(self, state: Dict) -> None:                                                                                                                                
        """Save task state"""                                                                                                                                                 
        state['last_updated'] = datetime.now().isoformat()                                                                                                                    
        with open(self.state_file, 'w') as f:                                                                                                                                 
            json.dump(state, f, indent=2)                                                                                                                                     
                                                                                                                                                                              
    def get_task_status(self, phase_id: str, task_id: str, state: Dict) -> str:                                                                                               
        """Get status of a specific task"""                                                                                                                                   
        task_key = f"{phase_id}.{task_id}"                                                                                                                                    
        if task_key in state.get('completed_tasks', {}):                                                                                                                      
            return "✅ COMPLETED"                                                                                                                                             
                                                                                                                                                                              
        # Check if dependencies are met                                                                                                                                       
        task = self.tasks[phase_id]['tasks'][task_id]                                                                                                                         
        for dep in task['dependencies']:                                                                                                                                      
            dep_key = f"{phase_id}.{dep}"                                                                                                                                     
            if dep_key not in state.get('completed_tasks', {}):                                                                                                               
                return "⏸️  BLOCKED"                                                                                                                                          
                                                                                                                                                                              
        # Check if this is the next logical task                                                                                                                              
        if self.is_next_task(phase_id, task_id, state):                                                                                                                       
            return "🔄 READY"                                                                                                                                                 
                                                                                                                                                                              
        return "⏳ PENDING"                                                                                                                                                   
                                                                                                                                                                              
    def is_next_task(self, phase_id: str, task_id: str, state: Dict) -> bool:                                                                                                 
        """Check if this is the next logical task to work on"""                                                                                                               
        # All dependencies must be completed                                                                                                                                  
        task = self.tasks[phase_id]['tasks'][task_id]                                                                                                                         
        for dep in task['dependencies']:                                                                                                                                      
            if dep not in state.get('completed_tasks', {}):                                                                                                               
                return False                                                                                                                                                  
                                                                                                                                                                              
        # Task must not be completed                                                                                                                                          
        task_key = f"{phase_id}.{task_id}"                                                                                                                                    
        if task_key in state.get('completed_tasks', {}):                                                                                                                      
            return False                                                                                                                                                      
                                                                                                                                                                              
        # Check if we're in the right phase                                                                                                                                   
        current_phase = state.get('current_phase', 'phase1_foundation')                                                                                                       
        if phase_id != current_phase:                                                                                                                                         
            # Only move to next phase if current phase is complete                                                                                                            
            if not self.is_phase_complete(current_phase, state):                                                                                                              
                return False                                                                                                                                                  
                                                                                                                                                                              
        return True                                                                                                                                                           
                                                                                                                                                                              
    def is_phase_complete(self, phase_id: str, state: Dict) -> bool:                                                                                                          
        """Check if a phase is complete"""                                                                                                                                    
        if phase_id not in self.tasks:                                                                                                                                        
            return False                                                                                                                                                      
                                                                                                                                                                              
        for task_id in self.tasks[phase_id]['tasks']:                                                                                                                         
            task_key = f"{phase_id}.{task_id}"                                                                                                                                
            if task_key not in state.get('completed_tasks', {}):                                                                                                              
                return False                                                                                                                                                  
        return True                                                                                                                                                           
                                                                                                                                                                              
    def get_next_tasks(self, state: Dict, limit: int = 3) -> List[Tuple[str, str, Dict]]:                                                                                     
        """Get next recommended tasks"""                                                                                                                                      
        next_tasks = []                                                                                                                                                       
                                                                                                                                                                              
        for phase_id, phase in self.tasks.items():                                                                                                                            
            for task_id, task in phase['tasks'].items():                                                                                                                      
                if self.is_next_task(phase_id, task_id, state):                                                                                                               
                    next_tasks.append((phase_id, task_id, task))                                                                                                              
                    if len(next_tasks) >= limit:                                                                                                                              
                        return next_tasks                                                                                                                                     
                                                                                                                                                                              
        return next_tasks                                                                                                                                                     
                                                                                                                                                                              
    def complete_task(self, phase_id: str, task_id: str, notes: str = "") -> bool:                                                                                            
        """Mark a task as completed"""                                                                                                                                        
        if phase_id not in self.tasks or task_id not in self.tasks[phase_id]['tasks']:                                                                                        
            print(f"❌ Task not found: {phase_id}.{task_id}")                                                                                                                 
            return False                                                                                                                                                      
                                                                                                                                                                              
        state = self.load_state()                                                                                                                                             
        task_key = f"{phase_id}.{task_id}"                                                                                                                                    
                                                                                                                                                                              
        state['completed_tasks'][task_key] = {                                                                                                                                
            "completed_at": datetime.now().isoformat(),                                                                                                                       
            "notes": notes                                                                                                                                                    
        }                                                                                                                                                                     
                                                                                                                                                                              
        if notes:                                                                                                                                                             
            state['notes'][task_key] = notes                                                                                                                                  
                                                                                                                                                                              
        # Update current phase if this phase is now complete                                                                                                                  
        if self.is_phase_complete(phase_id, state):                                                                                                                           
            next_phase = self.get_next_phase(phase_id)                                                                                                                        
            if next_phase:                                                                                                                                                    
                state['current_phase'] = next_phase                                                                                                                           
                print(f"🎉 Phase {phase_id} completed! Moving to {next_phase}")                                                                                               
                                                                                                                                                                              
        self.save_state(state)                                                                                                                                                
        print(f"✅ Task completed: {self.tasks[phase_id]['tasks'][task_id]['name']}")                                                                                         
        return True                                                                                                                                                           
                                                                                                                                                                              
    def get_next_phase(self, current_phase: str) -> Optional[str]:                                                                                                            
        """Get the next phase after current one"""                                                                                                                            
        phases = list(self.tasks.keys())                                                                                                                                      
        try:                                                                                                                                                                  
            current_index = phases.index(current_phase)                                                                                                                       
            if current_index + 1 < len(phases):                                                                                                                               
                return phases[current_index + 1]                                                                                                                              
        except ValueError:                                                                                                                                                    
            pass                                                                                                                                                              
        return None                                                                                                                                                           
                                                                                                                                                                              
    def show_progress(self, detailed: bool = False) -> None:                                                                                                                  
        """Show overall progress"""                                                                                                                                           
        state = self.load_state()                                                                                                                                             
                                                                                                                                                                              
        print("🚀 Memory Store Implementation Progress")                                                                                                                      
        print("=" * 50)                                                                                                                                                       
                                                                                                                                                                              
        total_tasks = sum(len(phase['tasks']) for phase in self.tasks.values())                                                                                               
        completed_tasks = len(state.get('completed_tasks', {}))                                                                                                               
        progress_percent = (completed_tasks / total_tasks) * 100                                                                                                              
                                                                                                                                                                              
        print(f"📊 Overall Progress: {completed_tasks}/{total_tasks} tasks ({progress_percent:.1f}%)")                                                                        
        print(f"📅 Started: {state.get('started_at', 'Unknown')}")                                                                                                            
        print(f"🔄 Last Updated: {state.get('last_updated', 'Unknown')}")                                                                                                     
        print(f"📍 Current Phase: {state.get('current_phase', 'Unknown')}")                                                                                                   
        print()                                                                                                                                                               
                                                                                                                                                                              
        # Show progress bar                                                                                                                                                   
        bar_length = 30                                                                                                                                                       
        filled_length = int(bar_length * progress_percent / 100)                                                                                                              
        bar = "█" * filled_length + "░" * (bar_length - filled_length)                                                                                                        
        print(f"Progress: [{bar}] {progress_percent:.1f}%")                                                                                                                   
        print()                                                                                                                                                               
                                                                                                                                                                              
        # Show phase breakdown                                                                                                                                                
        for phase_id, phase in self.tasks.items():                                                                                                                            
            phase_tasks = len(phase['tasks'])                                                                                                                                 
            phase_completed = sum(1 for task_id in phase['tasks']                                                                                                             
                                if f"{phase_id}.{task_id}" in state.get('completed_tasks', {}))                                                                               
            phase_percent = (phase_completed / phase_tasks) * 100                                                                                                             
                                                                                                                                                                              
            status_icon = "✅" if phase_completed == phase_tasks else "🔄" if phase_id == state.get('current_phase') else "⏳"                                                
            print(f"{status_icon} {phase['name']}: {phase_completed}/{phase_tasks} ({phase_percent:.0f}%)")                                                                   
                                                                                                                                                                              
            if detailed:                                                                                                                                                      
                for task_id, task in phase['tasks'].items():                                                                                                                  
                    task_status = self.get_task_status(phase_id, task_id, state)                                                                                              
                    print(f"    {task_status} {task['name']}")                                                                                                                
                    if detailed and f"{phase_id}.{task_id}" in state.get('completed_tasks', {}):                                                                              
                        completed_info = state['completed_tasks'][f"{phase_id}.{task_id}"]                                                                                    
                        print(f"        Completed: {completed_info.get('completed_at', 'Unknown')}")                                                                          
                        if completed_info.get('notes'):                                                                                                                       
                            print(f"        Notes: {completed_info['notes']}")                                                                                                
                print()                                                                                                                                                       
                                                                                                                                                                              
    def show_next_tasks(self, limit: int = 3) -> None:                                                                                                                        
        """Show next recommended tasks"""                                                                                                                                     
        state = self.load_state()                                                                                                                                             
        next_tasks = self.get_next_tasks(state, limit)                                                                                                                        
                                                                                                                                                                              
        if not next_tasks:                                                                                                                                                    
            print("🎉 All tasks completed! Memory store implementation is done!")                                                                                             
            return                                                                                                                                                            
                                                                                                                                                                              
        print(f"📋 Next {len(next_tasks)} Recommended Tasks:")                                                                                                                
        print("=" * 40)                                                                                                                                                       
                                                                                                                                                                              
        for i, (phase_id, task_id, task) in enumerate(next_tasks, 1):                                                                                                         
            print(f"{i}. {task['name']}")                                                                                                                                     
            print(f"   ID: {phase_id}.{task_id}")                                                                                                                         
            print(f"   📝 {task['description']}")                                                                                                                             
            print(f"   🔧 Command: {task['command']}")                                                                                                                        
            print(f"   📁 Files: {', '.join(task['files'])}")                                                                                                                 
                                                                                                                                                                              
            # Show validation criteria                                                                                                                                        
            if task.get('validation'):                                                                                                                                        
                print("   ✅ Validation:")                                                                                                                                   
                for criterion in task['validation']:                                                                                                                          
                    print(f"      - [ ] {criterion}")                                                                                                                         
                                                                                                                                                                              
            print()                                                                                                                                                           
                                                                                                                                                                              
    def find_task(self, search_term: str) -> List[Tuple[str, str, Dict]]:                                                                                                     
        """Find tasks matching search term"""                                                                                                                                 
        results = []                                                                                                                                                          
        search_lower = search_term.lower()                                                                                                                                    
                                                                                                                                                                              
        for phase_id, phase in self.tasks.items():                                                                                                                            
            for task_id, task in phase['tasks'].items():                                                                                                                      
                if (search_lower in task['name'].lower() or                                                                                                                   
                    search_lower in task['description'].lower() or                                                                                                            
                    search_lower in task_id.lower()):                                                                                                                         
                    results.append((phase_id, task_id, task))                                                                                                                 
                                                                                                                                                                              
        return results                                                                                                                                                        
                                                                                                                                                                              
def main():                                                                                                                                                                   
    parser = argparse.ArgumentParser(description='Memory Store Implementation Task Tracker')                                                                                  
    parser.add_argument('--detailed', action='store_true', help='Show detailed progress')                                                                                     
    parser.add_argument('--next', action='store_true', help='Show next recommended tasks')                                                                                    
    parser.add_argument('--complete', nargs=2, metavar=('TASK', 'NOTES'),                                                                                                     
                       help='Mark task as complete: --complete "phase.task" "completion notes"')                                                                              
    parser.add_argument('--find', metavar='SEARCH', help='Find tasks matching search term')                                                                                   
    parser.add_argument('--limit', type=int, default=3, help='Limit number of next tasks shown')                                                                              
                                                                                                                                                                              
    args = parser.parse_args()                                                                                                                                                
    tracker = TaskTracker()                                                                                                                                                   
                                                                                                                                                                              
    if args.complete:                                                                                                                                                         
        task_path, notes = args.complete                                                                                                                                      
        if '.' in task_path:                                                                                                                                                  
            phase_id, task_id = task_path.split('.', 1)                                                                                                                       
            tracker.complete_task(phase_id, task_id, notes)                                                                                                                   
        else:                                                                                                                                                                 
            print("❌ Task format should be 'phase.task' (e.g., 'phase1_foundation.directory_structure')")                                                                    
                                                                                                                                                                              
    elif args.find:                                                                                                                                                           
        results = tracker.find_task(args.find)                                                                                                                                
        if results:                                                                                                                                                           
            print(f"🔍 Found {len(results)} tasks matching '{args.find}':")                                                                                                   
            print("=" * 40)                                                                                                                                                   
            for phase_id, task_id, task in results:                                                                                                                           
                state = tracker.load_state()                                                                                                                                  
                status = tracker.get_task_status(phase_id, task_id, state)                                                                                                    
                print(f"{status} {task['name']}")                                                                                                                             
                print(f"   ID: {phase_id}.{task_id}")                                                                                                                         
                print(f"   📝 {task['description']}")                                                                                                                         
                print()                                                                                                                                                       
        else:                                                                                                                                                                 
            print(f"❌ No tasks found matching '{args.find}'")                                                                                                                
                                                                                                                                                                              
    elif args.next:                                                                                                                                                           
        tracker.show_next_tasks(args.limit)                                                                                                                                   
                                                                                                                                                                              
    else:                                                                                                                                                                     
        tracker.show_progress(args.detailed)                                                                                                                                  
                                                                                                                                                                              
if __name__ == "__main__":                                                                                                                                                    
    main()                                       

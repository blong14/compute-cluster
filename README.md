```bash
CLI for the compute cluster...

Usage:
  cluster [command]

Available Commands:
  completion   Generate the autocompletion script for the specified shell
  deploy       Deploy a service to the cluster
  help         Help about any command
  memory-store Memory store management commands
  run          Run a job in the cluster
  search       Search documentation using semantic search

Flags:
  -h, --help   help for cluster

Use "cluster [command] --help" for more information about a command.
                                                                                                                                                                              
## Examples                                                                                                                                                                   
                                                                                                                                                                              
Deploy a service to the cluster:                                                                                                                                              
```bash                                                                                                                                                                       
cluster deploy ollama                                                                                                                                                         
```                                                                                                                                                                           
                                                                                                                                                                              
Run a cluster job:                                                                                                                                                            
```bash                                                                                                                                                                       
cluster run ping                                                                                                                                       
```                                                                                                                                                                           
                                                                                                                                                                              
Generate shell completion:                                                                                                                                                    
```bash                                                                                                                                                                       
cluster completion bash > /etc/bash_completion.d/cluster                                                                                                                      
```                                                                                                                                                                           
                                                                                                                                                                              
## Documentation                                                                                                                                                              
                                                                                                                                                                              
Detailed guides are available in the `docs/` directory:                                                                                                                       
                                                                                                                                                                              
- **[Getting Started](docs/GETTING_STARTED.md)** - Initial setup and configuration                                                                                            
- **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** - Service deployment procedures                                                                                            
- **[Ansible AI Integration](docs/ANSIBLE_AI_INTEGRATION_GUIDE.md)** - AI-powered infrastructure automation                                                                   
- **[Aider Terminal Guide](docs/AIDER_TERMINAL_GUIDE.md)** - Using Aider for development                                                                                      
- **[Workflow Examples](docs/WORKFLOW_EXAMPLES.md)** - Practical development workflows                                                                                        
                                                                                                                                                                              
## Development                                                                                                                                                                
                                                                                                                                                                              
Build cluster cli:                                                                                                                                                      
```bash                                                                                                                                                                       
cd src
make build
```                                                                                                                                                                           
                                                                                                                                                                              
Set up Python development environment:                                                                                                                                        
```bash                                                                                                                                                                       
cluster run install                                                                                                                                                           
```    

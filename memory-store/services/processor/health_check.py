#!/usr/bin/env python3
"""
Health check module for document processor service.
Provides health status and metrics for monitoring.
"""

import os
import json
import psycopg2
from typing import Dict, Any
import logging

logger = logging.getLogger(__name__)

class HealthChecker:
    def __init__(self, db_url: str, voyage_api_key: str):
        self.db_url = db_url
        self.voyage_api_key = voyage_api_key
    
    def check_health(self) -> Dict[str, Any]:
        """Comprehensive health check"""
        health_status = {
            "status": "healthy",
            "timestamp": "2026-01-17T14:30:00Z",
            "checks": {
                "database": self._check_database(),
                "voyage_api": self._check_voyage_api(),
                "environment": self._check_environment()
            },
            "metrics": self._get_metrics()
        }
        
        # Determine overall status
        if any(check["status"] != "healthy" for check in health_status["checks"].values()):
            health_status["status"] = "unhealthy"
        
        return health_status
    
    def _check_database(self) -> Dict[str, Any]:
        """Check database connectivity and schema"""
        try:
            conn = psycopg2.connect(self.db_url)
            with conn.cursor() as cur:
                # Check pgvector extension
                cur.execute("SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'vector')")
                pgvector_exists = cur.fetchone()[0]
                
                # Check required tables
                cur.execute("""
                    SELECT table_name FROM information_schema.tables 
                    WHERE table_name IN ('documents', 'document_chunks')
                """)
                tables = [row[0] for row in cur.fetchall()]
                
                # Check document count
                cur.execute("SELECT COUNT(*) FROM documents")
                doc_count = cur.fetchone()[0]
                
                # Check chunk count
                cur.execute("SELECT COUNT(*) FROM document_chunks")
                chunk_count = cur.fetchone()[0]
            
            conn.close()
            
            return {
                "status": "healthy" if pgvector_exists and len(tables) == 2 else "unhealthy",
                "pgvector_enabled": pgvector_exists,
                "tables_present": tables,
                "document_count": doc_count,
                "chunk_count": chunk_count
            }
            
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e)
            }
    
    def _check_voyage_api(self) -> Dict[str, Any]:
        """Check Voyage AI API connectivity"""
        try:
            import requests
            
            if not self.voyage_api_key:
                return {
                    "status": "unhealthy",
                    "error": "VOYAGE_API_KEY not configured"
                }
            
            # Test API with a simple request
            headers = {
                "Authorization": f"Bearer {self.voyage_api_key}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "input": ["test"],
                "model": "voyage-large-2-instruct"
            }
            
            response = requests.post(
                "https://api.voyageai.com/v1/embeddings",
                headers=headers,
                json=payload,
                timeout=10
            )
            
            if response.status_code == 200:
                return {
                    "status": "healthy",
                    "api_accessible": True
                }
            else:
                return {
                    "status": "unhealthy",
                    "error": f"API returned status {response.status_code}"
                }
                
        except Exception as e:
            return {
                "status": "unhealthy",
                "error": str(e)
            }
    
    def _check_environment(self) -> Dict[str, Any]:
        """Check environment configuration"""
        required_vars = ["DATABASE_URL", "VOYAGE_API_KEY", "DOCS_PATH"]
        env_status = {}
        
        for var in required_vars:
            env_status[var] = bool(os.getenv(var))
        
        docs_path = os.getenv("DOCS_PATH", "/app/docs")
        docs_accessible = os.path.exists(docs_path) and os.access(docs_path, os.R_OK)
        
        return {
            "status": "healthy" if all(env_status.values()) and docs_accessible else "unhealthy",
            "environment_variables": env_status,
            "docs_path_accessible": docs_accessible,
            "docs_path": docs_path
        }
    
    def _get_metrics(self) -> Dict[str, Any]:
        """Get processing metrics"""
        try:
            conn = psycopg2.connect(self.db_url)
            with conn.cursor() as cur:
                # Get processing metrics
                cur.execute("""
                    SELECT 
                        COUNT(*) as total_documents,
                        COUNT(CASE WHEN updated_at > created_at THEN 1 END) as updated_documents,
                        MAX(updated_at) as last_update
                    FROM documents
                """)
                doc_metrics = cur.fetchone()
                
                cur.execute("""
                    SELECT 
                        COUNT(*) as total_chunks,
                        AVG(array_length(string_to_array(content, ' '), 1)) as avg_words_per_chunk,
                        MIN(created_at) as first_chunk,
                        MAX(created_at) as last_chunk
                    FROM document_chunks
                """)
                chunk_metrics = cur.fetchone()
            
            conn.close()
            
            return {
                "documents": {
                    "total": doc_metrics[0] if doc_metrics else 0,
                    "updated": doc_metrics[1] if doc_metrics else 0,
                    "last_update": doc_metrics[2].isoformat() if doc_metrics and doc_metrics[2] else None
                },
                "chunks": {
                    "total": chunk_metrics[0] if chunk_metrics else 0,
                    "avg_words": float(chunk_metrics[1]) if chunk_metrics and chunk_metrics[1] else 0,
                    "first_created": chunk_metrics[2].isoformat() if chunk_metrics and chunk_metrics[2] else None,
                    "last_created": chunk_metrics[3].isoformat() if chunk_metrics and chunk_metrics[3] else None
                }
            }
            
        except Exception as e:
            logger.warning(f"Could not retrieve metrics: {e}")
            return {
                "error": str(e)
            }

def main():
    """CLI health check"""
    db_url = os.getenv("DATABASE_URL", "postgresql://memory_user:memory_pass@localhost:5432/memory_store")
    voyage_api_key = os.getenv("VOYAGE_API_KEY")
    
    checker = HealthChecker(db_url, voyage_api_key)
    health = checker.check_health()
    
    print(json.dumps(health, indent=2))
    
    # Exit with error code if unhealthy
    if health["status"] != "healthy":
        exit(1)

if __name__ == "__main__":
    main()

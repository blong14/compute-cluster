import os
import json
from typing import List, Dict, Any, Optional
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
import psycopg2
from psycopg2.extras import RealDictCursor
import requests
from pydantic import BaseModel
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Memory Store Search API", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class SearchResult(BaseModel):
    file_path: str
    title: str
    content: str
    metadata: Dict[str, Any]
    similarity: float

class SearchResponse(BaseModel):
    results: List[SearchResult]
    count: int
    query: str

class SearchAPI:
    def __init__(self):
        self.db_url = os.getenv(
            "DATABASE_URL",
            "postgresql://memory_user:memory_pass@localhost:54321/memory_store",
        )
        self.max_results = int(os.getenv("MAX_RESULTS", "20"))
        self.similarity_threshold = float(os.getenv("SIMILARITY_THRESHOLD", "0.7"))
        
        # Initialize database connection
        self.conn = psycopg2.connect(self.db_url)
        self.conn.autocommit = True
        
        # Verify database
        self._verify_database()
    
    def _verify_database(self):
        """Verify database connection and schema"""
        with self.conn.cursor() as cur:
            # Check pgvector extension
            cur.execute("SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'vector')")
            if not cur.fetchone()[0]:
                logger.warning("pgvector extension not found")
            
            # Check tables
            tables = ['documents', 'document_chunks']
            for table in tables:
                cur.execute("""
                    SELECT EXISTS(
                        SELECT 1 FROM information_schema.tables 
                        WHERE table_name = %s
                    )
                """, (table,))
                if not cur.fetchone()[0]:
                    raise Exception(f"Required table '{table}' not found")
        
        logger.info("Database connection verified")
    
    def generate_embedding(self, text: str) -> List[float]:
        """Generate embedding using Voyage AI API"""
        url = "http://localhost:8001/embeddings"

        payload = {
            "texts": [text],
            "model_name": "all-MiniLM-L6-v2", 
        }
        
        try:
            response = requests.post(url,json=payload, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            if not data.get("embeddings") or len(data["embeddings"]) == 0:
                raise Exception("No embeddings returned from API")
            
            return data["embeddings"][0]
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error callingAPI: {e}")
            raise HTTPException(status_code=500, detail="Failed to generate embedding")
        except Exception as e:
            logger.error(f"Error processing embedding response: {e}")
            raise HTTPException(status_code=500, detail="Failed to process embedding")
    
    def semantic_search(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Perform semantic search using vector similarity"""
        try:
            # Generate query embedding
            query_embedding = self.generate_embedding(query)
            embedding_str = '[' + ','.join(map(str, query_embedding)) + ']'
            
            with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT 
                        d.file_path,
                        d.title,
                        dc.content,
                        dc.metadata,
                        1 - (dc.embedding <=> %s::vector) as similarity
                    FROM document_chunks dc
                    JOIN documents d ON dc.document_id = d.id
                    WHERE 1 - (dc.embedding <=> %s::vector) >= %s
                    ORDER BY dc.embedding <=> %s::vector
                    LIMIT %s
                """, (embedding_str, embedding_str, self.similarity_threshold, embedding_str, limit))
                
                results = cur.fetchall()
                return [dict(row) for row in results]
                
        except Exception as e:
            logger.error(f"Error in semantic search: {e}")
            raise HTTPException(status_code=500, detail="Search failed")
    
    def fulltext_search(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Perform full-text search using PostgreSQL text search"""
        try:
            with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    SELECT 
                        d.file_path,
                        d.title,
                        dc.content,
                        dc.metadata,
                        ts_rank(dc.content_tsvector, plainto_tsquery('english', %s)) as relevance
                    FROM document_chunks dc
                    JOIN documents d ON dc.document_id = d.id
                    WHERE dc.content_tsvector @@ plainto_tsquery('english', %s)
                    ORDER BY relevance DESC
                    LIMIT %s
                """, (query, query, limit))
                
                results = cur.fetchall()
                return [dict(row) for row in results]
                
        except Exception as e:
            logger.error(f"Error in fulltext search: {e}")
            raise HTTPException(status_code=500, detail="Search failed")
    
    def hybrid_search(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Perform hybrid search combining semantic and full-text search"""
        try:
            # Generate query embedding
            query_embedding = self.generate_embedding(query)
            embedding_str = '[' + ','.join(map(str, query_embedding)) + ']'
            
            with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("""
                    WITH semantic_results AS (
                        SELECT 
                            dc.id,
                            d.file_path,
                            d.title,
                            dc.content,
                            dc.metadata,
                            (1 - (dc.embedding <=> %s::vector)) * 0.7 as semantic_score
                        FROM document_chunks dc
                        JOIN documents d ON dc.document_id = d.id
                        ORDER BY dc.embedding <=> %s::vector
                        LIMIT %s
                    ),
                    fulltext_results AS (
                        SELECT 
                            dc.id,
                            d.file_path,
                            d.title,
                            dc.content,
                            dc.metadata,
                            ts_rank(dc.content_tsvector, plainto_tsquery('english', %s)) * 0.3 as fulltext_score
                        FROM document_chunks dc
                        JOIN documents d ON dc.document_id = d.id
                        WHERE dc.content_tsvector @@ plainto_tsquery('english', %s)
                        ORDER BY fulltext_score DESC
                        LIMIT %s
                    )
                    SELECT DISTINCT
                        COALESCE(s.file_path, f.file_path) as file_path,
                        COALESCE(s.title, f.title) as title,
                        COALESCE(s.content, f.content) as content,
                        COALESCE(s.metadata, f.metadata) as metadata,
                        COALESCE(s.semantic_score, 0) + COALESCE(f.fulltext_score, 0) as combined_score
                    FROM semantic_results s
                    FULL OUTER JOIN fulltext_results f ON s.id = f.id
                    ORDER BY combined_score DESC
                    LIMIT %s
                """, (embedding_str, embedding_str, limit, query, query, limit, limit))
                
                results = cur.fetchall()
                return [dict(row) for row in results]
                
        except Exception as e:
            logger.error(f"Error in hybrid search: {e}")
            raise HTTPException(status_code=500, detail="Search failed")


search_api = SearchAPI()


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "memory-store-search-api"}


@app.get("/search/semantic", response_model=SearchResponse)
async def semantic_search_endpoint(
    query: str = Query(..., description="Search query"),
    limit: int = Query(10, ge=1, le=50, description="Maximum number of results")
):
    """Semantic search using vector similarity"""
    results = search_api.semantic_search(query, limit)
    
    return SearchResponse(
        results=[SearchResult(**result) for result in results],
        count=len(results),
        query=query
    )


@app.get("/search/fulltext", response_model=SearchResponse)
async def fulltext_search_endpoint(
    query: str = Query(..., description="Search query"),
    limit: int = Query(10, ge=1, le=50, description="Maximum number of results")
):
    """Full-text search using PostgreSQL text search"""
    results = search_api.fulltext_search(query, limit)
    
    # Convert relevance to similarity for consistent response format
    for result in results:
        result['similarity'] = result.pop('relevance', 0.0)
    
    return SearchResponse(
        results=[SearchResult(**result) for result in results],
        count=len(results),
        query=query
    )


@app.get("/search/hybrid", response_model=SearchResponse)
async def hybrid_search_endpoint(
    query: str = Query(..., description="Search query"),
    limit: int = Query(10, ge=1, le=50, description="Maximum number of results")
):
    """Hybrid search combining semantic and full-text search"""
    results = search_api.hybrid_search(query, limit)
    
    # Convert combined_score to similarity for consistent response format
    for result in results:
        result['similarity'] = result.pop('combined_score', 0.0)
    
    return SearchResponse(
        results=[SearchResult(**result) for result in results],
        count=len(results),
        query=query
    )


@app.get("/stats")
async def get_stats():
    """Get database statistics"""
    try:
        with search_api.conn.cursor(cursor_factory=RealDictCursor) as cur:
            # Get document count
            cur.execute("SELECT COUNT(*) as document_count FROM documents")
            doc_count = cur.fetchone()['document_count']
            
            # Get chunk count
            cur.execute("SELECT COUNT(*) as chunk_count FROM document_chunks")
            chunk_count = cur.fetchone()['chunk_count']
            
            # Get latest update
            cur.execute("SELECT MAX(updated_at) as last_update FROM documents")
            last_update = cur.fetchone()['last_update']
            
            return {
                "documents": doc_count,
                "chunks": chunk_count,
                "last_update": last_update.isoformat() if last_update else None
            }
    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        raise HTTPException(status_code=500, detail="Failed to get statistics")


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("API_PORT", "8000"))
    host = os.getenv("API_HOST", "0.0.0.0")
    
    uvicorn.run(app, host=host, port=port)


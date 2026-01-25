import json
import logging
import os
from typing import List, Dict, Any, Union

import asyncpg
import httpx
from fastapi import FastAPI, HTTPException, Query, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, field_validator
from contextlib import asynccontextmanager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class SearchResult(BaseModel):
    file_path: str
    title: str
    content: str
    metadata: Dict[str, Any]
    similarity: float

    @field_validator('metadata', mode='before')
    @classmethod
    def parse_metadata(cls, v: Union[str, Dict[str, Any], None]) -> Dict[str, Any]:
        """Convert JSON string metadata to dictionary"""
        if v is None:
            return {}
        if isinstance(v, dict):
            return v
        if isinstance(v, str):
            if not v.strip():  # Empty or whitespace-only string
                return {}
            try:
                return json.loads(v)
            except json.JSONDecodeError:
                logger.warning(f"Invalid JSON in metadata field: {v}")
                return {}
        return {}


class SearchResponse(BaseModel):
    results: List[SearchResult]
    count: int
    query: str


class SearchAPI:
    """
    Memory Store Search API for semantic, full-text, and hybrid search operations.
    Now fully async for optimal performance with FastAPI.
    """

    def __init__(self):
        self.db_url = os.getenv(
            "DATABASE_URL",
            "postgresql://memory_user:memory_pass@localhost:54321/memory_store",
        )
        self.max_results = int(os.getenv("MAX_RESULTS", "20"))
        self.similarity_threshold = float(os.getenv("SIMILARITY_THRESHOLD", "0.7"))
        self.pool = None
        self.http_client = None
    
    async def initialize(self):
        """Initialize async resources"""
        # Create database connection pool
        self.pool = await asyncpg.create_pool(
            self.db_url,
            min_size=2,
            max_size=10,
            command_timeout=30
        )
        
        # Create HTTP client for embeddings
        self.http_client = httpx.AsyncClient(timeout=30.0)
        
        # Verify database
        await self._verify_database()
    
    async def close(self):
        """Clean up async resources"""
        if self.pool:
            await self.pool.close()
        if self.http_client:
            await self.http_client.aclose()
    
    async def _verify_database(self):
        """Verify database connection and schema"""
        async with self.pool.acquire() as conn:
            # Check pgvector extension
            result = await conn.fetchval("SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'vector')")
            if not result:
                logger.warning("pgvector extension not found")
            
            # Check tables
            tables = ['documents', 'document_chunks']
            for table in tables:
                exists = await conn.fetchval("""
                    SELECT EXISTS(
                        SELECT 1 FROM information_schema.tables 
                        WHERE table_name = $1
                    )
                """, table)
                if not exists:
                    raise Exception(f"Required table '{table}' not found")
        
        logger.info("Database connection verified")
    
    async def generate_embedding(self, text: str) -> List[float]:
        """Generate embedding using embedding service API"""
        url = "http://localhost:8001/embeddings"

        payload = {
            "texts": [text],
            "model_name": "all-MiniLM-L6-v2", 
        }
        
        try:
            response = await self.http_client.post(url, json=payload)
            response.raise_for_status()
            
            data = response.json()
            if not data.get("embeddings") or len(data["embeddings"]) == 0:
                raise Exception("No embeddings returned from API")
            
            return data["embeddings"][0]
            
        except httpx.RequestError as e:
            logger.error(f"Error calling API: {e}")
            raise HTTPException(status_code=500, detail="Failed to generate embedding")
        except Exception as e:
            logger.error(f"Error processing embedding response: {e}")
            raise HTTPException(status_code=500, detail="Failed to process embedding")
    
    async def semantic_search(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Perform semantic search using vector similarity"""
        try:
            # Generate query embedding
            query_embedding = await self.generate_embedding(query)
            embedding_str = '[' + ','.join(map(str, query_embedding)) + ']'        
            
            async with self.pool.acquire() as conn:
                rows = await conn.fetch("""
                    SELECT 
                        d.file_path,
                        d.title,
                        dc.content,
                        dc.metadata,
                        1 - (dc.embedding <=> $1::vector) as similarity
                    FROM document_chunks dc
                    JOIN documents d ON dc.document_id = d.id
                    WHERE 1 - (dc.embedding <=> $1::vector) >= $2
                    ORDER BY dc.embedding <=> $1::vector
                    LIMIT $3
                """, embedding_str, self.similarity_threshold, limit)
                
                return [dict(row) for row in rows]
                
        except Exception as e:
            logger.error(f"Error in semantic search: {e}")
            raise HTTPException(status_code=500, detail="Search failed")
    
    async def fulltext_search(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Perform full-text search using PostgreSQL text search"""
        try:
            async with self.pool.acquire() as conn:
                rows = await conn.fetch("""
                    SELECT 
                        d.file_path,
                        d.title,
                        dc.content,
                        dc.metadata,
                        ts_rank(dc.content_tsvector, plainto_tsquery('english', $1)) as relevance
                    FROM document_chunks dc
                    JOIN documents d ON dc.document_id = d.id
                    WHERE dc.content_tsvector @@ plainto_tsquery('english', $1)
                    ORDER BY relevance DESC
                    LIMIT $2
                """, query, limit)
                
                return [dict(row) for row in rows]
                
        except Exception as e:
            logger.error(f"Error in fulltext search: {e}")
            raise HTTPException(status_code=500, detail="Search failed")
    
    async def hybrid_search(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Perform hybrid search combining semantic and full-text search"""
        try:
            # Generate query embedding
            query_embedding = await self.generate_embedding(query)
            embedding_str = '[' + ','.join(map(str, query_embedding)) + ']'        
            
            async with self.pool.acquire() as conn:
                rows = await conn.fetch("""
                    WITH semantic_results AS (
                        SELECT 
                            dc.id,
                            d.file_path,
                            d.title,
                            dc.content,
                            dc.metadata,
                            (1 - (dc.embedding <=> $1::vector)) * 0.7 as semantic_score
                        FROM document_chunks dc
                        JOIN documents d ON dc.document_id = d.id
                        ORDER BY dc.embedding <=> $1::vector
                        LIMIT $2
                    ),
                    fulltext_results AS (
                        SELECT 
                            dc.id,
                            d.file_path,
                            d.title,
                            dc.content,
                            dc.metadata,
                            ts_rank(dc.content_tsvector, plainto_tsquery('english', $3)) * 0.3 as fulltext_score
                        FROM document_chunks dc
                        JOIN documents d ON dc.document_id = d.id
                        WHERE dc.content_tsvector @@ plainto_tsquery('english', $3)
                        ORDER BY fulltext_score DESC
                        LIMIT $2
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
                    LIMIT $2
                """, embedding_str, limit, query)
                
                return [dict(row) for row in rows]
                
        except Exception as e:
            logger.error(f"Error in hybrid search: {e}")
            raise HTTPException(status_code=500, detail="Search failed")


# Global search API instance
search_api = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle"""
    global search_api
    # Startup
    search_api = SearchAPI()
    await search_api.initialize()
    yield
    # Shutdown
    await search_api.close()

app = FastAPI(
    title="Memory Store Search API", 
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_search_api() -> SearchAPI:
    """Dependency to get search API instance"""
    return search_api

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "memory-store-search-api"}


@app.get("/search/semantic", response_model=SearchResponse)
async def semantic_search_endpoint(
    query: str = Query(..., description="Search query"),
    limit: int = Query(10, ge=1, le=50, description="Maximum number of results"),
    api: SearchAPI = Depends(get_search_api)
):
    """Semantic search using vector similarity"""
    results = await api.semantic_search(query, limit)
    
    return SearchResponse(
        results=[SearchResult(**result) for result in results],
        count=len(results),
        query=query
    )


@app.get("/search/fulltext", response_model=SearchResponse)
async def fulltext_search_endpoint(
    query: str = Query(..., description="Search query"),
    limit: int = Query(10, ge=1, le=50, description="Maximum number of results"),
    api: SearchAPI = Depends(get_search_api)
):
    """Full-text search using PostgreSQL text search"""
    results = await api.fulltext_search(query, limit)
    
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
    limit: int = Query(10, ge=1, le=50, description="Maximum number of results"),
    api: SearchAPI = Depends(get_search_api)
):
    """Hybrid search combining semantic and full-text search"""
    results = await api.hybrid_search(query, limit)
    print(results)
    
    # Convert combined_score to similarity for consistent response format
    for result in results:
        result['similarity'] = result.pop('combined_score', 0.0)
    
    return SearchResponse(
        results=[SearchResult(**result) for result in results],
        count=len(results),
        query=query
    )


@app.get("/stats")
async def get_stats(api: SearchAPI = Depends(get_search_api)):
    """Get database statistics"""
    try:
        async with api.pool.acquire() as conn:
            # Get document count
            doc_count = await conn.fetchval("SELECT COUNT(*) FROM documents")
            
            # Get chunk count
            chunk_count = await conn.fetchval("SELECT COUNT(*) FROM document_chunks")
            
            # Get latest update
            last_update = await conn.fetchval("SELECT MAX(updated_at) FROM documents")
            
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


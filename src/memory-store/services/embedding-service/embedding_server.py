#!/usr/bin/env python3

import os
import logging
import time
from typing import List 
from contextlib import asynccontextmanager

# import torch
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer


# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global model variable
model = None


class EmbeddingRequest(BaseModel):
    texts: List[str]
    model_name: str = "all-MiniLM-L6-v2"  # Default lightweight model


class EmbeddingResponse(BaseModel):
    embeddings: List[List[float]]
    model_name: str
    dimensions: int
    processing_time: float


class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    model_name: str
    device: str
    dimensions: int


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load model on startup, cleanup on shutdown"""
    global model
    
    # Startup
    model_name = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
    logger.info("Loading embedding model: %s", model_name)
    
    # device = "cuda" if torch.cuda.is_available() else "cpu"
    device = "cpu"
    logger.info("Using device: %s", device)
        
    model = SentenceTransformer(model_name, device=device)
    logger.info(
        "Model loaded successfully. Dimensions: %s",
        model.get_sentence_embedding_dimension()
    )
    
    yield
    
    # Shutdown
    logger.info("Shutting down embedding service")


app = FastAPI(
    title="Self-Hosted Embedding Service",
    description="Generate text embeddings using sentence-transformers",
    version="0.1.0",
    lifespan=lifespan
)


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    global model
    
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    return HealthResponse(
        status="healthy",
        model_loaded=True,
        model_name=model._modules['0'].auto_model.config.name_or_path,
        device=str(model.device),
        dimensions=model.get_sentence_embedding_dimension()
    )


@app.post("/embeddings", response_model=EmbeddingResponse)
async def generate_embeddings(request: EmbeddingRequest):
    """Generate embeddings for input texts"""
    global model
    
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    if not request.texts:
        raise HTTPException(status_code=400, detail="No texts provided")
    
    if len(request.texts) > 100:
        raise HTTPException(status_code=400, detail="Too many texts (max 100)")
    
    try:
        start_time = time.time()
        
        # Generate embeddings
        embeddings = model.encode(
            request.texts,
            convert_to_numpy=True,
            normalize_embeddings=True  # Normalize for cosine similarity
        )
        
        processing_time = time.time() - start_time
        
        # Convert to list of lists for JSON serialization
        embeddings_list = embeddings.tolist()
        
        logger.info(f"Generated embeddings for {len(request.texts)} texts in {processing_time:.3f}s")
        
        return EmbeddingResponse(
            embeddings=embeddings_list,
            model_name=model._modules['0'].auto_model.config.name_or_path,
            dimensions=len(embeddings_list[0]),
            processing_time=processing_time
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate embeddings: {str(e)}")


@app.get("/models")
async def list_available_models():
    """List popular embedding models"""
    return {
        "available_models": {
            "all-MiniLM-L6-v2": {
                "description": "Lightweight, fast, good quality (384 dimensions)",
                "size": "~90MB",
                "performance": "Fast"
            },
            "all-mpnet-base-v2": {
                "description": "High quality, slower (768 dimensions)",
                "size": "~420MB", 
                "performance": "Best quality"
            },
            "all-MiniLM-L12-v2": {
                "description": "Balance of speed and quality (384 dimensions)",
                "size": "~120MB",
                "performance": "Good balance"
            },
            "paraphrase-multilingual-MiniLM-L12-v2": {
                "description": "Multilingual support (384 dimensions)",
                "size": "~120MB",
                "performance": "Multilingual"
            }
        },
        "current_model": model._modules['0'].auto_model.config.name_or_path if model else None
    }


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8001))
    host = os.getenv("HOST", "0.0.0.0")
    
    uvicorn.run(
        "embedding_server:app",
        host=host,
        port=port,
        reload=True,
        log_level="info"
    )


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
    embedding vector(384), 
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

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at trigger to documents table
CREATE TRIGGER update_documents_updated_at
    BEFORE UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for performance optimization
CREATE INDEX idx_documents_created_at ON documents (created_at);
CREATE INDEX idx_documents_updated_at ON documents (updated_at);
CREATE INDEX idx_document_chunks_created_at ON document_chunks (created_at);
CREATE INDEX idx_document_chunks_chunk_index ON document_chunks (document_id, chunk_index);

-- Create a view for easy document search with chunk count
CREATE VIEW document_search_view AS
SELECT 
    d.id,
    d.file_path,
    d.title,
    d.content,
    d.metadata,
    d.created_at,
    d.updated_at,
    COUNT(dc.id) as chunk_count
FROM documents d
LEFT JOIN document_chunks dc ON d.id = dc.document_id
GROUP BY d.id, d.file_path, d.title, d.content, d.metadata, d.created_at, d.updated_at;

-- Create function for semantic search with similarity threshold
CREATE OR REPLACE FUNCTION semantic_search(
    query_embedding vector(384),
    similarity_threshold float DEFAULT 0.7,
    result_limit int DEFAULT 10
)
RETURNS TABLE (
    chunk_id int,
    document_id int,
    file_path text,
    title text,
    content text,
    similarity float,
    metadata jsonb
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dc.id as chunk_id,
        dc.document_id,
        d.file_path,
        d.title,
        dc.content,
        (1 - (dc.embedding <=> query_embedding)) as similarity,
        dc.metadata
    FROM document_chunks dc
    JOIN documents d ON dc.document_id = d.id
    WHERE (1 - (dc.embedding <=> query_embedding)) >= similarity_threshold
    ORDER BY dc.embedding <=> query_embedding
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql;

-- Create function for hybrid search combining semantic and full-text
CREATE OR REPLACE FUNCTION hybrid_search(
    query_text text,
    query_embedding vector(384),
    semantic_weight float DEFAULT 0.7,
    fulltext_weight float DEFAULT 0.3,
    result_limit int DEFAULT 10
)
RETURNS TABLE (
    chunk_id int,
    document_id int,
    file_path text,
    title text,
    content text,
    combined_score float,
    semantic_score float,
    fulltext_score float,
    metadata jsonb
) AS $$
BEGIN
    RETURN QUERY
    WITH semantic_results AS (
        SELECT 
            dc.id as chunk_id,
            dc.document_id,
            d.file_path,
            d.title,
            dc.content,
            (1 - (dc.embedding <=> query_embedding)) * semantic_weight as semantic_score,
            dc.metadata
        FROM document_chunks dc
        JOIN documents d ON dc.document_id = d.id
        ORDER BY dc.embedding <=> query_embedding
        LIMIT result_limit * 2
    ),
    fulltext_results AS (
        SELECT 
            dc.id as chunk_id,
            dc.document_id,
            d.file_path,
            d.title,
            dc.content,
            ts_rank(dc.content_tsvector, plainto_tsquery('english', query_text)) * fulltext_weight as fulltext_score,
            dc.metadata
        FROM document_chunks dc
        JOIN documents d ON dc.document_id = d.id
        WHERE dc.content_tsvector @@ plainto_tsquery('english', query_text)
        ORDER BY fulltext_score DESC
        LIMIT result_limit * 2
    )
    SELECT DISTINCT
        COALESCE(s.chunk_id, f.chunk_id) as chunk_id,
        COALESCE(s.document_id, f.document_id) as document_id,
        COALESCE(s.file_path, f.file_path) as file_path,
        COALESCE(s.title, f.title) as title,
        COALESCE(s.content, f.content) as content,
        COALESCE(s.semantic_score, 0) + COALESCE(f.fulltext_score, 0) as combined_score,
        COALESCE(s.semantic_score, 0) as semantic_score,
        COALESCE(f.fulltext_score, 0) as fulltext_score,
        COALESCE(s.metadata, f.metadata) as metadata
    FROM semantic_results s
    FULL OUTER JOIN fulltext_results f ON s.chunk_id = f.chunk_id
    ORDER BY combined_score DESC
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql;

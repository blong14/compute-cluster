import os
import json
import time
import hashlib
from pathlib import Path
from typing import List, Dict, Any, Optional
import psycopg2
from psycopg2.extras import RealDictCursor
import requests
import markdown
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DocumentProcessor:
    def __init__(self, db_url: str, voyage_api_key: str, docs_path: str):
        self.db_url = db_url
        self.voyage_api_key = voyage_api_key
        self.docs_path = Path(docs_path)
        self.voyage_model = os.getenv("VOYAGE_MODEL", "voyage-large-2-instruct")
        self.chunk_size = int(os.getenv("CHUNK_SIZE", "512"))
        self.chunk_overlap = int(os.getenv("CHUNK_OVERLAP", "50"))
        self.batch_size = int(os.getenv("BATCH_SIZE", "10"))
        
        # Initialize database connection
        self.conn = psycopg2.connect(db_url)
        self.conn.autocommit = True
        
        # Verify pgvector extension
        self._verify_database()
    
    def _verify_database(self):
        """Verify database schema and pgvector extension"""
        with self.conn.cursor() as cur:
            # Check pgvector extension
            cur.execute("SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'vector')")
            if not cur.fetchone()[0]:
                logger.warning("pgvector extension not found. Make sure it's installed.")
            
            # Check required tables
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
        
        logger.info("Database schema verified successfully")
    
    def generate_embedding(self, text: str) -> List[float]:
        """Generate embedding using Voyage AI API"""
        url = "https://api.voyageai.com/v1/embeddings"
        headers = {
            "Authorization": f"Bearer {self.voyage_api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "input": [text],
            "model": self.voyage_model
        }
        
        try:
            response = requests.post(url, headers=headers, json=payload, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            if not data.get("data") or len(data["data"]) == 0:
                raise Exception("No embeddings returned from API")
            
            return data["data"][0]["embedding"]
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error calling Voyage AI API: {e}")
            raise
        except Exception as e:
            logger.error(f"Error processing embedding response: {e}")
            raise
    
    def chunk_markdown(self, content: str, file_path: str) -> List[Dict[str, Any]]:
        """Intelligently chunk markdown content"""
        # Parse markdown to extract structure
        md = markdown.Markdown(extensions=['meta', 'toc'])
        html = md.convert(content)
        
        # Split by double newlines (paragraphs) and headers
        sections = []
        current_section = []
        current_size = 0
        
        lines = content.split('\n')
        current_header = ""
        
        for line in lines:
            line_stripped = line.strip()
            
            # Check if this is a header
            if line_stripped.startswith('#'):
                # If we have accumulated content, save it as a section
                if current_section and current_size > 0:
                    sections.append({
                        'content': '\n'.join(current_section),
                        'header': current_header,
                        'size': current_size
                    })
                
                # Start new section
                current_header = line_stripped
                current_section = [line]
                current_size = len(line)
            else:
                current_section.append(line)
                current_size += len(line) + 1  # +1 for newline
                
                # If section is getting too large, split it
                if current_size > self.chunk_size:
                    sections.append({
                        'content': '\n'.join(current_section),
                        'header': current_header,
                        'size': current_size
                    })
                    
                    # Start overlap for next chunk
                    overlap_lines = current_section[-self.chunk_overlap:] if len(current_section) > self.chunk_overlap else current_section
                    current_section = overlap_lines
                    current_size = sum(len(l) + 1 for l in overlap_lines)
        
        # Add final section
        if current_section and current_size > 0:
            sections.append({
                'content': '\n'.join(current_section),
                'header': current_header,
                'size': current_size
            })
        
        # Convert to chunks with metadata
        chunks = []
        for i, section in enumerate(sections):
            chunks.append({
                'content': section['content'].strip(),
                'metadata': {
                    'file_path': str(file_path),
                    'chunk_index': i,
                    'header': section['header'],
                    'size': section['size'],
                    'total_chunks': len(sections)
                }
            })
        
        return chunks
    
    def get_file_hash(self, file_path: Path) -> str:
        """Get MD5 hash of file content"""
        with open(file_path, 'rb') as f:
            return hashlib.md5(f.read()).hexdigest()
    
    def is_file_processed(self, file_path: Path) -> bool:
        """Check if file has been processed and is up to date"""
        current_hash = self.get_file_hash(file_path)
        
        with self.conn.cursor() as cur:
            cur.execute("""
                SELECT metadata->>'file_hash' as file_hash
                FROM documents 
                WHERE file_path = %s
            """, (str(file_path),))
            
            result = cur.fetchone()
            if result and result[0] == current_hash:
                return True
        
        return False
    
    def process_document(self, file_path: Path) -> bool:
        """Process a single markdown document"""
        try:
            # Check if file needs processing
            if self.is_file_processed(file_path):
                logger.info(f"File {file_path} is up to date, skipping")
                return True
            
            logger.info(f"Processing document: {file_path}")
            
            # Read file content
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if not content.strip():
                logger.warning(f"Empty file: {file_path}")
                return False
            
            # Extract title from first header or filename
            title = self._extract_title(content, file_path)
            
            # Create file metadata
            file_hash = self.get_file_hash(file_path)
            metadata = {
                'file_hash': file_hash,
                'file_size': file_path.stat().st_size,
                'last_modified': file_path.stat().st_mtime,
                'processed_at': time.time()
            }
            
            # Insert/update document
            with self.conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO documents (file_path, title, content, metadata)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (file_path) DO UPDATE SET
                        title = EXCLUDED.title,
                        content = EXCLUDED.content,
                        metadata = EXCLUDED.metadata,
                        updated_at = CURRENT_TIMESTAMP
                    RETURNING id
                """, (str(file_path), title, content, json.dumps(metadata)))
                
                document_id = cur.fetchone()[0]
            
            # Delete existing chunks for this document
            with self.conn.cursor() as cur:
                cur.execute("DELETE FROM document_chunks WHERE document_id = %s", (document_id,))
            
            # Chunk the content
            chunks = self.chunk_markdown(content, file_path)
            logger.info(f"Created {len(chunks)} chunks for {file_path}")
            
            # Process chunks in batches
            for i in range(0, len(chunks), self.batch_size):
                batch = chunks[i:i + self.batch_size]
                self._process_chunk_batch(document_id, batch)
            
            logger.info(f"Successfully processed {file_path}")
            return True
            
        except Exception as e:
            logger.error(f"Error processing {file_path}: {e}")
            return False
    
    def _extract_title(self, content: str, file_path: Path) -> str:
        """Extract title from content or filename"""
        lines = content.split('\n')
        for line in lines:
            line = line.strip()
            if line.startswith('# '):
                return line[2:].strip()
        
        # Fallback to filename
        return file_path.stem.replace('_', ' ').replace('-', ' ').title()
    
    def _process_chunk_batch(self, document_id: int, chunks: List[Dict[str, Any]]):
        """Process a batch of chunks"""
        for chunk in chunks:
            try:
                # Generate embedding
                embedding = self.generate_embedding(chunk['content'])
                
                # Convert embedding to pgvector format
                embedding_str = '[' + ','.join(map(str, embedding)) + ']'
                
                # Insert chunk
                with self.conn.cursor() as cur:
                    cur.execute("""
                        INSERT INTO document_chunks 
                        (document_id, chunk_index, content, embedding, metadata)
                        VALUES (%s, %s, %s, %s::vector, %s)
                    """, (
                        document_id,
                        chunk['metadata']['chunk_index'],
                        chunk['content'],
                        embedding_str,
                        json.dumps(chunk['metadata'])
                    ))
                
                # Small delay to respect API rate limits
                time.sleep(0.1)
                
            except Exception as e:
                logger.error(f"Error processing chunk {chunk['metadata']['chunk_index']}: {e}")
                raise
    
    def process_all_documents(self):
        """Process all markdown documents in the docs directory"""
        if not self.docs_path.exists():
            logger.error(f"Docs path does not exist: {self.docs_path}")
            return
        
        markdown_files = list(self.docs_path.rglob("*.md"))
        logger.info(f"Found {len(markdown_files)} markdown files")
        
        processed = 0
        failed = 0
        
        for file_path in markdown_files:
            if self.process_document(file_path):
                processed += 1
            else:
                failed += 1
        
        logger.info(f"Processing complete: {processed} processed, {failed} failed")
    
    def search_similar(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Search for similar documents using vector similarity"""
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
                    ORDER BY dc.embedding <=> %s::vector
                    LIMIT %s
                """, (embedding_str, embedding_str, limit))
                
                results = cur.fetchall()
                return [dict(row) for row in results]
                
        except Exception as e:
            logger.error(f"Error searching documents: {e}")
            return []

class DocumentWatcher(FileSystemEventHandler):
    """File system event handler for monitoring document changes"""
    
    def __init__(self, processor: DocumentProcessor):
        self.processor = processor
        super().__init__()
    
    def on_modified(self, event):
        if not event.is_directory and event.src_path.endswith('.md'):
            logger.info(f"Document modified: {event.src_path}")
            self.processor.process_document(Path(event.src_path))
    
    def on_created(self, event):
        if not event.is_directory and event.src_path.endswith('.md'):
            logger.info(f"Document created: {event.src_path}")
            self.processor.process_document(Path(event.src_path))

def main():
    # Get configuration from environment
    db_url = os.getenv("DATABASE_URL", "postgresql://memory_user:memory_pass@localhost:5432/memory_store")
    voyage_api_key = os.getenv("VOYAGE_API_KEY")
    docs_path = os.getenv("DOCS_PATH", "/app/docs")
    
    if not voyage_api_key:
        logger.error("VOYAGE_API_KEY environment variable is required")
        return
    
    # Initialize processor
    processor = DocumentProcessor(db_url, voyage_api_key, docs_path)
    
    # Process all documents initially
    processor.process_all_documents()
    
    # Set up file monitoring
    event_handler = DocumentWatcher(processor)
    observer = Observer()
    observer.schedule(event_handler, docs_path, recursive=True)
    observer.start()
    
    logger.info(f"Monitoring {docs_path} for changes...")
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
        logger.info("Stopping document processor...")
    
    observer.join()

if __name__ == "__main__":
    main()

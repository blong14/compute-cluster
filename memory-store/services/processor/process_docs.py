#!/usr/bin/env python3
"""
Document processing script for memory store.
Can be run standalone or as part of the document processor service.
"""

import os
import sys
import argparse
from pathlib import Path
from document_processor import DocumentProcessor
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    parser = argparse.ArgumentParser(description="Process documents for memory store")
    parser.add_argument("--docs-path", default=os.getenv("DOCS_PATH", "/app/docs"),
                       help="Path to documents directory")
    parser.add_argument("--file", help="Process a specific file")
    parser.add_argument("--search", help="Search for similar documents")
    parser.add_argument("--limit", type=int, default=10, help="Limit search results")
    
    args = parser.parse_args()
    
    # Get configuration
    db_url = os.getenv("DATABASE_URL", "postgresql://memory_user:memory_pass@localhost:5432/memory_store")
    voyage_api_key = os.getenv("VOYAGE_API_KEY")
    
    if not voyage_api_key:
        logger.error("VOYAGE_API_KEY environment variable is required")
        sys.exit(1)
    
    # Initialize processor
    try:
        processor = DocumentProcessor(db_url, voyage_api_key, args.docs_path)
    except Exception as e:
        logger.error(f"Failed to initialize processor: {e}")
        sys.exit(1)
    
    if args.search:
        # Search mode
        logger.info(f"Searching for: {args.search}")
        results = processor.search_similar(args.search, args.limit)
        
        if not results:
            print("No results found.")
            return
        
        print(f"\nFound {len(results)} results:")
        print("=" * 50)
        
        for i, result in enumerate(results, 1):
            print(f"\n{i}. {result['title']} (similarity: {result['similarity']:.3f})")
            print(f"   File: {result['file_path']}")
            print(f"   Content: {result['content'][:200]}...")
            if len(result['content']) > 200:
                print("   [truncated]")
    
    elif args.file:
        # Process specific file
        file_path = Path(args.file)
        if not file_path.exists():
            logger.error(f"File not found: {file_path}")
            sys.exit(1)
        
        logger.info(f"Processing file: {file_path}")
        success = processor.process_document(file_path)
        
        if success:
            print(f"Successfully processed: {file_path}")
        else:
            print(f"Failed to process: {file_path}")
            sys.exit(1)
    
    else:
        # Process all documents
        logger.info(f"Processing all documents in: {args.docs_path}")
        processor.process_all_documents()
        print("Document processing complete.")

if __name__ == "__main__":
    main()

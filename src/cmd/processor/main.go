package main

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	_ "github.com/lib/pq"
)

// Document represents a document to be processed
type Document struct {
	ID       string    `json:"id" db:"id"`
	Content  string    `json:"content" db:"content"`
	Title    string    `json:"title" db:"title"`
	Metadata string    `json:"metadata" db:"metadata"`
	Created  time.Time `json:"created" db:"created_at"`
}

// DocumentChunk represents a chunk of a document with metadata
type DocumentChunk struct {
	Content  string                 `json:"content"`
	Metadata map[string]interface{} `json:"metadata"`
}

// VoyageAIRequest represents the request structure for Voyage AI API
type VoyageAIRequest struct {
	Input []string `json:"input"`
	Model string   `json:"model"`
}

// VoyageAIResponse represents the response structure from Voyage AI API
type VoyageAIResponse struct {
	Data []struct {
		Embedding []float64 `json:"embedding"`
		Index     int       `json:"index"`
	} `json:"data"`
	Model string `json:"model"`
	Usage struct {
		TotalTokens int `json:"total_tokens"`
	} `json:"usage"`
}

// ProcessorService handles document processing and embedding generation
type ProcessorService struct {
	db           *sql.DB
	voyageAPIKey string
	voyageModel  string
}

// NewProcessorService creates a new processor service
func NewProcessorService(db *sql.DB, voyageAPIKey, voyageModel string) *ProcessorService {
	return &ProcessorService{
		db:           db,
		voyageAPIKey: voyageAPIKey,
		voyageModel:  voyageModel,
	}
}

// ProcessDocument processes a document and generates embeddings
func (ps *ProcessorService) ProcessDocument(ctx context.Context, doc Document) error {
	// Insert document and get ID
	var documentID int
	query := `
		INSERT INTO documents (file_path, content, title, metadata, created_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (file_path) DO UPDATE SET
			content = EXCLUDED.content,
			title = EXCLUDED.title,
			metadata = EXCLUDED.metadata,
			updated_at = CURRENT_TIMESTAMP
		RETURNING id
	`
	err := ps.db.QueryRowContext(ctx, query, doc.ID, doc.Content, doc.Title, doc.Metadata, doc.Created).Scan(&documentID)
	if err != nil {
		return fmt.Errorf("failed to insert document: %w", err)
	}

	// Chunk the document content
	chunks := ps.chunkContent(doc.Content, doc.ID)
	
	// Process each chunk
	for i, chunk := range chunks {
		embedding, err := ps.generateEmbedding(ctx, chunk.Content)
		if err != nil {
			return fmt.Errorf("failed to generate embedding for chunk %d: %w", i, err)
		}
		
		err = ps.insertDocumentChunk(ctx, documentID, i, chunk.Content, embedding, chunk.Metadata)
		if err != nil {
			return fmt.Errorf("failed to insert chunk %d: %w", i, err)
		}
	}
	
	return nil
}

func (ps *ProcessorService) insertDocument(ctx context.Context, doc Document) error {
	query := `
		INSERT INTO documents (file_path, content, title, metadata, created_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (file_path) DO UPDATE SET
			content = EXCLUDED.content,
			title = EXCLUDED.title,
			metadata = EXCLUDED.metadata,
			updated_at = CURRENT_TIMESTAMP
		RETURNING id
	`
	var documentID int
	err := ps.db.QueryRowContext(ctx, query, doc.ID, doc.Content, doc.Title, doc.Metadata, doc.Created).Scan(&documentID)
	return err
}

func (ps *ProcessorService) insertDocumentChunk(ctx context.Context, documentID int, chunkIndex int, content string, embedding []float64, metadata map[string]interface{}) error {
	metadataJSON, err := json.Marshal(metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}
	
	// Convert embedding slice to pgvector format
	embeddingStr := fmt.Sprintf("[%s]", strings.Join(func() []string {
		strs := make([]string, len(embedding))
		for i, v := range embedding {
			strs[i] = fmt.Sprintf("%f", v)
		}
		return strs
	}(), ","))
	
	query := `
		INSERT INTO document_chunks (document_id, chunk_index, content, embedding, metadata)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (document_id, chunk_index) DO UPDATE SET
			content = EXCLUDED.content,
			embedding = EXCLUDED.embedding,
			metadata = EXCLUDED.metadata
	`
	_, err = ps.db.ExecContext(ctx, query, documentID, chunkIndex, content, embeddingStr, metadataJSON)
	return err
}

func (ps *ProcessorService) generateEmbedding(ctx context.Context, text string) ([]float64, error) {
	reqBody := VoyageAIRequest{
		Input: []string{text},
		Model: ps.voyageModel,
	}
	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}
	
	req, err := http.NewRequestWithContext(ctx, "POST", "https://api.voyageai.com/v1/embeddings", bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+ps.voyageAPIKey)
	
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API request failed with status %d: %s", resp.StatusCode, string(body))
	}

	var voyageResp VoyageAIResponse
	err = json.Unmarshal(body, &voyageResp)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal response: %w", err)
	}
	if len(voyageResp.Data) == 0 {
		return nil, fmt.Errorf("no embeddings returned from API")
	}

	return voyageResp.Data[0].Embedding, nil
}

// chunkContent splits document content into manageable chunks
func (ps *ProcessorService) chunkContent(content string, filePath string) []DocumentChunk {
	// Simple chunking strategy - split by paragraphs and combine to target size
	const targetChunkSize = 512
	const overlapSize = 50
	
	paragraphs := strings.Split(content, "\n\n")
	var chunks []DocumentChunk
	var currentChunk strings.Builder
	var currentSize int
	
	for i, paragraph := range paragraphs {
		paragraph = strings.TrimSpace(paragraph)
		if paragraph == "" {
			continue
		}
		
		paragraphSize := len(paragraph)
		
		// If adding this paragraph would exceed target size, finalize current chunk
		if currentSize > 0 && currentSize+paragraphSize > targetChunkSize {
			chunks = append(chunks, DocumentChunk{
				Content: currentChunk.String(),
				Metadata: map[string]interface{}{
					"file_path":    filePath,
					"chunk_index":  len(chunks),
					"paragraph_start": i - strings.Count(currentChunk.String(), "\n\n"),
					"paragraph_end":   i - 1,
				},
			})
			
			// Start new chunk with overlap from previous chunk
			currentChunk.Reset()
			currentSize = 0
			
			// Add overlap from end of previous chunk if it exists
			if len(chunks) > 0 {
				prevContent := chunks[len(chunks)-1].Content
				words := strings.Fields(prevContent)
				if len(words) > overlapSize {
					overlapWords := words[len(words)-overlapSize:]
					currentChunk.WriteString(strings.Join(overlapWords, " "))
					currentChunk.WriteString("\n\n")
					currentSize = len(currentChunk.String())
				}
			}
		}
		
		if currentSize > 0 {
			currentChunk.WriteString("\n\n")
		}
		currentChunk.WriteString(paragraph)
		currentSize = currentChunk.Len()
	}
	
	// Add final chunk if there's content
	if currentSize > 0 {
		chunks = append(chunks, DocumentChunk{
			Content: currentChunk.String(),
			Metadata: map[string]interface{}{
				"file_path":   filePath,
				"chunk_index": len(chunks),
				"is_final":    true,
			},
		})
	}
	
	// If no chunks were created, create one with the full content
	if len(chunks) == 0 {
		chunks = append(chunks, DocumentChunk{
			Content: content,
			Metadata: map[string]interface{}{
				"file_path":   filePath,
				"chunk_index": 0,
				"full_document": true,
			},
		})
	}
	
	return chunks
}

func (ps *ProcessorService) initDatabase(ctx context.Context) error {
	// Check if pgvector extension exists
	var exists bool
	err := ps.db.QueryRowContext(ctx, "SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'vector')").Scan(&exists)
	if err != nil {
		return fmt.Errorf("failed to check pgvector extension: %w", err)
	}
	if !exists {
		log.Println("Warning: pgvector extension not found. Make sure it's installed and enabled.")
	}
	
	// The tables should already be created by init.sql, just verify they exist
	tables := []string{"documents", "document_chunks"}
	for _, table := range tables {
		var tableExists bool
		err := ps.db.QueryRowContext(ctx, 
			"SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = $1)", 
			table).Scan(&tableExists)
		if err != nil {
			return fmt.Errorf("failed to check table %s: %w", table, err)
		}
		if !tableExists {
			return fmt.Errorf("required table %s does not exist", table)
		}
	}
	
	log.Println("Database schema verified successfully")
	return nil
}

// SearchSimilarDocuments searches for similar documents using pgvector cosine similarity
func (ps *ProcessorService) SearchSimilarDocuments(ctx context.Context, queryText string, limit int) ([]Document, error) {
	queryEmbedding, err := ps.generateEmbedding(ctx, queryText)
	if err != nil {
		return nil, fmt.Errorf("failed to generate query embedding: %w", err)
	}
	
	// Convert embedding to pgvector format
	embeddingStr := fmt.Sprintf("[%s]", strings.Join(func() []string {
		strs := make([]string, len(queryEmbedding))
		for i, v := range queryEmbedding {
			strs[i] = fmt.Sprintf("%f", v)
		}
		return strs
	}(), ","))
	
	// Use pgvector cosine similarity search
	query := `
		SELECT 
			d.file_path,
			d.content,
			d.title,
			d.metadata,
			d.created_at,
			1 - (dc.embedding <=> $1::vector) as similarity
		FROM document_chunks dc
		JOIN documents d ON dc.document_id = d.id
		ORDER BY dc.embedding <=> $1::vector
		LIMIT $2
	`

	rows, err := ps.db.QueryContext(ctx, query, embeddingStr, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query similar documents: %w", err)
	}
	defer rows.Close()

	var documents []Document
	for rows.Next() {
		var doc Document
		var similarity float64
		err := rows.Scan(&doc.ID, &doc.Content, &doc.Title, &doc.Metadata, &doc.Created, &similarity)
		if err != nil {
			return nil, fmt.Errorf("failed to scan document: %w", err)
		}
		documents = append(documents, doc)
	}
	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating over rows: %w", err)
	}
	
	return documents, nil
}

// HTTP handlers
func (ps *ProcessorService) handleProcessDocument(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	var doc Document
	err := json.NewDecoder(r.Body).Decode(&doc)
	if err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}
	if doc.ID == "" {
		doc.ID = fmt.Sprintf("doc_%d.md", time.Now().UnixNano())
	}
	if doc.Created.IsZero() {
		doc.Created = time.Now()
	}
	ctx := r.Context()
	err = ps.ProcessDocument(ctx, doc)
	if err != nil {
		log.Printf("Error processing document: %v", err)
		http.Error(w, "Failed to process document", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":      "success",
		"document_id": doc.ID,
	})
}

func (ps *ProcessorService) handleSearchDocuments(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
	query := r.URL.Query().Get("q")
	if query == "" {
		http.Error(w, "Query parameter 'q' is required", http.StatusBadRequest)
		return
	}
	limit := 10 // default limit
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if parsedLimit, err := strconv.Atoi(limitStr); err == nil && parsedLimit > 0 && parsedLimit <= 100 {
			limit = parsedLimit
		}
	}
	ctx := r.Context()
	documents, err := ps.SearchSimilarDocuments(ctx, query, limit)
	if err != nil {
		log.Printf("Error searching documents: %v", err)
		http.Error(w, "Failed to search documents", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"documents": documents,
		"count":     len(documents),
	})
}


func main() {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://user:password@localhost/memorystore?sslmode=disable"
	}

	voyageAPIKey := os.Getenv("VOYAGE_API_KEY")
	if voyageAPIKey == "" {
		log.Fatal("VOYAGE_API_KEY environment variable is required")
	}

	voyageModel := os.Getenv("VOYAGE_MODEL")
	if voyageModel == "" {
		voyageModel = "voyage-large-2" // default model
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	ctx := context.Background()
	err = db.PingContext(ctx)
	if err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	processor := NewProcessorService(db, voyageAPIKey, voyageModel)
	err = processor.initDatabase(ctx)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	http.HandleFunc("/process", processor.handleProcessDocument)
	http.HandleFunc("/search", processor.handleSearchDocuments)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
	})

	log.Printf("Starting document processor service on port %s", port)
	
	server := &http.Server{
		Addr:         ":" + port,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	log.Fatal(server.ListenAndServe())
}

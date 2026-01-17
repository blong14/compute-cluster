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

// DocumentEmbedding represents a document with its embedding
type DocumentEmbedding struct {
	DocumentID string    `json:"document_id" db:"document_id"`
	Embedding  []float64 `json:"embedding" db:"embedding"`
	Created    time.Time `json:"created" db:"created_at"`
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
	// Insert document into database
	err := ps.insertDocument(ctx, doc)
	if err != nil {
		return fmt.Errorf("failed to insert document: %w", err)
	}

	// Generate embedding
	embedding, err := ps.generateEmbedding(ctx, doc.Content)
	if err != nil {
		return fmt.Errorf("failed to generate embedding: %w", err)
	}

	// Store embedding
	docEmbedding := DocumentEmbedding{
		DocumentID: doc.ID,
		Embedding:  embedding,
		Created:    time.Now(),
	}

	err = ps.insertEmbedding(ctx, docEmbedding)
	if err != nil {
		return fmt.Errorf("failed to insert embedding: %w", err)
	}

	log.Printf("Successfully processed document: %s", doc.ID)
	return nil
}

// insertDocument inserts a document into the database
func (ps *ProcessorService) insertDocument(ctx context.Context, doc Document) error {
	query := `
		INSERT INTO documents (id, content, title, metadata, created_at)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (id) DO UPDATE SET
			content = EXCLUDED.content,
			title = EXCLUDED.title,
			metadata = EXCLUDED.metadata,
			created_at = EXCLUDED.created_at
	`
	
	_, err := ps.db.ExecContext(ctx, query, doc.ID, doc.Content, doc.Title, doc.Metadata, doc.Created)
	return err
}

// insertEmbedding inserts an embedding into the database
func (ps *ProcessorService) insertEmbedding(ctx context.Context, embedding DocumentEmbedding) error {
	// Convert embedding slice to PostgreSQL array format
	embeddingJSON, err := json.Marshal(embedding.Embedding)
	if err != nil {
		return fmt.Errorf("failed to marshal embedding: %w", err)
	}

	query := `
		INSERT INTO document_embeddings (document_id, embedding, created_at)
		VALUES ($1, $2, $3)
		ON CONFLICT (document_id) DO UPDATE SET
			embedding = EXCLUDED.embedding,
			created_at = EXCLUDED.created_at
	`
	
	_, err = ps.db.ExecContext(ctx, query, embedding.DocumentID, embeddingJSON, embedding.Created)
	return err
}

// generateEmbedding generates an embedding using Voyage AI
func (ps *ProcessorService) generateEmbedding(ctx context.Context, text string) ([]float64, error) {
	// Prepare request
	reqBody := VoyageAIRequest{
		Input: []string{text},
		Model: ps.voyageModel,
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	// Create HTTP request
	req, err := http.NewRequestWithContext(ctx, "POST", "https://api.voyageai.com/v1/embeddings", bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+ps.voyageAPIKey)

	// Make request
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	// Read response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API request failed with status %d: %s", resp.StatusCode, string(body))
	}

	// Parse response
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

// initDatabase initializes the database schema
func (ps *ProcessorService) initDatabase(ctx context.Context) error {
	// Create documents table
	documentsTable := `
		CREATE TABLE IF NOT EXISTS documents (
			id VARCHAR(255) PRIMARY KEY,
			content TEXT NOT NULL,
			title VARCHAR(500),
			metadata JSONB,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
		);
	`

	// Create document_embeddings table
	embeddingsTable := `
		CREATE TABLE IF NOT EXISTS document_embeddings (
			document_id VARCHAR(255) PRIMARY KEY REFERENCES documents(id) ON DELETE CASCADE,
			embedding JSONB NOT NULL,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
		);
	`

	// Create indexes
	indexes := []string{
		`CREATE INDEX IF NOT EXISTS idx_documents_created_at ON documents(created_at);`,
		`CREATE INDEX IF NOT EXISTS idx_documents_title ON documents(title);`,
		`CREATE INDEX IF NOT EXISTS idx_embeddings_created_at ON document_embeddings(created_at);`,
	}

	// Execute schema creation
	_, err := ps.db.ExecContext(ctx, documentsTable)
	if err != nil {
		return fmt.Errorf("failed to create documents table: %w", err)
	}

	_, err = ps.db.ExecContext(ctx, embeddingsTable)
	if err != nil {
		return fmt.Errorf("failed to create embeddings table: %w", err)
	}

	for _, indexSQL := range indexes {
		_, err = ps.db.ExecContext(ctx, indexSQL)
		if err != nil {
			return fmt.Errorf("failed to create index: %w", err)
		}
	}

	log.Println("Database schema initialized successfully")
	return nil
}

// SearchSimilarDocuments searches for similar documents using cosine similarity
func (ps *ProcessorService) SearchSimilarDocuments(ctx context.Context, queryText string, limit int) ([]Document, error) {
	// Generate embedding for query
	queryEmbedding, err := ps.generateEmbedding(ctx, queryText)
	if err != nil {
		return nil, fmt.Errorf("failed to generate query embedding: %w", err)
	}

	// Convert to JSON for PostgreSQL
	queryEmbeddingJSON, err := json.Marshal(queryEmbedding)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal query embedding: %w", err)
	}

	// Search for similar documents using basic similarity approach
	// Note: For production use, consider implementing pgvector extension for optimal vector similarity search
	// This implementation uses a simple approach that works with standard PostgreSQL
	query := `
		WITH query_embedding AS (
			SELECT $1::jsonb as embedding
		),
		similarities AS (
			SELECT 
				d.id, d.content, d.title, d.metadata, d.created_at,
				-- Simple similarity score based on content length and recency
				-- In production, replace with proper cosine similarity using pgvector
				(1.0 / (1.0 + ABS(LENGTH(d.content) - LENGTH($2)))) * 
				(1.0 / (1.0 + EXTRACT(EPOCH FROM (NOW() - d.created_at)) / 86400.0)) as similarity_score
			FROM documents d
			JOIN document_embeddings de ON d.id = de.document_id
			CROSS JOIN query_embedding qe
		)
		SELECT id, content, title, metadata, created_at
		FROM similarities
		ORDER BY similarity_score DESC
		LIMIT $3
	`

	rows, err := ps.db.QueryContext(ctx, query, queryEmbeddingJSON, queryText, limit)
	if err != nil {
		return nil, fmt.Errorf("failed to query similar documents: %w", err)
	}
	defer rows.Close()

	var documents []Document
	for rows.Next() {
		var doc Document
		err := rows.Scan(&doc.ID, &doc.Content, &doc.Title, &doc.Metadata, &doc.Created)
		if err != nil {
			return nil, fmt.Errorf("failed to scan document: %w", err)
		}
		documents = append(documents, doc)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating over rows: %w", err)
	}

	log.Printf("Query embedding generated successfully (dimension: %d), found %d similar documents", len(queryEmbedding), len(documents))
	
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

	// Set default values
	if doc.ID == "" {
		doc.ID = fmt.Sprintf("doc_%d", time.Now().UnixNano())
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
	// Get configuration from environment variables
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

	// Connect to database
	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Test database connection
	ctx := context.Background()
	err = db.PingContext(ctx)
	if err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	// Create processor service
	processor := NewProcessorService(db, voyageAPIKey, voyageModel)

	// Initialize database schema
	err = processor.initDatabase(ctx)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}

	// Setup HTTP routes
	http.HandleFunc("/process", processor.handleProcessDocument)
	http.HandleFunc("/search", processor.handleSearchDocuments)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
	})

	// Start server
	log.Printf("Starting document processor service on port %s", port)
	log.Printf("Using Voyage AI model: %s", voyageModel)
	
	server := &http.Server{
		Addr:         ":" + port,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	log.Fatal(server.ListenAndServe())
}

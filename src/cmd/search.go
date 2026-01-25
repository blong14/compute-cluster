package cmd

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"

	"github.com/spf13/cobra"
	"k8s.io/klog/v2"
)

type SearchResult struct {
	Content    string                 `json:"content"`
	FilePath   string                 `json:"file_path"`
	Title      string                 `json:"title"`
	Metadata   map[string]interface{} `json:"metadata"`
	Similarity float64                `json:"similarity,omitempty"`
	Score      float64                `json:"score,omitempty"`
}

type SearchResponse struct {
	Results []SearchResult `json:"results"`
}

var (
	searchLimit  int
	searchHybrid bool
	memoryStoreURL = "http://localhost:8000"
)

var searchCmd = &cobra.Command{
	Use:   "search [query]",
	Short: "Search documentation using semantic search",
	Long: `Search through your documentation using semantic search powered by AI embeddings.
	
Examples:
  cluster search "ansible integration"
  cluster search "security best practices" --limit 10
  cluster search "workflow examples" --hybrid`,
	Args: cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		query := args[0]
		results, err := performSearch(query, searchHybrid, searchLimit)
		if err != nil {
			klog.Errorf("Search failed: %v", err)
			return
		}
		displayResults(results)
	},
}

var memoryStoreCmd = &cobra.Command{
	Use:   "memory-store",
	Short: "Memory store management commands",
	Long:  "Commands for managing the documentation memory store system",
}

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show memory store status",
	Run: func(cmd *cobra.Command, args []string) {
		status, err := getMemoryStoreStatus()
		if err != nil {
			klog.Errorf("Failed to get status: %v", err)
			return
		}
		fmt.Println(status)
	},
}

var healthCmd = &cobra.Command{
	Use:   "health",
	Short: "Check memory store health",
	Run: func(cmd *cobra.Command, args []string) {
		healthy, err := checkMemoryStoreHealth()
		if err != nil {
			klog.Errorf("Health check failed: %v", err)
			return
		}
		if healthy {
			fmt.Println("✅ Memory store is healthy")
		} else {
			fmt.Println("❌ Memory store is unhealthy")
		}
	},
}

func init() {
	rootCmd.AddCommand(searchCmd)
	rootCmd.AddCommand(memoryStoreCmd)
	
	memoryStoreCmd.AddCommand(statusCmd)
	memoryStoreCmd.AddCommand(healthCmd)
	
	searchCmd.Flags().IntVarP(&searchLimit, "limit", "l", 5, "Maximum number of results to return")
	searchCmd.Flags().BoolVar(&searchHybrid, "hybrid", false, "Use hybrid search (semantic + full-text)")
}

func performSearch(query string, hybrid bool, limit int) ([]SearchResult, error) {
	endpoint := "/search/semantic"
	if hybrid {
		endpoint = "/search/hybrid"
	}
	
	// Build URL with query parameters
	searchURL := fmt.Sprintf("%s%s", memoryStoreURL, endpoint)
	params := url.Values{}
	params.Add("query", query)
	params.Add("limit", strconv.Itoa(limit))
	
	fullURL := fmt.Sprintf("%s?%s", searchURL, params.Encode())
	
	klog.V(2).Infof("Searching: %s", fullURL)
	
	resp, err := http.Get(fullURL)
	if err != nil {
		return nil, fmt.Errorf("failed to make search request: %w", err)
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("search request failed with status %d: %s", resp.StatusCode, string(body))
	}
	
	var searchResponse SearchResponse
	if err := json.NewDecoder(resp.Body).Decode(&searchResponse); err != nil {
		return nil, fmt.Errorf("failed to decode search response: %w", err)
	}
	
	return searchResponse.Results, nil
}

func displayResults(results []SearchResult) {
	if len(results) == 0 {
		fmt.Println("No results found.")
		return
	}
	
	fmt.Printf("Found %d results:\n\n", len(results))
	
	for i, result := range results {
		fmt.Printf("📄 Result %d\n", i+1)
		fmt.Printf("   File: %s\n", result.FilePath)
		if result.Title != "" {
			fmt.Printf("   Title: %s\n", result.Title)
		}
		
		// Show similarity or score
		if result.Similarity > 0 {
			fmt.Printf("   Similarity: %.2f\n", result.Similarity)
		} else if result.Score > 0 {
			fmt.Printf("   Score: %.2f\n", result.Score)
		}
		
		// Show content preview (first 200 chars)
		content := result.Content
		if len(content) > 200 {
			content = content[:200] + "..."
		}
		fmt.Printf("   Content: %s\n", content)
		fmt.Println()
	}
}

func getMemoryStoreStatus() (string, error) {
	resp, err := http.Get(fmt.Sprintf("%s/stats", memoryStoreURL))
	if err != nil {
		return "", fmt.Errorf("failed to get status: %w", err)
	}
	defer resp.Body.Close()
	
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read status response: %w", err)
	}
	
	return string(body), nil
}

func checkMemoryStoreHealth() (bool, error) {
	resp, err := http.Get(fmt.Sprintf("%s/health", memoryStoreURL))
	if err != nil {
		return false, fmt.Errorf("failed to check health: %w", err)
	}
	defer resp.Body.Close()
	
	return resp.StatusCode == http.StatusOK, nil
}

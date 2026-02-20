package cmd

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/spf13/cobra"
	"k8s.io/klog/v2"
)

var (
	aiQuery  string
	aiLimit  int
	aiModel  string
	aiConfig string
)

var aiCmd = &cobra.Command{
	Use:   "ai [message]",
	Short: "Run aider with knowledge base context",
	Long: `Run aider with relevant context from the knowledge base.
	
Examples:
  cluster ai "help me implement kubernetes deployment"
  cluster ai --query "helm charts" "create memory store chart"
  cluster ai --config memory-store.yml "update search API"`,
	Args: cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		message := strings.Join(args, " ")
		
		// Use query if provided, otherwise use the message
		query := aiQuery
		if query == "" {
			query = message
		}
		
		// Search knowledge base for context
		klog.V(2).Infof("Searching knowledge base for: %s", query)
		results, err := performSearch(query, true, aiLimit) // Use hybrid search
		if err != nil {
			klog.Warningf("Knowledge base search failed: %v", err)
			// Continue without context
		}
		
		// Prepare context from search results
		contextFiles := []string{}
		if len(results) > 0 {
			contextFile, err := createContextFile(results, query)
			if err != nil {
				klog.Warningf("Failed to create context file: %v", err)
			} else {
				contextFiles = append(contextFiles, contextFile)
				defer os.Remove(contextFile) // Clean up
			}
		}
		
		// Launch aider with context and message
		if err := runAiderWithContext(message, contextFiles); err != nil {
			klog.Errorf("Failed to run aider: %v", err)
		}
	},
}

func init() {
	rootCmd.AddCommand(aiCmd)
	
	aiCmd.Flags().StringVarP(&aiQuery, "query", "q", "", "Specific query for knowledge base (defaults to message)")
	aiCmd.Flags().IntVarP(&aiLimit, "limit", "l", 5, "Maximum number of context results")
	aiCmd.Flags().StringVarP(&aiModel, "model", "m", "", "AI model to use with aider")
	aiCmd.Flags().StringVarP(&aiConfig, "config", "c", "", "Aider config file to use")
}

func createContextFile(results []SearchResult, query string) (string, error) {
	tmpFile, err := ioutil.TempFile("", "cluster-ai-context-*.md")
	if err != nil {
		return "", fmt.Errorf("failed to create temp file: %w", err)
	}
	defer tmpFile.Close()
	
	// Enhanced header with metadata
	fmt.Fprintf(tmpFile, "# Knowledge Base Context\n\n")
	fmt.Fprintf(tmpFile, "**Query**: \"%s\"\n", query)
	fmt.Fprintf(tmpFile, "**Results Found**: %d\n", len(results))
	fmt.Fprintf(tmpFile, "**Generated**: %s\n\n", time.Now().Format("2006-01-02 15:04:05"))
	
	// Add search strategy note
	fmt.Fprintf(tmpFile, "**Search Strategy**: This context was retrieved using hybrid search (semantic + full-text) to find the most relevant information for your request.\n\n")
	fmt.Fprintf(tmpFile, "---\n\n")
	fmt.Fprintf(tmpFile, "## Context Sources\n\n")
	
	// Process each result with better formatting
	for i, result := range results {
		// Determine relevance level
		relevanceScore := result.Score
		if relevanceScore == 0 {
			relevanceScore = result.Similarity
		}
		
		relevanceLevel := "Low"
		if relevanceScore > 0.7 {
			relevanceLevel = "High"
		} else if relevanceScore > 0.3 {
			relevanceLevel = "Medium"
		}
		
		// Extract section from content if possible
		section := extractSection(result.Content)
		
		fmt.Fprintf(tmpFile, "### %d. %s\n", i+1, result.Title)
		fmt.Fprintf(tmpFile, "- **File**: `%s`\n", result.FilePath)
		fmt.Fprintf(tmpFile, "- **Relevance**: %.2f (%s)\n", relevanceScore, relevanceLevel)
		if section != "" {
			fmt.Fprintf(tmpFile, "- **Section**: %s\n", section)
		}
		fmt.Fprintf(tmpFile, "\n")
		
		// Format content with proper code block handling
		formattedContent := formatContent(result.Content)
		fmt.Fprintf(tmpFile, "**Content:**\n%s\n\n", formattedContent)
		
		// Extract key points
		keyPoints := extractKeyPoints(result.Content)
		if len(keyPoints) > 0 {
			fmt.Fprintf(tmpFile, "**Key Points:**\n")
			for _, point := range keyPoints {
				fmt.Fprintf(tmpFile, "- %s\n", point)
			}
			fmt.Fprintf(tmpFile, "\n")
		}
		
		fmt.Fprintf(tmpFile, "---\n\n")
	}
	
	// Enhanced instructions
	fmt.Fprintf(tmpFile, "## Instructions for AI Assistant\n\n")
	fmt.Fprintf(tmpFile, "**Context Usage Guidelines:**\n")
	fmt.Fprintf(tmpFile, "1. **Prioritize High Relevance**: Focus on sources with higher relevance scores\n")
	fmt.Fprintf(tmpFile, "2. **Reference Sources**: When using information, reference the specific file and section\n")
	fmt.Fprintf(tmpFile, "3. **Maintain Patterns**: Follow the established patterns and conventions shown in the context\n")
	fmt.Fprintf(tmpFile, "4. **Code Examples**: Use the code examples as templates for similar implementations\n")
	fmt.Fprintf(tmpFile, "5. **File Structure**: Respect the file organization and naming conventions demonstrated\n\n")
	
	fmt.Fprintf(tmpFile, "**Original Query Context**: \"%s\"\n", query)
	fmt.Fprintf(tmpFile, "Use this context to provide accurate, relevant assistance that aligns with the existing codebase and documentation patterns.\n")
	
	return tmpFile.Name(), nil
}

// Helper functions for enhanced context formatting
func extractSection(content string) string {
	lines := strings.Split(content, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "#") {
			// Remove markdown header symbols and return clean section name
			return strings.TrimSpace(strings.TrimLeft(line, "#"))
		}
	}
	return ""
}

func formatContent(content string) string {
	// Ensure code blocks are properly formatted
	lines := strings.Split(content, "\n")
	var formatted []string
	inCodeBlock := false
	
	for _, line := range lines {
		if strings.HasPrefix(strings.TrimSpace(line), "```") {
			inCodeBlock = !inCodeBlock
		}
		formatted = append(formatted, line)
	}
	
	// If we ended in a code block, close it
	if inCodeBlock {
		formatted = append(formatted, "```")
	}
	
	return strings.Join(formatted, "\n")
}

func extractKeyPoints(content string) []string {
	var points []string
	lines := strings.Split(content, "\n")
	
	for _, line := range lines {
		line = strings.TrimSpace(line)
		// Look for list items, commands, or important statements
		if strings.HasPrefix(line, "-") || strings.HasPrefix(line, "*") {
			point := strings.TrimSpace(strings.TrimLeft(line, "-*"))
			if len(point) > 10 && len(point) < 100 { // Reasonable length
				points = append(points, point)
			}
		} else if strings.Contains(line, "cluster ") && len(line) < 80 {
			// Extract command examples
			points = append(points, line)
		}
	}
	
	// Limit to most relevant points
	if len(points) > 5 {
		points = points[:5]
	}
	
	return points
}

func runAiderWithContext(message string, contextFiles []string) error {
	// Build aider command
	args := []string{}
	
	// Add config if specified
	if aiConfig != "" {
		args = append(args, "--config", aiConfig)
	}
	
	// Add model if specified
	if aiModel != "" {
		args = append(args, "--model", aiModel)
	}
	
	// Add context files
	for _, contextFile := range contextFiles {
		args = append(args, "--read", contextFile)
	}
	
	// Add message
	args = append(args, "--message", message)
	
	klog.V(2).Infof("Running aider with args: %v", args)
	
	// Execute aider
	cmd := exec.Command("aider", args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	
	return cmd.Run()
}

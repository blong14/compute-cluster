package cmd

import (
	"github.com/spf13/cobra"

	"cluster/pkg/tools/database"
)

var proxyDB = &cobra.Command{
	Use: "proxydb",
	Short: "create proxy from localhost to cluster database",
	Run: database.ProxyDB,
}

var clientDB = &cobra.Command{
	Use: "connect",
	Short: "create sql connection to cluster database",
	Run: database.Connect,
}

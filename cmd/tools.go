package cmd

import (
	"github.com/spf13/cobra"

	"cluster/pkg/tools/database"
)

var proxyDB = &cobra.Command{
	Use: "proxydb",
	Run: database.ProxyDB,
}

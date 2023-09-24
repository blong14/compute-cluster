package cmd

import (
	"cluster/pkg/network"
	"cluster/pkg/tools"
	"cluster/pkg/tools/database"
	"github.com/spf13/cobra"
)

var hostname string

var proxy = &cobra.Command{
	Use:   "proxy",
	Short: "Create proxy from localhost to cluster",
	Run:   tools.Proxy,
}

var clientDB = &cobra.Command{
	Use:   "connect",
	Short: "Create sql connection to cluster database",
	Run:   database.Connect,
}

var nsLookUp = &cobra.Command{
	Use:   "nslookup",
	Short: "Query internet server names",
	Run:   network.NsLookUp,
}

var ping = &cobra.Command{
	Use:   "ping",
	Short: "Ping the cluster",
	Run:   network.Ping,
}

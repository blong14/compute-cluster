package cmd

import (
	"github.com/spf13/cobra"

	"cluster/pkg/jobs/beam"
)

var initDBCmd = &cobra.Command{
	Use:   "initdb",
	Short: "Initialize a cockroachdb cluster",
	Run:   beam.InitDB,
}

var pingDBCmd = &cobra.Command{
	Use:   "pingdb",
	Short: "Ping a cockroachdb cluster",
	Args:  cobra.MinimumNArgs(1),
	Run:   beam.PingDB,
}

var (
	pingHost string
	pingPort int
	pingUser string

	connectDB string

	proxyResource string
	proxyPort string
)

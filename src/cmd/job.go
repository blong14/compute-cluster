package cmd

import (
	"github.com/spf13/cobra"

	"cluster/pkg/jobs/beam"
)

var pingDBCmd = &cobra.Command{
	Use:   "pingdb",
	Short: "Ping a cockroachdb cluster",
	Args:  cobra.MinimumNArgs(1),
	Run:   beam.PingDB,
}

var ridesScanCmd = &cobra.Command{
	Use:   "ridesscan",
	Short: "Scan the movr.rides table",
	Args:  cobra.MinimumNArgs(1),
	Run:   beam.Rides,
}

var (
	host     string
	port     int
	user     string
	password string
	runner   string
	flinkDSN string

	connectDB string

	proxyResource string
	proxyPort     string
)

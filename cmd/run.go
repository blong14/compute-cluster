package cmd

import "github.com/spf13/cobra"

var runCmd = &cobra.Command{
	Use:   "run",
	Short: "Run a job in the cluster",
}

func init() {
	runCmd.PersistentFlags().StringVarP(&flinkDSN, "flink-dsn", "f", "localhost", "flink dsn")
	runCmd.PersistentFlags().StringVarP(&runner, "runner", "", "direct", "apache beam runner")

	pingDBCmd.Flags().StringVar(&host, "host", "127.0.0.1", "db host")
	pingDBCmd.Flags().IntVarP(&port, "port", "p", 9000, "db port")
	pingDBCmd.Flags().StringVarP(&user, "user", "u", "admin", "db user")

	ridesScanCmd.Flags().StringVar(&host, "host", "127.0.0.1", "db host")
	ridesScanCmd.Flags().IntVarP(&port, "port", "p", 9000, "db port")
	ridesScanCmd.Flags().StringVarP(&user, "user", "u", "admin", "db user")

	clientDB.Flags().StringVarP(&connectDB, "database", "d", "postgres", "database")

	proxy.Flags().StringVarP(&proxyResource, "resource", "r", "svc/cockroachdb-public", "proxy cluster resource")
	proxy.Flags().StringVarP(&proxyPort, "port", "p", "8080", "port to proxy cluster")

	rootCmd.AddCommand(runCmd)
	runCmd.AddCommand(pingDBCmd, proxy, clientDB, ridesScanCmd)
}

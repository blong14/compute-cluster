package cmd

import "github.com/spf13/cobra"

var runCmd = &cobra.Command{
	Use:   "run",
	Short: "Run a job in the cluster",
}

func init() {
	pingDBCmd.Flags().StringVar(&pingHost, "host", "127.0.0.1", "db host")
	pingDBCmd.Flags().IntVarP(&pingPort, "port", "p", 9000, "db port")
	pingDBCmd.Flags().StringVarP(&pingUser, "user", "u", "admin", "db user")

	clientDB.Flags().StringVarP(&connectDB, "database", "d", "postgres", "database")

	rootCmd.AddCommand(runCmd)
	runCmd.AddCommand(initDBCmd, pingDBCmd, proxyDB, clientDB)
}

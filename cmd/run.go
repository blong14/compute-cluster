package cmd

import "github.com/spf13/cobra"

var runCmd = &cobra.Command{
	Use:   "run",
	Short: "Run a job in the cluster",
}

func init() {
	rootCmd.AddCommand(runCmd)
	runCmd.AddCommand(initDBCmd)
}

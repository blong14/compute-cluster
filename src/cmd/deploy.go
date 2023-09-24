package cmd

import (
	"cluster/pkg/deploy"
	"github.com/spf13/cobra"
)

var deployCmd = &cobra.Command{
	Use:   "deploy",
	Short: "Deploy a service to the cluster",
}

var scrutiny = &cobra.Command{
	Use:   "scrutiny",
	Short: "Build and Deploy scrutiny",
	Run:   deploy.Scrutiny,
}

var jupyterhub = &cobra.Command{
	Use:   "jupyterhub",
	Short: "Build and Deploy jupyterhub",
	Run:   deploy.Jupyterhub,
}

func init() {
	deployCmd.AddCommand(
		jupyterhub,
		scrutiny,
	)
	rootCmd.AddCommand(deployCmd)
}

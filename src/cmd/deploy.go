package cmd

import (
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"k8s.io/klog/v2"

	"cluster/pkg/deploy"
)

var deployCmd = &cobra.Command{
	Use:   "deploy",
	Short: "Deploy a service to the cluster",
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		viper.SetConfigFile("config.yml") // file name
		if err := viper.ReadInConfig(); err != nil {
			klog.Fatal(err)
		}
	},
}

var scrutiny = &cobra.Command{
	Use:   "scrutiny",
	Short: "Build and Deploy scrutiny",
	Run:   deploy.Scrutiny,
}

func init() {
	deployCmd.AddCommand(scrutiny)
	rootCmd.AddCommand(deployCmd)
}

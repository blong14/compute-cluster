package cmd

import (
	"cluster/pkg/deploy"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"k8s.io/klog/v2"
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

var scrutinyNgxin = &cobra.Command{
	Use:   "scrutiny-nginx",
	Short: "Build and Deploy scrutiny-nginx",
	Run:   deploy.ScrutinyNginx,
}

var scrutinyVarnish = &cobra.Command{
	Use:   "scrutiny-varnish",
	Short: "Build and Deploy scrutiny-varnish",
	Run:   deploy.ScrutinyVarnish,
}

func init() {
	deployCmd.AddCommand(scrutiny)
	deployCmd.AddCommand(scrutinyNgxin)
	deployCmd.AddCommand(scrutinyVarnish)
	rootCmd.AddCommand(deployCmd)
}

package cmd

import (
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"k8s.io/klog/v2"
)

var rootCmd = &cobra.Command{
	Use:   "cluster",
	Short: "CLI for the compute cluster...",
}

func init() {
	viper.SetConfigFile("config.yml")
	if err := viper.ReadInConfig(); err != nil {
		klog.Fatal(err)
	}
	cobra.OnInitialize(func() {
		klog.Info("executing cmd")
	})
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		klog.Fatal(err)
	}
}

package cmd

import (
	"github.com/spf13/cobra"
	"k8s.io/klog/v2"
)

var rootCmd = &cobra.Command{
	Use:   "cluster",
	Short: "CLI for the compute cluster...",
}

func init() {
	cobra.OnInitialize(func() {
		klog.Info("executing cmd")
	})
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		klog.Fatal(err)
	}
}

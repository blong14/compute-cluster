package tools

import (
	"github.com/spf13/cobra"
	"k8s.io/klog/v2"
	"os"
	"os/exec"
)

func Proxy(cmd *cobra.Command, _ []string) {
	c := exec.Command(
		"kubectl",
		"port-forward",
		"--address",
		"0.0.0.0",
		cmd.Flag("resource").Value.String(),
		cmd.Flag("port").Value.String(),
	)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	if err := c.Run(); err != nil {
		klog.Fatal(err)
	}
}

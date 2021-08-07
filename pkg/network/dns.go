package network

import (
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"k8s.io/klog/v2"
)

func NsLookUp(cmd *cobra.Command, _ []string) {
	c := exec.Command(
		"kubectl",
		"exec",
		"-it",
		"dnsutils",
		"--",
		"nslookup",
		cmd.Flag("host").Value.String(),
	)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	if err := c.Run(); err != nil {
		klog.Fatal(err)
	}
}

package database

import (
	"fmt"
	"github.com/spf13/cobra"
	"k8s.io/klog/v2"
	"os"
	"os/exec"
)

func Connect(cmd *cobra.Command, _ []string) {
	// TODO: add more flags to remove the hard coding
	c := exec.Command(
		"kubectl",
		"exec",
		"-it",
		"cockroachdb-client-secure",
		"--",
		"./cockroach",
		"sql",
		"--certs-dir",
		"/cockroach/cockroach-certs",
		"--host=cockroachdb-public",
		fmt.Sprintf("--database=%s", cmd.Flag("database").Value.String()),
	)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	if err := c.Run(); err != nil {
		klog.Fatal(err)
	}
}

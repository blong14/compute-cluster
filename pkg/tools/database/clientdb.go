package database

import (
	"fmt"
	"github.com/spf13/cobra"
	"k8s.io/klog/v2"
	"os"
	"os/exec"
)

func Connect(cmd *cobra.Command, _ []string) {
	c := exec.Command(
		"kubectl",
		"run",
		"--rm",
		"-it",
		"cockroachdb-client",
		"--image=marceloglezer/cockroach:v20.1.7",
		"--overrides={\"apiVersion\":\"v1\",\"spec\":{\"affinity\":{\"nodeAffinity\":{\"requiredDuringSchedulingIgnoredDuringExecution\":{\"nodeSelectorTerms\":[{\"matchFields\":[{\"key\":\"metadata.name\",\"operator\":\"In\",\"values\":[\"worker-01\"]}]}]}}}}}",
		"--command",
		"--",
		"/cockroach/cockroach",
		"sql",
		"--insecure",
		"--host=cockroachdb-1.cockroachdb.default.svc.cluster.local",
		fmt.Sprintf("--database=%s", cmd.Flag("database").Value.String()),
	)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	if err := c.Run(); err != nil {
		klog.Fatal(err)
	}
}

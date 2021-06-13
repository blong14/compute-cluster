package database

import (
	"os/exec"

	"github.com/spf13/cobra"
	"k8s.io/klog/v2"
)

func ProxyDB(_ *cobra.Command, _ []string) {
	cmd := exec.Command("kubectl", "port-forward", "pod/cockroachdb-0", "9000:26257")
	if err := cmd.Run(); err != nil {
		klog.Fatal(err)
	}
}

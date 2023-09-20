package deploy

import (
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"k8s.io/klog/v2"
)

func Scrutiny(cmd *cobra.Command, _ []string) {
	c := exec.Command(
		"ansible-playbook",
		"build/playbooks/scrutiny/build.yml",
		"-e",
		"@build/playbooks/scrutiny/cfg.enc",
		"--ask-vault-pass",
		"-f",
		"1",
		"-u",
		"pi",
		"--become",
		"-K",
		"-vv",
	)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	if err := c.Run(); err != nil {
		klog.Fatal(err)
	}
}

func ScrutinyNginx(cmd *cobra.Command, _ []string) {
	c := exec.Command(
		"ansible-playbook",
		"build/playbooks/scrutiny/build-nginx.yml",
		"-f",
		"1",
		"-u",
		"pi",
		"--become",
		"-K",
		"-vv",
	)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	if err := c.Run(); err != nil {
		klog.Fatal(err)
	}
}

func ScrutinyVarnish(cmd *cobra.Command, _ []string) {
	c := exec.Command(
		"ansible-playbook",
		"build/playbooks/scrutiny/build-varnish.yml",
		"-f",
		"1",
		"-u",
		"pi",
		"--become",
		"-K",
		"-vv",
	)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	if err := c.Run(); err != nil {
		klog.Fatal(err)
	}
}

package deploy

import (
	"fmt"
	"github.com/apenella/go-ansible/pkg/options"
	"github.com/apenella/go-ansible/pkg/playbook"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"k8s.io/klog/v2"
)

type AnsibleOpts struct {
	ConnOpts                *options.AnsibleConnectionOptions
	PrivilegeExcalationOpts *options.AnsiblePrivilegeEscalationOptions
	PlaybookOpts            *playbook.AnsiblePlaybookOptions
}

func NewAnsibleOpts(deployDir string) AnsibleOpts {
	return AnsibleOpts{
		ConnOpts: &options.AnsibleConnectionOptions{
			AskPass: false,
			User:    "pi",
		},
		PrivilegeExcalationOpts: &options.AnsiblePrivilegeEscalationOptions{
			Become:        true,
			AskBecomePass: true,
		},
		PlaybookOpts: &playbook.AnsiblePlaybookOptions{
			Inventory:        fmt.Sprintf("%s/etc/ansible/hosts", deployDir),
			AskVaultPassword: false,
			VerboseVV:        true,
		},
	}
}

func Scrutiny(cmd *cobra.Command, args []string) {
	deployDir := viper.GetString("deploy.ansible-dir")
	opts := NewAnsibleOpts(deployDir)
	opts.PlaybookOpts.AskVaultPassword = true
	opts.PlaybookOpts.ExtraVarsFile = []string{
		fmt.Sprintf("@%s/playbooks/scrutiny/cfg.enc", deployDir),
	}
	pb := &playbook.AnsiblePlaybookCmd{
		Playbooks: []string{
			fmt.Sprintf("%s/playbooks/scrutiny/build.yml", deployDir),
		},
		ConnectionOptions:          opts.ConnOpts,
		Options:                    opts.PlaybookOpts,
		PrivilegeEscalationOptions: opts.PrivilegeExcalationOpts,
	}
	if err := pb.Run(cmd.Context()); err != nil {
		klog.Fatal(err)
	}
}

func ScrutinyNginx(cmd *cobra.Command, _ []string) {
	deployDir := viper.GetString("deploy.ansible-dir")
	opts := NewAnsibleOpts(deployDir)
	pb := &playbook.AnsiblePlaybookCmd{
		Playbooks: []string{
			fmt.Sprintf("%s/playbooks/scrutiny/build-nginx.yml", deployDir),
		},
		ConnectionOptions:          opts.ConnOpts,
		Options:                    opts.PlaybookOpts,
		PrivilegeEscalationOptions: opts.PrivilegeExcalationOpts,
	}
	if err := pb.Run(cmd.Context()); err != nil {
		klog.Fatal(err)
	}
}

func ScrutinyVarnish(cmd *cobra.Command, _ []string) {
	deployDir := viper.GetString("deploy.ansible-dir")
	opts := NewAnsibleOpts(deployDir)
	pb := &playbook.AnsiblePlaybookCmd{
		Playbooks: []string{
			fmt.Sprintf("%s/playbooks/scrutiny/build-varnish.yml", deployDir),
		},
		ConnectionOptions:          opts.ConnOpts,
		Options:                    opts.PlaybookOpts,
		PrivilegeEscalationOptions: opts.PrivilegeExcalationOpts,
	}
	if err := pb.Run(cmd.Context()); err != nil {
		klog.Fatal(err)
	}
}

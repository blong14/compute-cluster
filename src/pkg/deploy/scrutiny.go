package deploy

import (
	"fmt"

	"github.com/apenella/go-ansible/pkg/playbook"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"k8s.io/klog/v2"

	"cluster/pkg/ansible"
)

func Scrutiny(cmd *cobra.Command, _ []string) {
	v := viper.GetViper()
	opts := ansible.NewAnsibleOpts(v)
	play := &playbook.AnsiblePlaybookCmd{
		Playbooks: []string{
			fmt.Sprintf(
				"%s/playbooks/scrutiny/build.yml",
				opts.BuildOpts.BuildDir,
			),
		},
		ConnectionOptions:          opts.ConnOpts,
		Options:                    opts.PlaybookOpts,
		PrivilegeEscalationOptions: opts.PrivilegeExcalationOpts,
	}
	if err := play.Run(cmd.Context()); err != nil {
		klog.Fatal(err)
	}
}

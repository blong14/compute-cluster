package ansible

import (
	"github.com/apenella/go-ansible/pkg/adhoc"
	"github.com/apenella/go-ansible/pkg/options"
	"github.com/apenella/go-ansible/pkg/playbook"
	"github.com/spf13/viper"
)

type BuildOptions struct {
	BuildDir string
}

type AnsibleOpts struct {
	AdhocOpts               *adhoc.AnsibleAdhocOptions
	ConnOpts                *options.AnsibleConnectionOptions
	BuildOpts               *BuildOptions
	PrivilegeExcalationOpts *options.AnsiblePrivilegeEscalationOptions
	PlaybookOpts            *playbook.AnsiblePlaybookOptions
}

func NewAnsibleOpts(v *viper.Viper) AnsibleOpts {
	return AnsibleOpts{
		ConnOpts: &options.AnsibleConnectionOptions{
			AskPass: false,
			User:    v.GetString("deploy.deploy-user"),
		},
		BuildOpts: &BuildOptions{
			BuildDir: v.GetString("deploy.build-dir"),
		},
		PlaybookOpts: &playbook.AnsiblePlaybookOptions{
			Inventory:        v.GetString("deploy.inventory-file"),
			AskVaultPassword: false,
			VerboseVV:        true,
		},
		PrivilegeExcalationOpts: &options.AnsiblePrivilegeEscalationOptions{
			Become:        true,
			AskBecomePass: true,
		},
	}
}

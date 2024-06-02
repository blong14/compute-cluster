package ansible

import (
	"github.com/apenella/go-ansible/v2/pkg/adhoc"
	"github.com/apenella/go-ansible/v2/pkg/playbook"
	"github.com/spf13/viper"
)

type BuildOptions struct {
	BuildDir    string
	PlaybookDir string
}

type PlayOpts struct {
	AdhocOpts    *adhoc.AnsibleAdhocOptions
	BuildOpts    *BuildOptions
	PlaybookOpts *playbook.AnsiblePlaybookOptions
}

func NewAnsibleOpts(v *viper.Viper) PlayOpts {
	return PlayOpts{
		BuildOpts: &BuildOptions{
			BuildDir:    v.GetString("deploy.build-dir"),
			PlaybookDir: v.GetString("deploy.playbook-dir"),
		},
		PlaybookOpts: &playbook.AnsiblePlaybookOptions{
			AskBecomePass:    true,
			AskVaultPassword: false,
			Become:           true,
			Inventory:        v.GetString("deploy.inventory-file"),
			VerboseVV:        true,
			User:             v.GetString("deploy.deploy-user"),
		},
	}
}

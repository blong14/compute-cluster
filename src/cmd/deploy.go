package cmd

import (
	"cluster/internal/ansible"
	"errors"
	"fmt"

	"github.com/apenella/go-ansible/pkg/playbook"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"k8s.io/klog/v2"
)

var deployCmd = &cobra.Command{
	Use:   "deploy",
	Short: "Deploy a service to the cluster",
	Args: func(_ *cobra.Command, args []string) error {
		if len(args) < 1 {
			return errors.New("requires at least one arg")
		}
		return nil
	},
	Run: func(cmd *cobra.Command, args []string) {
		srvc := args[0]
		v := viper.GetViper()
		opts := ansible.NewAnsibleOpts(v)
		switch srvc {
		case "scrutiny":
			opts.PlaybookOpts.AskVaultPassword = true
			opts.PlaybookOpts.ExtraVarsFile = []string{
				fmt.Sprintf(
					"@%s/%s/scrutiny/cfg.enc",
					opts.BuildOpts.BuildDir,
					opts.BuildOpts.PlaybookDir,
				),
			}
		}
		play := &playbook.AnsiblePlaybookCmd{
			Playbooks: []string{
				fmt.Sprintf(
					"%s/%s/%s/build.yml",
					opts.BuildOpts.BuildDir,
					opts.BuildOpts.PlaybookDir,
					srvc,
				),
			},
			ConnectionOptions:          opts.ConnOpts,
			Options:                    opts.PlaybookOpts,
			PrivilegeEscalationOptions: opts.PrivilegeExcalationOpts,
			StdoutCallback:             "yaml",
		}
		if err := play.Run(cmd.Context()); err != nil {
			klog.Fatal(err)
		}
	},
}

func init() {
	rootCmd.AddCommand(deployCmd)
}

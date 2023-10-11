package cmd

import (
	"fmt"

	"github.com/apenella/go-ansible/pkg/adhoc"
	"github.com/apenella/go-ansible/pkg/playbook"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"k8s.io/klog/v2"

	"cluster/internal/ansible"
)

var runCmd = &cobra.Command{
	Use:   "run",
	Short: "Run a job in the cluster",
}

var ping = &cobra.Command{
	Use:   "ping",
	Short: "Ping the cluster",
	Run: func(cmd *cobra.Command, _ []string) {
		v := viper.GetViper()
		opts := ansible.NewAnsibleOpts(v)
		opts.AdhocOpts = &adhoc.AnsibleAdhocOptions{
			Inventory:  opts.PlaybookOpts.Inventory,
			ModuleName: "ansible.builtin.ping",
		}
		play := &adhoc.AnsibleAdhocCmd{
			Pattern:                    "all",
			Options:                    opts.AdhocOpts,
			ConnectionOptions:          opts.ConnOpts,
			PrivilegeEscalationOptions: opts.PrivilegeExcalationOpts,
			StdoutCallback:             "oneline",
		}
		klog.Info(play.String())
		if err := play.Run(cmd.Context()); err != nil {
			klog.Fatal(err)
		}
	},
}

var updateNodeCmd = &cobra.Command{
	Use:   "update-node",
	Short: "Update OS pkgs for each node in the cluster",
	Run: func(cmd *cobra.Command, _ []string) {
		v := viper.GetViper()
		opts := ansible.NewAnsibleOpts(v)
		play := &playbook.AnsiblePlaybookCmd{
			Playbooks: []string{
				fmt.Sprintf(
					"%s/playbooks/node/update.yml",
					opts.BuildOpts.BuildDir,
				),
			},
			ConnectionOptions:          opts.ConnOpts,
			Options:                    opts.PlaybookOpts,
			PrivilegeEscalationOptions: opts.PrivilegeExcalationOpts,
		}
		klog.Info(play.String())
		if err := play.Run(cmd.Context()); err != nil {
			klog.Fatal(err)
		}
	},
}

var releaseUpgrade = &cobra.Command{
	Use:   "release-upgrade",
	Short: "Update OS release for each node in the cluster",
	Run: func(cmd *cobra.Command, _ []string) {
		v := viper.GetViper()
		opts := ansible.NewAnsibleOpts(v)
		play := &playbook.AnsiblePlaybookCmd{
			Playbooks: []string{
				fmt.Sprintf(
					"%s/playbooks/node/upgrade-release.yml",
					opts.BuildOpts.BuildDir,
				),
			},
			ConnectionOptions:          opts.ConnOpts,
			Options:                    opts.PlaybookOpts,
			PrivilegeEscalationOptions: opts.PrivilegeExcalationOpts,
		}
		klog.Info(play.String())
		if err := play.Run(cmd.Context()); err != nil {
			klog.Fatal(err)
		}
	},
}

func init() {
	rootCmd.AddCommand(runCmd)
	runCmd.AddCommand(
		ping,
		releaseUpgrade,
		updateNodeCmd,
	)
}

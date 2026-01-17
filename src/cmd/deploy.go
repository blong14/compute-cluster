package cmd

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/apenella/go-ansible/v2/pkg/execute"
	"github.com/apenella/go-ansible/v2/pkg/playbook"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"k8s.io/klog/v2"

	"cluster/internal/ansible"
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
		venvPath := v.GetString("ansible.venv_path")
		if venvPath != "" {
			venvBin := filepath.Join(venvPath, "bin")
			currentPath := os.Getenv("PATH")
			os.Setenv("PATH", venvBin+":"+currentPath)
		}
		opts := ansible.NewAnsibleOpts(v)
		switch srvc {
		case "collector", "logconsumer", "mercure", "scrutiny":
			opts.PlaybookOpts.AskVaultPassword = true
			opts.PlaybookOpts.ExtraVarsFile = []string{
				fmt.Sprintf(
					"@%s/%s/%s/cfg.enc",
					opts.BuildOpts.BuildDir,
					opts.BuildOpts.PlaybookDir,
					srvc,
				),
			}
		}
		play := playbook.NewAnsiblePlaybookCmd(
			playbook.WithPlaybooks(
				fmt.Sprintf(
					"%s/%s/%s/build.yml",
					opts.BuildOpts.BuildDir,
					opts.BuildOpts.PlaybookDir,
					srvc,
				),
			),
			playbook.WithPlaybookOptions(opts.PlaybookOpts),
		)
		exec := execute.NewDefaultExecute(
			execute.WithCmd(play),
		)
		if err := exec.Execute(cmd.Context()); err != nil {
			klog.Fatal(err)
		}
	},
}

func init() {
	rootCmd.AddCommand(deployCmd)
}

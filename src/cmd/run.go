package cmd

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/apenella/go-ansible/v2/pkg/adhoc"
	"github.com/apenella/go-ansible/v2/pkg/execute"
	"github.com/apenella/go-ansible/v2/pkg/playbook"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"k8s.io/klog/v2"

	cserver "cluster/cmd/collector"
	"cluster/internal/ansible"
)

var runCmd = &cobra.Command{
	Use:   "run",
	Short: "Run a job in the cluster",
}

var collector = &cobra.Command{
	Use:   "collector",
	Short: "Run the collection server",
	Run: func(cmd *cobra.Command, args []string) {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

		ctx, cancel := context.WithCancel(cmd.Context())

		db := cserver.MustConnectDB()
		cserver.MigrateDB(db)

		port := "8080"
		if len(args) == 1 {
			port = args[0]
		}

		srv := cserver.Server(fmt.Sprintf(":%s", port))
		go cserver.Start(srv, cserver.HTTPHandlers(db))

		s := <-sigint
		klog.Infof("received %s signal\n", s)
		cserver.Stop(ctx, srv)
		cancel()
		time.Sleep(500 * time.Millisecond)
	},
}

var ping = &cobra.Command{
	Use:   "ping",
	Short: "Ping the cluster",
	Run: func(cmd *cobra.Command, _ []string) {
		v := viper.GetViper()
		opts := ansible.NewAnsibleOpts(v)
		adhocOpts := &adhoc.AnsibleAdhocOptions{
			AskBecomePass: opts.PlaybookOpts.AskBecomePass,
			Become:        opts.PlaybookOpts.Become,
			Inventory:     opts.PlaybookOpts.Inventory,
			ModuleName:    "ansible.builtin.ping",
			User:          opts.PlaybookOpts.User,
		}
		play := adhoc.NewAnsibleAdhocCmd(
			adhoc.WithAdhocOptions(adhocOpts),
			adhoc.WithPattern("all"),
		)
		exec := execute.NewDefaultExecute(
			execute.WithCmd(play),
		)
		if err := exec.Execute(cmd.Context()); err != nil {
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
		play := playbook.NewAnsiblePlaybookCmd(
			playbook.WithPlaybooks(
				fmt.Sprintf(
					"%s/playbooks/node/update.yml",
					opts.BuildOpts.BuildDir,
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

var releaseUpgrade = &cobra.Command{
	Use:   "release-upgrade",
	Short: "Update OS release for each node in the cluster",
	Run: func(cmd *cobra.Command, _ []string) {
		v := viper.GetViper()
		opts := ansible.NewAnsibleOpts(v)
		play := playbook.NewAnsiblePlaybookCmd(
			playbook.WithPlaybooks(
				fmt.Sprintf(
					"%s/playbooks/node/upgrade-release.yml",
					opts.BuildOpts.BuildDir,
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
	rootCmd.AddCommand(runCmd)
	runCmd.AddCommand(
		collector,
		ping,
		releaseUpgrade,
		updateNodeCmd,
	)
}

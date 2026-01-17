package cmd

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
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
		venvPath := v.GetString("ansible.venv_path")
		if venvPath != "" {
			venvBin := filepath.Join(venvPath, "bin")
			currentPath := os.Getenv("PATH")
			os.Setenv("PATH", venvBin+":"+currentPath)
		}
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
		venvPath := v.GetString("ansible.venv_path")
		if venvPath != "" {
			venvBin := filepath.Join(venvPath, "bin")
			currentPath := os.Getenv("PATH")
			os.Setenv("PATH", venvBin+":"+currentPath)
		}
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
		venvPath := v.GetString("ansible.venv_path")
		if venvPath != "" {
			venvBin := filepath.Join(venvPath, "bin")
			currentPath := os.Getenv("PATH")
			os.Setenv("PATH", venvBin+":"+currentPath)
		}
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

var install = &cobra.Command{
	Use:   "install",
	Short: "Install Python dependencies with virtual environment",
	Run: func(cmd *cobra.Command, args []string) {
		venvPath := "venv"
		pipPath := filepath.Join(venvPath, "bin", "pip")
		if _, err := os.Stat(venvPath); os.IsNotExist(err) {
			klog.Info("Creating virtual environment...")
			createVenv := exec.Command("python3.11", "-m", "venv", venvPath)
			if err := createVenv.Run(); err != nil {
				klog.Fatalf("Failed to create virtual environment: %v", err)
			}
		}
		upgradePip := exec.Command(pipPath, "install", "--upgrade", "pip")
		if err := upgradePip.Run(); err != nil {
			klog.Fatalf("Failed to upgrade pip: %v", err)
		}
		klog.Info("Installing package in editable mode...")
		installCmd := exec.Command(pipPath, "install", "-e", ".")
		if err := installCmd.Run(); err != nil {
			klog.Fatalf("Failed to install package: %v", err)
		}
		klog.Info("Generating requirements.txt...")
		freezeCmd := exec.Command(pipPath, "freeze")
		freezeOutput, err := freezeCmd.Output()
		if err != nil {
			klog.Fatalf("Failed to freeze requirements: %v", err)
		}
		if err := os.WriteFile("requirements.txt", freezeOutput, 0644); err != nil {
			klog.Fatalf("Failed to write requirements.txt: %v", err)
		}
		klog.Info("Installation completed successfully!")
	},
}

func init() {
	rootCmd.AddCommand(runCmd)
	runCmd.AddCommand(
		collector,
		ping,
		install,
		releaseUpgrade,
		updateNodeCmd,
	)
}

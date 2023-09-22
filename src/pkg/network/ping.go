package network

import (
	"github.com/apenella/go-ansible/pkg/adhoc"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"k8s.io/klog/v2"

	"cluster/pkg/ansible"
)

func Ping(cmd *cobra.Command, _ []string) {
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
}

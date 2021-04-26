package cmd

import (
	"github.com/spf13/cobra"

	"cluster/pkg/jobs/beam"
)

var initDBCmd = &cobra.Command{
	Use:   "initdb",
	Short: "Initialize a cockroachdb cluster",
	Run:   beam.InitDB,
}

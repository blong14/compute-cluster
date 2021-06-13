package beam

import (
	"context"
	"fmt"
	"time"

	"github.com/apache/beam/sdks/go/pkg/beam"
	"github.com/apache/beam/sdks/go/pkg/beam/io/textio"
	"github.com/spf13/cobra"
	"k8s.io/klog/v2"

	_ "github.com/apache/beam/sdks/go/pkg/beam/core/runtime/exec/optimized"
	_ "github.com/apache/beam/sdks/go/pkg/beam/io/filesystem/local"
	_ "github.com/apache/beam/sdks/go/pkg/beam/runners/direct"
)

func InitDB(_ *cobra.Command, _ []string) {
	beam.Init()

	ctx := context.Background()

	p := beam.NewPipeline()
	s := p.Root()

	lines := textio.Read(s, "track_points.csv")
	sts := Extract(s, lines)

	if _, err := beam.Run(ctx, "direct", p); err != nil {
		klog.Fatalf("Failed to execute job: %v", err)
	}

	klog.Info(sts)
}

func PingDB(cmd *cobra.Command, args []string) {
	beam.Init()

	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s dbname=%s sslmode=disable",
		cmd.Flag("host").Value.String(),
		cmd.Flag("port").Value.String(),
		cmd.Flag("user").Value.String(),
		args[0],
	)

	p, s := beam.NewPipelineWithRoot()

	Ping(s, dsn)

	ctx, cancel := context.WithTimeout(context.Background(), 9*time.Second)
	defer cancel()

	if _, err := beam.Run(ctx, "direct", p); err != nil {
		klog.Fatal(err)
	}
}

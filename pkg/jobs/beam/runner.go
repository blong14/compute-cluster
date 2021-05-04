package beam

import (
	"context"
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

func PingDB(_ *cobra.Command, _ []string) {
	beam.Init()

	ctx, cancel := context.WithTimeout(context.Background(), 9*time.Second)
	defer cancel()

	p, s := beam.NewPipelineWithRoot()

	sts := Ping(s)

	if _, err := beam.Run(ctx, "direct", p); err != nil {
		klog.Fatal(err)
	}

	klog.Info(sts)
}

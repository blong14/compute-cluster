package beam

import (
	"context"
	"strings"

	"github.com/apache/beam/sdks/go/pkg/beam"
	"github.com/apache/beam/sdks/go/pkg/beam/io/textio"
	"github.com/apache/beam/sdks/go/pkg/beam/transforms/stats"
	"github.com/spf13/cobra"
	"k8s.io/klog/v2"

	_ "github.com/apache/beam/sdks/go/pkg/beam/core/runtime/exec/optimized"
	_ "github.com/apache/beam/sdks/go/pkg/beam/io/filesystem/local"
	_ "github.com/apache/beam/sdks/go/pkg/beam/runners/direct"
)

func init() {
	beam.RegisterFunction(extractFn)
}

func extractFn(ctx context.Context, line string, emit func(string)) {
	for _, word := range strings.Split(line, ",") {
		select {
		case <-ctx.Done():
			return
		default:
		}
		if word == "" {
			continue
		}
		klog.Info(word)
		emit(word)
	}
}

func Extract(s beam.Scope, lines beam.PCollection) beam.PCollection {
	s = s.Scope("extract")

	col := beam.ParDo(s, extractFn, lines)

	return stats.Count(s, col)
}

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

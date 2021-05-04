package beam

import (
	"context"
	"strings"

	"github.com/apache/beam/sdks/go/pkg/beam"
	"github.com/apache/beam/sdks/go/pkg/beam/transforms/stats"
	"k8s.io/klog/v2"
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

package beam

import (
	"github.com/apache/beam/sdks/go/pkg/beam"
	"github.com/apache/beam/sdks/go/pkg/beam/io/textio"
	"k8s.io/klog/v2"
)

func Ping(s beam.Scope) beam.PCollection {
	s.Scope("ping")

	lines := textio.Read(s, "track_points.csv")

	klog.Info("PING")

	return lines
}

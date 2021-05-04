package beam

import (
	"github.com/apache/beam/sdks/go/pkg/beam"
	"testing"
)

func TestPing(t *testing.T) {
	// given
	_, s := beam.NewPipelineWithRoot()

	// when
	actual := Ping(s)

	// then
	if !actual.IsValid() {
		t.Error("ping not valid")
	}
}

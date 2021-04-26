package beam

import (
	"context"
	"testing"
)

func TestExtractFn(t *testing.T) {
	// given
	ctx := context.Background()
	line := "foo,,"

	// when
	extractFn(ctx, line, func(s string) {
		// then
		if s != "foo" {
			t.Errorf("want %s got %s", "foo", s)
		}
	})
}

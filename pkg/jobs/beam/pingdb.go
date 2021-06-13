package beam

import (
	"context"
	"database/sql"
	"reflect"
	"time"

	"github.com/apache/beam/sdks/go/pkg/beam"
	"github.com/apache/beam/sdks/go/pkg/beam/io/databaseio"
	"github.com/apache/beam/sdks/go/pkg/beam/transforms/stats"
	"k8s.io/klog/v2"

	_ "github.com/lib/pq"
)

type result struct {
	Now sql.NullTime `db:"now" json:"now"`
}

func init() {
	beam.RegisterFunction(nowFn)
}

func nowFn(ctx context.Context, r result, emit func(time.Time)) {
	select {
	case <-ctx.Done():
		return
	default:
		if r.Now.Valid {
			klog.Info(r.Now.Time)
			emit(r.Now.Time)
		}
	}

}

func Ping(s beam.Scope, dsn string) beam.PCollection {
	s.Scope("ping")

	result := databaseio.Query(
		s,
		"postgres",
		dsn,
		"select now() as now;",
		reflect.TypeOf(result{}),
	)

	return stats.Count(s, beam.ParDo(s, nowFn, result))
}

package beam

import (
	"context"
	"database/sql"
	"flag"
	"fmt"
	"reflect"
	"time"

	"github.com/apache/beam/sdks/go/pkg/beam"
	"github.com/apache/beam/sdks/go/pkg/beam/io/databaseio"
	"github.com/apache/beam/sdks/go/pkg/beam/transforms/stats"
	"github.com/spf13/cobra"
	"k8s.io/klog/v2"

	_ "github.com/apache/beam/sdks/go/pkg/beam/core/runtime/exec/optimized"
	_ "github.com/apache/beam/sdks/go/pkg/beam/io/filesystem/local"
	_ "github.com/apache/beam/sdks/go/pkg/beam/runners/direct"
	_ "github.com/apache/beam/sdks/go/pkg/beam/runners/flink"
	_ "github.com/lib/pq"
)

func PingDB(cmd *cobra.Command, args []string) {
	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s dbname=%s sslmode=disable",
		cmd.Flag("host").Value.String(),
		cmd.Flag("port").Value.String(),
		cmd.Flag("user").Value.String(),
		args[0],
	)

	beam.Init()

	p, s := beam.NewPipelineWithRoot()
	s.Scope("runner.PingDB")

	type result struct {
		Now sql.NullTime `db:"now" json:"now"`
	}

	ping := databaseio.Query(
		s,
		"postgres",
		dsn,
		"select now() as now;",
		reflect.TypeOf(result{}),
	)

	beam.ParDo0(s, func(ctx context.Context, n result) {
		select {
		case <-ctx.Done():
			return
		default:
			if n.Now.Valid {
				klog.Info(n.Now.Time.String())
			}
		}

	}, ping)

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	if _, err := beam.Run(ctx, cmd.Flag("runner").Value.String(), p); err != nil {
		klog.Fatal(err)
	}
}

// Rides table scans the movr.rides table and counts how
// many rides individual riders and vehicles took.
func Rides(cmd *cobra.Command, args []string) {
	// parse flag off cobra command and expose it to flagset for flink
	if err := flag.Set("endpoint", cmd.Flag("flink-dsn").Value.String()); err != nil {
		klog.Fatal(err)
	}

	dsn := fmt.Sprintf(
		"host=%s port=%s user=%s dbname=%s sslmode=disable",
		cmd.Flag("host").Value.String(),
		cmd.Flag("port").Value.String(),
		cmd.Flag("user").Value.String(),
		args[0],
	)

	beam.Init()

	p, s := beam.NewPipelineWithRoot()
	s.Scope("runner.Rides")

	type rides struct {
		VehicleID sql.NullString `db:"vehicle_id" json:"vehicle_id"`
		RiderID   sql.NullString `db:"rider_id" json:"rider_id"`
	}

	// sends ride rows on a stream for processing
	stream := databaseio.Query(s, "postgres", dsn,
		"select vehicle_id, rider_id from rides;", reflect.TypeOf(rides{}))

	// split stream into vehicle and rider streams
	vehicles, riders := beam.ParDo2(s, func(ctx context.Context, r rides, vehicles, riders func(string)) {
		select {
		case <-ctx.Done():
			return
		default:
			if r.VehicleID.Valid {
				vehicles(r.VehicleID.String)
			}
			if r.RiderID.Valid {
				riders(r.RiderID.String)
			}
		}
	}, stream)

	// write rides for vehicles grouped by vehicle UUID
	vehicleKeys := beam.ParDo(s, func(k string, i int) string {
		klog.Infof("v-%s: %d", k, i)
		return k
	}, stats.Count(s, vehicles))

	// write rides for riders grouped by rider UUID
	riderKeys := beam.ParDo(s, func(k string, i int) string {
		klog.Infof("r-%s: %d", k, i)
		return k
	}, stats.Count(s, riders))

	// write unique vehicles
	beam.ParDo0(s, func(i int) {
		klog.Infof("unique vehicles %d", i)
	}, stats.CountElms(s, beam.AddFixedKey(s, vehicleKeys)))

	// write total number of vehicles
	beam.ParDo0(s, func(i int) {
		klog.Infof("total vehicles %d", i)
	}, stats.CountElms(s, beam.AddFixedKey(s, vehicles)))

	// write unique riders
	beam.ParDo0(s, func(i int) {
		klog.Infof("unique riders %d", i)
	}, stats.CountElms(s, beam.AddFixedKey(s, riderKeys)))

	// write total number of riders
	beam.ParDo0(s, func(i int) {
		klog.Infof("total riders %d", i)
	}, stats.CountElms(s, beam.AddFixedKey(s, riders)))

	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Minute)
	defer cancel()

	if _, err := beam.Run(ctx, cmd.Flag("runner").Value.String(), p); err != nil {
		klog.Fatal(err)
	}
}

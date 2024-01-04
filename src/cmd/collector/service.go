package collector

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"os"
	"time"

	_ "github.com/lib/pq"
	"k8s.io/klog/v2"
)

type LogRow struct {
	Arch          string    `db:"arch"`
	Host          string    `db:"host"`
	KernalVersion string    `db:"kernal_version"`
	CreatedAT     time.Time `db:"created_at"`
}

type LogService struct {
	db *sql.DB
}

type LogAppendRequest struct {
	Arch          string
	Host          string
	KernalVersion string
}

func (l *LogService) Append(ctx context.Context, req *LogAppendRequest) error {
	const appendSql = `
insert into logs(
  arch, host, kernal_version, created_at
) 
values 
  ($1, $2, $3, $4);
`
	result, err := l.db.ExecContext(
		ctx, appendSql, req.Arch, req.Host, req.KernalVersion, time.Now().UTC())
	if err != nil {
		return err
	}
	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rows != 1 {
		return errors.New("log not written")
	}
	return nil
}

type Query struct {
	host  string
	since uint8
	limit string
}

func (l *LogService) read(ctx context.Context, query string, q Query) ([]LogRow, error) {
	rows, err := l.db.QueryContext(ctx, query, q.host, q.since, q.limit)
	if err != nil {
		return nil, err
	}
	logRows := make([]LogRow, 0)
	for rows.Next() {
		var logRow LogRow
		if err = rows.Scan(
			&logRow.Arch,
			&logRow.Host,
			&logRow.KernalVersion,
			&logRow.CreatedAT,
		); err != nil {
			return nil, err
		}
		logRows = append(logRows, logRow)
	}
	if rows.Err() != nil {
		return nil, rows.Err()
	}
	if err = rows.Close(); err != nil {
		return nil, err
	}
	return logRows, err

}

func (l *LogService) Since(ctx context.Context, q Query) ([]LogRow, error) {
	const query = `
select 
  arch,
  host,
  kernal_version,
  created_at 
from
  logs
where 
  host = $1 and
  created_at > (current_timestamp - interval '1 minutes' * $2)
order by 
  created_at desc
limit
  $3;
`
	return l.read(ctx, query, q)
}

func (l *LogService) Read(ctx context.Context, q Query) ([]LogRow, error) {
	if q.since != 0 {
		return l.Since(ctx, q)
	}
	const query = `
select 
  arch,
  host,
  kernal_version,
  created_at 
from
  logs
where 
  host = $1
order by 
  created_at desc
limit
  $2;
`
	return l.read(ctx, query, q)
}

func MustConnectDB() *sql.DB {
	host := os.Getenv("POSTGRES_HOST")
	if host == "" {
		host = "localhost:54321"
	}
	database := os.Getenv("POSTGRES_DATABASE")
	if database == "" {
		database = "cluster"
	}
	user := os.Getenv("POSTGRES_USER")
	if user == "" {
		user = "app"
	}
	password := os.Getenv("POSTGRES_PASSWORD")
	if password == "" {
		password = "app"
	}
	connStr := fmt.Sprintf("postgresql://%s:%s@%s/%s?sslmode=disable",
		user, password, host, database,
	)
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		klog.Fatal(err)
	}
	return db
}

func MigrateDB(db *sql.DB) {
	klog.Info("migrating database")
	const migrationSql = `
create table if not exists logs (
	id serial not null primary key,
	arch varchar(32) not null,
	host varchar(255) not null,
	kernal_version varchar(255) not null,
	created_at timestamp not null
);
`
	if _, err := db.Exec(migrationSql); err != nil {
		klog.Fatalf("not able to migrate database %s\n", err)
	}
}

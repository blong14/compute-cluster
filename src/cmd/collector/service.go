package collector

import (
	"context"
	"database/sql"
	"errors"
	"time"

	_ "github.com/lib/pq"
)

type LogRow struct {
	Host      string    `db:"host"`
	CreatedAT time.Time `db:"created_at"`
}

type LogService struct {
	db *sql.DB
}

type AppendReq struct {
	Host string
}

func (l *LogService) Append(ctx context.Context, req *AppendReq) error {
	result, err := l.db.ExecContext(
		ctx, "insert into logs(host, created_at) values($1, $2)", req.Host, time.Now().UTC())
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

type ReadReq struct {
	Host string
}

func (l *LogService) Last(ctx context.Context, req *ReadReq) (*LogRow, error) {
	var logRow LogRow
	err := l.db.QueryRowContext(
		ctx,
		`select host, created_at from logs where host = '$1' and created_at > (current_timestamp - interval '10 minutes') order by created_at desc`,
		req.Host,
	).Scan(&logRow)
	return &logRow, err
}

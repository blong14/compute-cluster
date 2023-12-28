package collector

import (
	"context"
	"database/sql"
	"errors"
	"time"

	_ "github.com/lib/pq"
)

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

package collector

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
)

type ErrorResponse struct {
	Status int
	Error  string
}

type HealthzRequest struct {
	Host string
}

type HealthzResponse struct {
	Status string
}

func HealthzService(ctx context.Context, srvc *LogService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			MustWriteJSON(w, r, http.StatusOK, HealthzResponse{Status: "ok"})
		case http.MethodPost:
			body := r.Body
			if body == nil {
				resp := ErrorResponse{Error: "server error", Status: http.StatusBadRequest}
				MustWriteJSON(w, r, http.StatusBadRequest, resp)
				return
			}
			defer func() { _ = body.Close() }()
			decoder := json.NewDecoder(body)
			var req HealthzRequest
			if err := decoder.Decode(&req); err != nil {
				resp := ErrorResponse{Error: err.Error()}
				MustWriteJSON(w, r, http.StatusInternalServerError, resp)
				return

			}
			log.Printf("received heart beat from %s\n", req.Host)
			if err := srvc.Append(ctx, &AppendReq{Host: req.Host}); err != nil {
				resp := ErrorResponse{Error: err.Error()}
				MustWriteJSON(w, r, http.StatusInternalServerError, resp)
				return
			}
			MustWriteJSON(w, r, http.StatusCreated, HealthzResponse{Status: "ok"})
		default:
			errResp := ErrorResponse{Error: "method not allowed"}
			MustWriteJSON(w, r, http.StatusMethodNotAllowed, errResp)
		}
	}
}

type Handler map[string]http.HandlerFunc

func HTTPHandlers(ctx context.Context, db *sql.DB) Handler {
	srvc := LogService{db: db}
	return map[string]http.HandlerFunc{
		"/healthz": HealthzService(ctx, &srvc),
	}
}

func Server(port string) *http.Server {
	return &http.Server{Addr: port}
}

func Start(srv *http.Server, routes Handler) {
	for pattern, handler := range routes {
		http.HandleFunc(pattern, handler)
	}
	log.Printf("listening on %s\n", srv.Addr)
	if err := srv.ListenAndServe(); err != http.ErrServerClosed {
		log.Println(err)
	}
}

func Stop(ctx context.Context, srvs ...*http.Server) {
	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()
	for _, srv := range srvs {
		if err := srv.Shutdown(ctx); err != nil {
			log.Printf("HTTP server Shutdown: %v", err)
		}
	}
}

func MustWriteJSON(w http.ResponseWriter, _ *http.Request, status int, resp interface{}) {
	w.Header().Set("Content-Type", "application/json")
	if status >= http.StatusBadRequest {
		w.WriteHeader(status)
	}
	jsonResp, err := json.Marshal(resp)
	if err != nil {
		log.Fatalf("Error happened in JSON marshal. Err: %s", err)
	}
	if _, err := w.Write(jsonResp); err != nil {
		log.Fatalf("Error happened in writing JSON. Err: %s", err)
	}
}

func MustConnectDB() *sql.DB {
	host := os.Getenv("POSTGRES_HOST")
	if host == "" {
		host = "localhost"
	}
	database := os.Getenv("POSTGRES_DATABASE")
	if database == "" {
		database = "logs"
	}
	user := os.Getenv("POSTGRES_USER")
	if user == "" {
		user = "postgres"
	}
	password := os.Getenv("POSTGRES_PASSWORD")
	connStr := fmt.Sprintf("postgresql://%s:%s@%s/%s?sslmode=disable",
		user, password, host, database,
	)
	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}
	return db
}

func MigrateDB(db *sql.DB) {
	log.Println("migrating database")
	if _, err := db.Exec(
		"create table if not exists logs (id serial not null primary key, host varchar(255) not null, created_at timestamp not null)",
	); err != nil {
		log.Fatalf("not able to migrate database %s\n", err)
	}
}

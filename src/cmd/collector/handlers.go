package collector

import (
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"k8s.io/klog/v2"
)

type ErrorResponse struct {
	Status int
	Error  string
}

type HealthzResponse struct {
	Data   []LogRow
	Error  string
	Host   string
	Status string
}

func HealthzRead(srvc *LogService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		switch r.Method {
		case http.MethodGet, http.MethodHead:
			ctx, cancel := context.WithCancel(r.Context())
			defer cancel()
			status := http.StatusOK
			response := HealthzResponse{Status: "ok"}
			if err := srvc.db.PingContext(ctx); err != nil {
				status = http.StatusInternalServerError
				response = HealthzResponse{
					Error:  err.Error(),
					Status: "not ok",
				}
			}
			MustWriteJSON(w, r, status, response)
		default:
			MustWriteJSON(w, r, http.StatusMethodNotAllowed, ErrorResponse{Error: "not allowed"})
		}
		klog.Infof("GET %s in %s\n", r.URL, time.Since(start))
	}
}

func LogRead(srvc *LogService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			errResp := ErrorResponse{Error: "method not allowed"}
			MustWriteJSON(w, r, http.StatusMethodNotAllowed, errResp)
			return
		}
		start := time.Now()
		ctx, cancel := context.WithCancel(r.Context())
		defer cancel()
		urlQuery := r.URL.Query()
		if !urlQuery.Has("host") {
			err := ErrorResponse{
				Status: http.StatusBadRequest,
				Error:  "missing host",
			}
			MustWriteJSON(w, r, http.StatusBadRequest, err)
			return
		}
		limit := urlQuery.Get("limit")
		if limit == "" {
			limit = "100"
		}
		since := uint8(0)
		s := urlQuery.Get("since")
		if s != "" {
			sin, err := strconv.ParseInt(s, 10, 8)
			if err != nil {
				since = 255 // max number of rows we'll return
			}
			since = uint8(sin)
		}
		q := Query{
			host:  urlQuery.Get("host"),
			since: since,
			limit: limit,
		}
		items, err := srvc.Read(ctx, q)
		var (
			status int
			resp   HealthzResponse
		)
		switch {
		case err == sql.ErrNoRows:
			klog.Error(err)
			status = http.StatusNotFound
			resp = HealthzResponse{Status: "not ok", Error: "rows not found"}
		case err != nil:
			klog.Error(err)
			status = http.StatusInternalServerError
			resp = HealthzResponse{Status: "not ok", Error: err.Error()}
		default:
			status = http.StatusOK
			resp = HealthzResponse{Status: "ok", Host: q.host, Data: items}
		}
		MustWriteJSON(w, r, status, resp)
		klog.Infof("GET (%d) %s for %s in %s\n", status, r.URL, q.host, time.Since(start))
	}
}

func LogCreate(srvc *LogService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			errResp := ErrorResponse{Error: "method not allowed"}
			MustWriteJSON(w, r, http.StatusMethodNotAllowed, errResp)
			return
		}
		start := time.Now()
		body := r.Body
		if body == nil {
			resp := ErrorResponse{Error: "server error", Status: http.StatusBadRequest}
			MustWriteJSON(w, r, http.StatusBadRequest, resp)
			klog.Errorf("POST %s missing body in request", r.URL)
			return
		}
		defer func() { _ = body.Close() }()
		decoder := json.NewDecoder(body)
		var req LogAppendRequest
		if err := decoder.Decode(&req); err != nil {
			resp := ErrorResponse{Error: err.Error()}
			MustWriteJSON(w, r, http.StatusInternalServerError, resp)
			klog.Errorf("POST (%d) %s %s", http.StatusInternalServerError, r.URL, err)
			return
		}
		ctx, cancel := context.WithCancel(r.Context())
		defer cancel()
		if err := srvc.Append(ctx, &req); err != nil {
			resp := ErrorResponse{Error: err.Error()}
			MustWriteJSON(w, r, http.StatusInternalServerError, resp)
			klog.Errorf("POST (%d) %s %s", http.StatusInternalServerError, r.URL, err)
			return
		}
		MustWriteJSON(w, r, http.StatusCreated, HealthzResponse{Status: "ok"})
		klog.Infof("POST (%d) %s from %s in %s\n", http.StatusCreated, r.URL, req.Host, time.Since(start))
	}
}

type Handler map[string]http.HandlerFunc

func HTTPHandlers(db *sql.DB) Handler {
	srvc := LogService{db: db}
	return map[string]http.HandlerFunc{
		"/healthz":    HealthzRead(&srvc),
		"/log/append": LogCreate(&srvc),
		"/log/get":    LogRead(&srvc),
	}
}

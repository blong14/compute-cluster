package collector

import (
	"context"
	"database/sql"
	"encoding/json"
	"k8s.io/klog/v2"
	"net/http"
	"time"
)

type ErrorResponse struct {
	Status int
	Error  string
}

type HealthzResponse struct {
	Error  string
	Host   string
	Status string
}

func HealthzRead(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	switch r.Method {
	case http.MethodGet, http.MethodHead:
		MustWriteJSON(w, r, http.StatusOK, HealthzResponse{Status: "ok"})
	default:
		MustWriteJSON(w, r, http.StatusMethodNotAllowed, ErrorResponse{Error: "not allowed"})
	}
	klog.Infof("GET %s in %s\n", r.URL, time.Since(start))
}

func LogRead(srvc *LogService) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			errResp := ErrorResponse{Error: "method not allowed"}
			MustWriteJSON(w, r, http.StatusMethodNotAllowed, errResp)
			return
		}
		start := time.Now()
		urlQuery := r.URL.Query()
		if !urlQuery.Has("host") {
			err := ErrorResponse{Error: "missing host"}
			MustWriteJSON(w, r, http.StatusBadRequest, err)
			return
		}
		host := urlQuery.Get("host")
		ctx, cancel := context.WithCancel(r.Context())
		defer cancel()
		last, err := srvc.Last(ctx, &ReadReq{Host: host})
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
			resp = HealthzResponse{Status: "ok", Host: last.Host}
		}
		MustWriteJSON(w, r, status, resp)
		klog.Infof("GET (%d) %s for %s in %s\n", status, r.URL, host, time.Since(start))
	}
}

type LogCreateRequest struct {
	Host string
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
			return
		}
		defer func() { _ = body.Close() }()
		decoder := json.NewDecoder(body)
		var req LogCreateRequest
		if err := decoder.Decode(&req); err != nil {
			resp := ErrorResponse{Error: err.Error()}
			MustWriteJSON(w, r, http.StatusInternalServerError, resp)
			return
		}
		ctx, cancel := context.WithCancel(r.Context())
		defer cancel()
		if err := srvc.Append(ctx, &AppendReq{Host: req.Host}); err != nil {
			resp := ErrorResponse{Error: err.Error()}
			MustWriteJSON(w, r, http.StatusInternalServerError, resp)
			return
		}
		MustWriteJSON(w, r, http.StatusCreated, HealthzResponse{Status: "ok"})
		klog.Infof("POST %s from %s in %s\n", r.URL, req.Host, time.Since(start))
	}
}

type Handler map[string]http.HandlerFunc

func HTTPHandlers(db *sql.DB) Handler {
	srvc := LogService{db: db}
	return map[string]http.HandlerFunc{
		"/healthz":  HealthzRead,
		"/log":      LogCreate(&srvc),
		"/log/last": LogRead(&srvc),
	}
}

func Server(port string) *http.Server {
	return &http.Server{Addr: port}
}

func Start(srv *http.Server, routes Handler) {
	for pattern, handler := range routes {
		http.HandleFunc(pattern, handler)
	}
	klog.Infof("listening on %s\n", srv.Addr)
	if err := srv.ListenAndServe(); err != http.ErrServerClosed {
		klog.Fatal(err)
	}
}

func Stop(ctx context.Context, srvs ...*http.Server) {
	ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
	defer cancel()
	for _, srv := range srvs {
		if err := srv.Shutdown(ctx); err != nil {
			klog.Warningf("HTTP server Shutdown: %v\n", err)
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
		klog.Fatalf("Error happened in JSON marshal. Err: %s", err)
	}
	if _, err := w.Write(jsonResp); err != nil {
		klog.Fatalf("Error happened in writing JSON. Err: %s", err)
	}
}

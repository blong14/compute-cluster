package collector

import (
	"context"
	"encoding/json"
	"net/http"
	"time"

	"k8s.io/klog/v2"
)

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

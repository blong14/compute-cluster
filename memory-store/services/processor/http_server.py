#!/usr/bin/env python3
"""
Simple HTTP server for health checks and metrics.
Runs alongside the document processor for monitoring.
"""

import os
import json
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
from health_check import HealthChecker
import logging

logger = logging.getLogger(__name__)

class HealthHandler(BaseHTTPRequestHandler):
    def __init__(self, *args, health_checker=None, **kwargs):
        self.health_checker = health_checker
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/health':
            self._handle_health()
        elif parsed_path.path == '/metrics':
            self._handle_metrics()
        elif parsed_path.path == '/':
            self._handle_root()
        else:
            self._handle_404()
    
    def _handle_health(self):
        """Health check endpoint"""
        try:
            health = self.health_checker.check_health()
            status_code = 200 if health["status"] == "healthy" else 503
            
            self.send_response(status_code)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(health, indent=2).encode())
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            error_response = {"status": "error", "message": str(e)}
            self.wfile.write(json.dumps(error_response).encode())
    
    def _handle_metrics(self):
        """Metrics endpoint"""
        try:
            health = self.health_checker.check_health()
            metrics = health.get("metrics", {})
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(metrics, indent=2).encode())
            
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            error_response = {"error": str(e)}
            self.wfile.write(json.dumps(error_response).encode())
    
    def _handle_root(self):
        """Root endpoint with service info"""
        info = {
            "service": "memory-store-processor",
            "version": "1.0.0",
            "endpoints": {
                "/health": "Health check",
                "/metrics": "Processing metrics",
                "/": "Service information"
            }
        }
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(info, indent=2).encode())
    
    def _handle_404(self):
        """404 handler"""
        self.send_response(404)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        error_response = {"error": "Not found"}
        self.wfile.write(json.dumps(error_response).encode())
    
    def log_message(self, format, *args):
        """Override to use our logger"""
        logger.info(f"{self.address_string()} - {format % args}")

class HealthServer:
    def __init__(self, port=8080):
        self.port = port
        self.health_checker = HealthChecker(
            os.getenv("DATABASE_URL", "postgresql://memory_user:memory_pass@localhost:5432/memory_store"),
            os.getenv("VOYAGE_API_KEY")
        )
        self.server = None
        self.thread = None
    
    def start(self):
        """Start the health server in a separate thread"""
        def handler(*args, **kwargs):
            return HealthHandler(*args, health_checker=self.health_checker, **kwargs)
        
        self.server = HTTPServer(('0.0.0.0', self.port), handler)
        self.thread = threading.Thread(target=self.server.serve_forever)
        self.thread.daemon = True
        self.thread.start()
        
        logger.info(f"Health server started on port {self.port}")
    
    def stop(self):
        """Stop the health server"""
        if self.server:
            self.server.shutdown()
            self.server.server_close()
        if self.thread:
            self.thread.join()
        logger.info("Health server stopped")

if __name__ == "__main__":
    # Run standalone health server
    port = int(os.getenv("HEALTH_PORT", "8080"))
    server = HealthServer(port)
    
    try:
        server.start()
        logger.info(f"Health server running on port {port}")
        
        # Keep the main thread alive
        import time
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        logger.info("Shutting down health server...")
        server.stop()

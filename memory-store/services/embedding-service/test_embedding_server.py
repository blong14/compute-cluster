#!/usr/bin/env python3
"""
Comprehensive unit tests for the embedding server.

This test suite covers:
- Health endpoint functionality
- Embeddings generation endpoint
- Models listing endpoint
- Edge cases and error scenarios
- Performance and validation testing

Tests are designed to run against a live server at localhost:8001
"""

import unittest
import requests
import time
import concurrent.futures


class TestEmbeddingServer(unittest.TestCase):
    """Test suite for the embedding server API endpoints."""
    
    BASE_URL = "http://localhost:8001"
    
    @classmethod
    def setUpClass(cls):
        """Set up test class - verify server is running."""
        cls.session = requests.Session()
        cls.session.headers.update({'Content-Type': 'application/json'})
        
        # Wait for server to be ready
        max_retries = 30
        for i in range(max_retries):
            try:
                response = cls.session.get(f"{cls.BASE_URL}/health", timeout=5)
                if response.status_code == 200:
                    print(f"Server is ready after {i+1} attempts")
                    break
            except requests.exceptions.RequestException:
                if i == max_retries - 1:
                    raise unittest.SkipTest("Embedding server is not running at localhost:8001")
                time.sleep(1)
    
    @classmethod
    def tearDownClass(cls):
        """Clean up test class."""
        cls.session.close()

    def test_health_endpoint_success(self):
        """Test health endpoint returns correct structure when model is loaded."""
        response = self.session.get(f"{self.BASE_URL}/health")
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        # Verify response structure
        required_fields = ['status', 'model_loaded', 'model_name', 'device', 'dimensions']
        for field in required_fields:
            self.assertIn(field, data, f"Missing required field: {field}")
        
        # Verify field types and values
        self.assertEqual(data['status'], 'healthy')
        self.assertTrue(data['model_loaded'])
        self.assertIsInstance(data['model_name'], str)
        self.assertIn(data['device'], ['cpu', 'cuda'])
        self.assertIsInstance(data['dimensions'], int)
        self.assertGreater(data['dimensions'], 0)

    def test_embeddings_endpoint_single_text(self):
        """Test embeddings generation with a single text."""
        payload = {
            "texts": ["Hello world"],
            "model_name": "all-MiniLM-L6-v2"
        }
        
        response = self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        # Verify response structure
        required_fields = ['embeddings', 'model_name', 'dimensions', 'processing_time']
        for field in required_fields:
            self.assertIn(field, data, f"Missing required field: {field}")
        
        # Verify embeddings structure
        self.assertIsInstance(data['embeddings'], list)
        self.assertEqual(len(data['embeddings']), 1)
        self.assertIsInstance(data['embeddings'][0], list)
        self.assertGreater(len(data['embeddings'][0]), 0)
        
        # Verify all embedding values are floats
        for embedding_value in data['embeddings'][0]:
            self.assertIsInstance(embedding_value, float)
        
        # Verify dimensions match
        self.assertEqual(data['dimensions'], len(data['embeddings'][0]))
        
        # Verify processing time
        self.assertIsInstance(data['processing_time'], float)
        self.assertGreater(data['processing_time'], 0)

    def test_embeddings_endpoint_multiple_texts(self):
        """Test embeddings generation with multiple texts."""
        payload = {
            "texts": [
                "Hello world",
                "This is a test sentence",
                "Machine learning is fascinating",
                "Natural language processing"
            ]
        }
        
        response = self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        # Verify correct number of embeddings
        self.assertEqual(len(data['embeddings']), 4)
        
        # Verify all embeddings have same dimensions
        dimensions = len(data['embeddings'][0])
        for embedding in data['embeddings']:
            self.assertEqual(len(embedding), dimensions)

    def test_embeddings_endpoint_empty_texts_error(self):
        """Test embeddings endpoint with empty texts list."""
        payload = {"texts": []}
        
        response = self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
        
        self.assertEqual(response.status_code, 400)
        data = response.json()
        self.assertIn("No texts provided", data['detail'])

    def test_embeddings_endpoint_too_many_texts_error(self):
        """Test embeddings endpoint with too many texts (>100)."""
        payload = {
            "texts": [f"Text number {i}" for i in range(101)]
        }
        
        response = self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
        
        self.assertEqual(response.status_code, 400)
        data = response.json()
        self.assertIn("Too many texts", data['detail'])

    def test_embeddings_endpoint_invalid_json(self):
        """Test embeddings endpoint with invalid JSON."""
        response = self.session.post(
            f"{self.BASE_URL}/embeddings",
            data="invalid json",
            headers={'Content-Type': 'application/json'}
        )
        
        self.assertEqual(response.status_code, 422)

    def test_embeddings_endpoint_missing_texts_field(self):
        """Test embeddings endpoint with missing texts field."""
        payload = {"model_name": "all-MiniLM-L6-v2"}
        
        response = self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
        
        self.assertEqual(response.status_code, 422)

    def test_embeddings_endpoint_empty_string_in_texts(self):
        """Test embeddings endpoint with empty string in texts."""
        payload = {
            "texts": ["Hello world", "", "Another text"]
        }
        
        response = self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
        
        # Should still work - empty strings are valid input
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(len(data['embeddings']), 3)

    def test_embeddings_endpoint_unicode_text(self):
        """Test embeddings endpoint with unicode characters."""
        payload = {
            "texts": [
                "Hello 世界",
                "Café résumé naïve",
                "🚀 Emoji test 🎉",
                "Ñoño niño"
            ]
        }
        
        response = self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(len(data['embeddings']), 4)

    def test_embeddings_endpoint_very_long_text(self):
        """Test embeddings endpoint with very long text."""
        long_text = "This is a very long text. " * 1000  # ~26,000 characters
        payload = {
            "texts": [long_text]
        }
        
        response = self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
        
        # Should handle long text gracefully
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(len(data['embeddings']), 1)

    def test_models_endpoint(self):
        """Test models listing endpoint."""
        response = self.session.get(f"{self.BASE_URL}/models")
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        
        # Verify response structure
        self.assertIn('available_models', data)
        self.assertIn('current_model', data)
        
        # Verify available models structure
        available_models = data['available_models']
        self.assertIsInstance(available_models, dict)
        
        # Check for expected models
        expected_models = [
            'all-MiniLM-L6-v2',
            'all-mpnet-base-v2',
            'all-MiniLM-L12-v2',
            'paraphrase-multilingual-MiniLM-L12-v2'
        ]
        
        for model_name in expected_models:
            self.assertIn(model_name, available_models)
            model_info = available_models[model_name]
            
            # Verify model info structure
            required_fields = ['description', 'size', 'performance']
            for field in required_fields:
                self.assertIn(field, model_info)
                self.assertIsInstance(model_info[field], str)

    def test_embeddings_consistency(self):
        """Test that same input produces consistent embeddings."""
        payload = {
            "texts": ["Consistency test text"]
        }
        
        # Make multiple requests
        responses = []
        for _ in range(3):
            response = self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
            self.assertEqual(response.status_code, 200)
            responses.append(response.json())
        
        # Verify embeddings are identical
        first_embedding = responses[0]['embeddings'][0]
        for response in responses[1:]:
            self.assertEqual(response['embeddings'][0], first_embedding)

    def test_embeddings_normalization(self):
        """Test that embeddings are normalized (L2 norm ≈ 1)."""
        payload = {
            "texts": ["Test normalization"]
        }
        
        response = self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
        self.assertEqual(response.status_code, 200)
        
        embedding = response.json()['embeddings'][0]
        
        # Calculate L2 norm
        l2_norm = sum(x**2 for x in embedding) ** 0.5
        
        # Should be approximately 1 (allowing for floating point precision)
        self.assertAlmostEqual(l2_norm, 1.0, places=5)

    def test_concurrent_requests(self):
        """Test server handles concurrent requests properly."""
        payload = {
            "texts": [f"Concurrent test {i}" for i in range(5)]
        }
        
        def make_request():
            return self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
        
        # Make 5 concurrent requests
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(make_request) for _ in range(5)]
            responses = [future.result() for future in concurrent.futures.as_completed(futures)]
        
        # All requests should succeed
        for response in responses:
            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(len(data['embeddings']), 5)

    def test_performance_timing(self):
        """Test that processing times are reasonable."""
        payload = {
            "texts": ["Performance test text"] * 10
        }
        
        start_time = time.time()
        response = self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
        end_time = time.time()
        
        self.assertEqual(response.status_code, 200)
        
        data = response.json()
        server_processing_time = data['processing_time']
        total_request_time = end_time - start_time
        
        # Server processing time should be reasonable
        self.assertLess(server_processing_time, 10.0)  # Less than 10 seconds
        self.assertGreater(server_processing_time, 0)
        
        # Server processing time should be less than total request time
        self.assertLess(server_processing_time, total_request_time)

    def test_invalid_endpoints(self):
        """Test invalid endpoints return 404."""
        invalid_endpoints = [
            "/invalid",
            "/embedding",  # Missing 's'
            "/model",      # Missing 's'
            "/healthcheck" # Wrong name
        ]
        
        for endpoint in invalid_endpoints:
            response = self.session.get(f"{self.BASE_URL}{endpoint}")
            self.assertEqual(response.status_code, 404)

    def test_wrong_http_methods(self):
        """Test wrong HTTP methods return 405."""
        # POST to health endpoint (should be GET)
        response = self.session.post(f"{self.BASE_URL}/health")
        self.assertEqual(response.status_code, 405)
        
        # GET to embeddings endpoint (should be POST)
        response = self.session.get(f"{self.BASE_URL}/embeddings")
        self.assertEqual(response.status_code, 405)
        
        # POST to models endpoint (should be GET)
        response = self.session.post(f"{self.BASE_URL}/models")
        self.assertEqual(response.status_code, 405)


class TestEmbeddingServerStress(unittest.TestCase):
    """Stress tests for the embedding server."""
    
    BASE_URL = "http://localhost:8001"
    
    @classmethod
    def setUpClass(cls):
        """Set up test class."""
        cls.session = requests.Session()
        cls.session.headers.update({'Content-Type': 'application/json'})
    
    @classmethod
    def tearDownClass(cls):
        """Clean up test class."""
        cls.session.close()

    def test_maximum_batch_size(self):
        """Test with maximum allowed batch size (100 texts)."""
        payload = {
            "texts": [f"Batch test text number {i}" for i in range(100)]
        }
        
        response = self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
        
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(len(data['embeddings']), 100)
        
        # Verify processing time is reasonable for large batch
        self.assertLess(data['processing_time'], 30.0)  # Less than 30 seconds

    def test_rapid_sequential_requests(self):
        """Test rapid sequential requests."""
        payload = {
            "texts": ["Rapid test"]
        }
        
        responses = []
        start_time = time.time()
        
        for i in range(20):
            response = self.session.post(f"{self.BASE_URL}/embeddings", json=payload)
            responses.append(response)
        
        end_time = time.time()
        
        # All requests should succeed
        for response in responses:
            self.assertEqual(response.status_code, 200)
        
        # Should complete in reasonable time
        total_time = end_time - start_time
        self.assertLess(total_time, 60.0)  # Less than 60 seconds for 20 requests


if __name__ == '__main__':
    # Print test information
    print("=" * 80)
    print("EMBEDDING SERVER TEST SUITE")
    print("=" * 80)
    print("This test suite requires the embedding server to be running at localhost:8001")
    print("Start the server with: python embedding_server.py")
    print("=" * 80)
    print()
    
    # Run tests with verbose output
    unittest.main(verbosity=2, buffer=True)


"""
TODO: Additional test cases that should be considered:

SECURITY TESTS:
- [ ] Test SQL injection attempts in text inputs
- [ ] Test XSS attempts in text inputs  
- [ ] Test extremely large payloads (DoS protection)
- [ ] Test malformed headers
- [ ] Test authentication/authorization if implemented

PERFORMANCE TESTS:
- [ ] Memory usage monitoring during large batches
- [ ] CPU usage monitoring during processing
- [ ] Test with different model sizes and their performance impact
- [ ] Load testing with sustained high request rates
- [ ] Test memory leaks with long-running processes

MODEL-SPECIFIC TESTS:
- [ ] Test with different embedding models (if model switching is supported)
- [ ] Test model loading/unloading scenarios
- [ ] Test behavior when model files are corrupted or missing
- [ ] Test GPU vs CPU performance differences
- [ ] Test model warm-up time and caching

ERROR RECOVERY TESTS:
- [ ] Test server behavior when running out of memory
- [ ] Test server behavior when GPU memory is exhausted
- [ ] Test network interruption handling
- [ ] Test disk space exhaustion scenarios
- [ ] Test graceful shutdown and restart scenarios

INTEGRATION TESTS:
- [ ] Test with real-world text samples from different domains
- [ ] Test with texts in different languages
- [ ] Test integration with vector databases
- [ ] Test with downstream applications (similarity search, clustering)
- [ ] Test API compatibility with OpenAI embeddings format

MONITORING AND OBSERVABILITY:
- [ ] Test logging output and format
- [ ] Test metrics collection (if implemented)
- [ ] Test health check edge cases (partial failures)
- [ ] Test error reporting and debugging information
- [ ] Test request tracing and correlation IDs

CONFIGURATION TESTS:
- [ ] Test different environment variable configurations
- [ ] Test configuration validation
- [ ] Test default value handling
- [ ] Test configuration hot-reloading (if supported)
- [ ] Test invalid configuration handling

DATA VALIDATION TESTS:
- [ ] Test with binary data in text fields
- [ ] Test with extremely long individual texts (>1M characters)
- [ ] Test with special characters and control characters
- [ ] Test with different text encodings
- [ ] Test with malformed Unicode sequences

EDGE CASE TESTS:
- [ ] Test server startup without internet connection (for model downloads)
- [ ] Test behavior with insufficient disk space for model caching
- [ ] Test with system clock changes during processing
- [ ] Test with different Python versions and dependency versions
- [ ] Test container resource limits and constraints
"""

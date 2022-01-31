from json import JSONDecodeError
from typing import Optional

from locust import HttpUser, between, constant, task


class MetricsUser(HttpUser):
    wait_time = constant(2)

    @task
    def metrics(self):
        self.client.get("/metrics")


class HealthUser(HttpUser):
    wait_time = constant(1)

    @task
    def health(self):
        self.client.get("/v1/health")


class ProjectsUser(HttpUser):
    wait_time = between(0.5, 2.0)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._token: Optional[str] = None

    def on_start(self):
        endpoint = "/v1/auth/login/"
        data = {"email": "admin@graft.com", "password": "password"}
        with self.client.post(endpoint, json=data, catch_response=True) as resp:
            try:
                data = resp.json()
            except JSONDecodeError:
                resp.failure("Response could not be decoded as JSON")
            finally:
                self._token = data.get("access_token")

    @task
    def projects(self):
        if self._token is None:
            raise ValueError("missing token")
        headers = {"Authorization": f"Bearer {self._token}"}
        self.client.get("/v1/projects/", headers=headers)

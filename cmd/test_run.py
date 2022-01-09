import asyncio
import unittest
from functools import wraps

import aiohttp

import cmd.run as run

def with_async_request(fn):
    @wraps(fn)
    def wrapper(self):
        async def _request(awaitable, user: run.User, *args, **kwargs):
            timeout = kwargs.pop('timeout', 1.0)
            async with aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=timeout)) as session:
                return await awaitable(run.HttpRequest(session=session, token=user.token), *args, **kwargs)
        return fn(self, _request)
    return wrapper


class TestAPI(unittest.TestCase):
    usr: run.User = run.User(email='', token='', projects=list())

    @with_async_request
    def setUp(self, request):
        self.usr = asyncio.run(request(run.user, self.usr))

    @with_async_request
    def test_healthz(self, request):
        healthz = asyncio.run(request(run.healthz, self.usr))
        self.assertIsInstance(healthz, run.Healthz)

    @with_async_request
    def test_notes(self, request):
        project = asyncio.run(request(run.notes, self.usr, run.Project(id='832322363b', title='', notes=list())))
        self.assertNotEqual(len(project.notes), 0)

    @with_async_request
    def test_projects(self, request):
        projects = asyncio.run(request(run.projects, self.usr))
        self.assertIsInstance(projects, list)
        self.assertNotEqual(len(projects), 0)

    @with_async_request
    def test_projects_error(self, request):
        projects = asyncio.run(request(run.projects, self.usr, timeout=0.01))
        self.assertIsInstance(projects, list)
        self.assertEqual(len(projects), 0)


if __name__ == '__main__':
    unittest.main()


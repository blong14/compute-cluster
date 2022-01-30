import asyncio
import logging
from typing import Any, List, Optional

import aiohttp

from pkg.tools.dataclass import dataclass


logger = logging.getLogger(__name__)


@dataclass(frozen=True, init=True)
class HttpRequest:
    session: Any
    token: str = ''
    base_url: str = 'https://api.graftapp.co'
    read_timeout: float = 10.0
    user: str = ''
    password: str = ''

    def header(self) -> dict:
        return {'Authorization': f'Bearer {self.token}'}



@dataclass(frozen=True)
class Note:
    id: str
    title: str
    body: Optional[str]


@dataclass(frozen=True)
class Project:
    id: str
    title: str
    notes: List[Note]


@dataclass(frozen=True)
class User:
    token: str
    email: str
    projects: List[Project]


@dataclass(frozen=True)
class Response:
    data: dict
    success: bool = False


READ_TIMEOUT = 10.0
ERROR_RESPONSE = Response(data=dict(), success=False)


async def _request(req: HttpRequest, method: str, url: str, **kwargs) -> Response:
    try:
        kwargs |= dict(headers=req.header())
        async with req.session.request(method, url, ssl=True, **kwargs) as resp:
            data = await resp.json()
    except asyncio.TimeoutError as e:
        logger.error(f'asyncio.TimeOutError {req.read_timeout}')
        return ERROR_RESPONSE
    except aiohttp.ClientResponseError as e:
        logger.error(e)
        logger.warning('sleeping...')
        await asyncio.sleep(3)
        return ERROR_RESPONSE
    else:
        return Response(success=True, data=data)


async def get_token(session: aiohttp.ClientSession) -> Response:
    req = HttpRequest(session=session)
    resp = await _request(
        req, aiohttp.hdrs.METH_POST, f'{req.base_url}/v1/auth/login/',
        json=dict(email=req.user, password=req.password))
    return resp


async def user(req: HttpRequest) -> User:
    resp = await _request(
        req, aiohttp.hdrs.METH_POST, f'{req.base_url}/v1/auth/login/',
        json=dict(email=req.user, password=req.password))
    return User(
        token=resp.data.get('access_token', ''),
        email=resp.data.get('user', dict()).get('email', ''),
        projects=await projects(HttpRequest(session=req.session, token=resp.data.get('access_token', '')))
    )


async def notes(req: HttpRequest, project: Project) -> Project:
    resp = await _request(
        req, aiohttp.hdrs.METH_GET, f'{req.base_url}/v1/projects/{project.id}/notes/')
    return Project(
        id=project.id,
        title=project.title,
        notes=[
            Note(
                id=n['id'],
                title=n['title'],
                body=n['body'],
            ) for n in resp.data.get('items', [])
        ],
    )


async def projects(req: HttpRequest) -> List[Project]:
    resp = await _request(req, aiohttp.hdrs.METH_GET, f'{req.base_url}/v1/projects/')
    if not resp.success:
        return list()
    future_projects = [
        asyncio.ensure_future(
            notes(req, Project(id=p['id'], title=p['title'], notes=list())),
        ) for p in resp.data.get('items', [])
    ]
    return [project for project in await asyncio.gather(*future_projects)]


async def main():
    async with aiohttp.ClientSession(
        trust_env=False,
        raise_for_status=True,
        timeout=aiohttp.ClientTimeout(total=READ_TIMEOUT),
    ) as session:
        logger.info('starting requests...')
        usr = await user(HttpRequest(session=session, token=''))
        logger.info('requesting data...')
        tasks = [
            asyncio.ensure_future(
                fn(HttpRequest(session=session, token=usr.token))
            ) for fn in (projects,)
        ]
        logger.info([data for data in await asyncio.gather(*tasks)])
        logger.info('finished')


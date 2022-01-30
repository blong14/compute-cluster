from typing import Any, Callable, Optional, Tuple, Type, TypeVar, Union, overload

from pydantic.dataclasses import dataclass as pyd_dataclass
from pydantic.fields import Field, FieldInfo

_T = TypeVar("_T")


def __dataclass_transform__(
    *,
    eq_default: bool = True,
    order_default: bool = False,
    kw_only_default: bool = False,
    field_descriptors: Tuple[Union[type, Callable[..., Any]], ...] = (()),
) -> Callable[[_T], _T]:
    return lambda a: a


@__dataclass_transform__(kw_only_default=True, field_descriptors=(Field, FieldInfo))
@overload
def dataclass(
    *,
    init: bool = True,
    repr: bool = True,
    eq: bool = True,
    order: bool = False,
    unsafe_hash: bool = False,
    frozen: bool = False,
    config: Type[Any] = None,
) -> Callable[[Type[_T]], Type[_T]]:  # type: ignore
    ...


@__dataclass_transform__(kw_only_default=True, field_descriptors=(Field, FieldInfo))
@overload
def dataclass(
    _cls: Type[_T],
    *,
    init: bool = True,
    repr: bool = True,
    eq: bool = True,
    order: bool = False,
    unsafe_hash: bool = False,
    frozen: bool = False,
    config: Type[Any] = None,
) -> Type[_T]:
    ...


@__dataclass_transform__(kw_only_default=True, field_descriptors=(Field, FieldInfo))
def dataclass(
    cls: Optional[Type[_T]] = None,
    *,
    init: bool = True,
    repr: bool = True,
    eq: bool = True,
    order: bool = False,
    unsafe_hash: bool = False,
    frozen: bool = False,
    config: Type[Any] = None,
) -> Union[Callable[[Type[Any]], Type[_T]], Type[_T]]:
    return pyd_dataclass(cls, init=init, repr=repr, eq=eq, order=order, unsafe_hash=unsafe_hash, frozen=frozen, config=config)  # type: ignore


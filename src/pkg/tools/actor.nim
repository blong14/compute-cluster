import os

import nimpy


var
  chan: Channel[string]
  thread: Thread[void]


type Actor* = ref object of RootObj
method run(this: Actor, chn: Channel[string]): void {.base.} = 
  while true:
    echo("hellow")


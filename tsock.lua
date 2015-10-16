#!/usr/bin/env lua
socket = require "socket"
--socket.unix = require "socket.unix"

--c = assert(socket.unix());
c = socket.tcp()

--assert(c:connect("/var/run/docker.sock"))
c:connect("localhost","8080")
print("connected!?")

local request = [[
GET /containers/json HTTP/1.1
HOST: localhost

]]
print("request:\r\n"..request)
c:send(request);
local line = c:receive()
print("line:"..line)
-- GET /outernet/client/rss/reddit-feeds HTTP/1.1\r\n
c:close()


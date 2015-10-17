#!/usr/bin/env lua
--socket = require "socket"
-- socket.unix = require "socket.unix"

--c = assert(socket.unix());
--assert(c:connect("/var/run/docker.sock"))
require "pl"
--http = require("socket.http")
unixHTTP= require("usock")
assert(unixHTTP)
json = require("json")
assert(json)
applyTemplate = require "pl.template".substitute

-- Get running containers
--b, c, h = http.request("http://localhost:8080/containers/json")
h, b = unixHttp.request("/containers/json")
print("b",b)
res = json.decode(b)
print(pretty.write(res))
print("----------")
containers={}

table.foreach(res, function(a,b) 
	local rec={}
	rec.Id=b.Id
	--strip front slash
	rec.Name=string.sub(b.Names[1],2,-1)
	if b.Ports[1] then
		rec.PrivatePort=b.Ports[1].PrivatePort
		rec.PublicPort=b.Ports[1].PublicPort
	end
	if rec.PublicPort then
		table.insert(containers,rec)
	end
	end)

-- Get the IPaddress from the container info.
-- not needed when using localhost !?
for i,val in ipairs(containers) do
--	b, c , h = http.request("http://localhost:8080/containers/"..val.Id.."/json")
	h, b = unixHttp.request("/containers/"..val.Id.."/json")
	local res = json.decode(b)
	if res.NetworkSettings.IPAddress then
		val.IPaddress = res.NetworkSettings.IPAddress
	end
end

haptl=file.read("./haproxy.tmpl")
mres = applyTemplate(haptl,{_escape='>',containers=containers,ipairs=ipairs})
file.write("./haproxy.cfg",mres)
print(mres)

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

function updateConfig()
	-- Get running containers
	--b, c, h = http.request("http://localhost:8080/containers/json")
	h, b = unixHttp.request("/containers/json")
	--print("b",b)
	res = json.decode(b)
	--print(pretty.write(res))
	--print("----------")
	containers={}

	table.foreach(res, function(a,b) 
		local rec={}
		rec.Id=b.Id
		--strip front slash
		rec.Name=string.sub(b.Names[1],2,-1)
		if b.Ports[1] then
			rec.IP=b.Ports[1].IP
			rec.PrivatePort=b.Ports[1].PrivatePort
			rec.PublicPort=b.Ports[1].PublicPort
		end
		if rec.PublicPort then
			table.insert(containers,rec)
		end
	end)

	haptl=file.read("./haproxy.tmpl")
	mres = applyTemplate(haptl,{_escape='>',containers=containers,ipairs=ipairs})
	file.copy("./haproxy.cfg","./haproxy.cfg.old")
	file.write("./haproxy.cfg",mres)
--	print(mres)
end

function restartHAProxy()
	--note: there is a 'zero downtime version to restart haproxy'
	--http://engineeringblog.yelp.com/2015/04/true-zero-downtime-haproxy-reloads.html
	
	if os.execute("test -e /tmp/haproxy.pid") > 0 then
		cmd="haproxy -f ./haproxy.cfg -p /tmp/haproxy.pid"
		os.execute(cmd)
	else
		pid=file.read("/tmp/haproxy.pid")

		cmd="haproxy -f ./haproxy.cfg -p /tmp/haproxy.pid -sf "..pid
		os.execute(cmd);
		--os.execute(cmd);
	end
end

function HAProxyNeedsUpdate()
	return os.execute("diff ./haproxy.cfg ./haproxy.cfg.old > /dev/null") ~= 0
end
function sleep(sec)
	return os.execute("sleep "..sec) == 0
end

repeat
	updateConfig()

	if HAProxyNeedsUpdate() then
		print("Updating HAProxy")
		restartHAProxy()
	end
	if not sleep(15) then
		--sigint ?
		os.exit(1)
	end
--	print("tick..")
until false 


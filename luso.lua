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

	for a, b in ipairs(res) do
		local rec={}
		rec.Id=b.Id
		--strip front slash
		rec.Name=string.sub(b.Names[1],2,-1)
		--table.foreach(b.Ports, function(k,v)print( v.PrivatePort)end);
		--if hasPort80(b.Ports) then print(rec.Name.." yup") else print(rec.Name.." nup") end
		--if hasPort80(b.Ports) then
		if hasEnvHautoproxy(rec.Name) then
			--rec.IP=b.Ports[1].IP
			print(rec.Name.." has port 80")
			--if hasEnvHautoproxy(rec.Name) then print("got hauto") else print("NO hauto") end
			rec.IP=getIP(rec.Name)
			-- needs more love
			rec.PrivatePort=80 --b.Ports[1].PrivatePort
			rec.PublicPort=b.Ports[1].PublicPort
		end
		--print("rec.Name:",rec.Name)
		--print("rec.PrivatePort:",rec.PrivatePort)
		--print("--")
		if rec.PrivatePort == 80 then
			table.foreach(rec, print)
			print("")
			table.insert(containers,rec)
		end
	end

	haptl=file.read("./haproxy.tmpl")
	mres = applyTemplate(haptl,{_escape='>',containers=containers,ipairs=ipairs})
	--use diff? no write read access needed if there is nochange
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

function getIP(name)
	h, b = unixHttp.request("/containers/"..name.."/json")
	--print("b",b)
	res = json.decode(b)
	print(pretty.write(res.NetworkSettings.IPAddress))
	return res.NetworkSettings.IPAddress
end

function hasPort80(tab)
	local got80 = false
	--table.foreach(tab, function(v,k)
	for v,k in ipairs(tab) do
		if(k.PrivatePort == 80) then 
			--print("got one")
			got80 = true
			break
		end
	end
	return got80
end

function hasEnvHautoproxy(name)
	local gotHauto = false

	h, b = unixHttp.request("/containers/"..name.."/json")
	--print("b",b)
	res = json.decode(b)
	if res.Config.Env then
		for k,item in ipairs(res.Config.Env) do
			if string.find(item,"HAUTOPROXY") and string.find(item,"true") then
				gotHauto = true
			--	print("Env: "..item);
			end	
		end
	end
	return gotHauto

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


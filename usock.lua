#!/usr/bin/env lua

require "pl"
stringx.import()
socket = require "socket"
socket.unix = require "socket.unix"

unixHttp={}

function unixHttp.request(url)
--c = socket.tcp()
	c = assert(socket.unix());

	assert(c:connect("/var/run/docker.sock"))
	--c:connect("localhost","8080")
--	print("connected!?")

	-- do not indent... header shuold be sent without intends

	require "pl.text".format_operator()
	local request = 
[[
GET %s HTTP/1.1
HOST: localhost

]] % {url}
	
--	print("request:\r\n"..request)
	local header={}

	c:send(request);
	repeat 
		line = c:receive()
		table.insert(header,line);
	until line == ""

--	print(pretty.write(header))
	
	chunked = false
	for i,line in ipairs(header) do
		if (line):lfind("Transfer-Encoding: chunked") then
			chunked = true
		end
	end
	--chunked ? print("chunked") : print("not chunked")
	if (not chunked) then
		local bodySize=(header[5]):split(":")[2]+0
		body = c:receive(bodySize)
--		print(body)
		c:close()
		return header, body
	else
		body=""
		line = c:receive()
		repeat
--			print(line)
			local cnt = tonumber(line,16)
--			print(cnt)
			chunk = c:receive(cnt)
--			print(chunk)
			line = c:receive()
--			print(line)
			body = body..chunk
		until line == ""
		return header, body
	end
end

return unixHTTP

--[[
json = require "json"

print("------")
headers, res=unixHttp.request("/containers/json")
res=json.decode(res)
print(pretty.write(res))
print("------")
headers,res = unixHttp.request("/containers/83ecc0b04bf60f343ebb6a48f7314b5a5c16951fbd0856c8793335c49fa7f30a/json")
res=json.decode(res)
print(pretty.write(res))
]]

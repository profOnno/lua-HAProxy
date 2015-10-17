#!/usr/bin/env lua
require "usock"
if (table.getn(arg) < 1) then
	print("Argument needed, like '/containers/json'")
	os.exit(1)
end

h, b = unixHttp.request(arg[1])
print(b)

#!/usr/bin/env lua

tmpl=[[
<ul>
# for i,val in ipairs(T) do
<li>$(i) = $(val:upper())</li>
# end
</ul>
]]

tmpl2=[[
ik heet $(naam), hoe heet ben jij?
]]

local t = require "pl.template"
print(t.substitute(tmpl2,{naam="menno"}))

ar = {'een','twee','drie'}
for i,val in ipairs(ar) do
	print("val:"..val)
end
print(t.substitute(tmpl,{T = {'one','two','three'},ipairs=ipairs}))
--print(res)

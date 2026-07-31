--
-- Author: sir.huangwei@gmail.com
-- Date: 2014-02-10 14:39:17
--

package.path = package.path .. ";../?.lua"
--print(package.path)
require "extern"
require "luastl/set"
require "print_r"

-----------------------------
-- test
-----------------------------
local function test()
	a = CSet.new()
	b = CSet.new()
	print(a == b)
	print(a == a)

	local tt = {3}
	a:insert(1, "1111")
	a:insert("2", "22")
	a:insert(tt, "333")
	a:print()
	b:insert(1, "1111")
	b:insert("2", "22")
	b:insert(tt, "333")
	print(a == b)
	b:erase(tt)
	b:insert({3}, "333")
	print(a == b)
	b:print()
	print("---")

	print(a:size())
	a:erase(1)
	print(a:size())
	a:erase({3}) -- false erase table
	print(a)
	print(getmetatable(a), getmetatable(a).__cname, getmetatable(a).__tostring)
	print("---")

	local b = {4}
	a:insert(b, "4444")
	print(a)
	print(a:count(b))
	a:erase(b) -- true erase table
	print(a)
	print(a:count(b))

	print("---")
	for k,v in pairs(a) do
		print(k,v)
	end
	print("---")
	for k,v in lua_pairs(a) do
		print(k,v)
	end

	print_r(a)
end


test()

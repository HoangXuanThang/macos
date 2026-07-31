--
-- Author: sir.huangwei@gmail.com
-- Date: 2014-02-10 14:39:17
--
require "test_env"
require "luastl.map"


-----------------------------
-- test
-----------------------------
local function test()
	a = CMap.new()

	a:insert(1, "1111")
	a:insert("2", "22")
	a:insert({3}, "333")
	print(a)
	print(a:size())
	a:erase(1)
	print(a:size())
	a:erase({3}) -- false erase table
	print(a)

	local b = {4}
	a:insert(b, "4444")
	print(a)
	a:erase(b) -- true erase table
	print(a)

	aa = CMap.new()
	aa:insert(1, "111")

	print(CMap.__eq, type(a), type(b), type(aa))
	print ("a==b", a==b)
	print ("a==aa", a==aa)

	print("---pairs---")
	for k,v in pairs(a) do
		print(k,v)
	end
	print("---lua_pairs---")
	for k,v in lua_pairs(a) do
		print(k,v)
	end
	print("---a:pairs---")
	for k,v in a:pairs() do
		print(k,v)
	end
	print("------")

	a:assign({[1]=11,["22"]=222})
	--a:assign("234")
	print(a)
end

print(CMap)
test()

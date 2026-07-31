--
-- Author: sir.huangwei@gmail.com
-- Date: 2014-02-10 11:13:52
--

package.path = package.path .. ";../?.lua;../cocos/?.lua;../scripts/?.lua"
--print(package.path)
require "extern"
require "luastl/vector"


-----------------------------
-- test
-----------------------------
local function test()
	a = CVector.new()
	print(a)
	a:push_back(1)
	a:push_back("22")
	a:push_back(3)
	print(a)
	a:erase(2)
	print(a)
	a:erase(1)
	print(a)
	--a:erase("1")
	a:erase(1)
	print(a)
	a:push_back(1)
	a:push_back("22")
	a:push_back(3)
	print(a)
	print(a:at(0))
	print(a:at(1))
	print(a:at(2))
	print(a:at(3))
	print(a:at(4))
	print(a:at("2"))
	print(a)
	a:push_back(4)
	a:push_back("55")
	a:push_back(6)
	print(a)

	print("slice test -----")
	a:slice(2, 3):print()
	a:slice(-1, 3):print()
	a:slice(-3, 3):print()
	a:slice(-a:size(), 3):print()
	a:slice(-a:size(), 0):print()
	a:slice(-1, -1):print()
	a:slice(1, 6):print()
	a:slice(6, 1):print()
	a:slice(1, 6, -1):print()
	a:slice(3, 4):print()
	a:slice(3, 4, -1):print() --reverse!
	a:slice(3, 3):print()
	a:slice(3, 3, -1):print()
	a:slice(1, 6, 2):print()
	a:slice(6, 1, 2):print() --reverse!
	a:slice(6, 2, 2):print() --reverse!

	print("---~~~")
	--for k,v in pairs(a:slice(6, 2, 2)) do
	--	print(k,v)
	--end
	print("---~~~")
	for k,v in ipairs(a:slice(6, 2, 2)) do
		print(k,v)
	end
	print("---~~~")
end

print(CVector)
test()
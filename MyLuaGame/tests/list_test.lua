--
-- Author: sir.huangwei@gmail.com
-- Date: 2018-09-17 11:13:52
--

package.path = package.path .. ";../?.lua;../cocos/?.lua;../src/?.lua"
--print(package.path)
-- require "cocos_init"
globals = _G
require "cocos/cocos2d/functions"
require "luastl/list"
require "util/helper"


-----------------------------
-- test
-----------------------------
local function test()
	a = CList.new()
	a:push_back(1)
	a:push_back("22")
	a:push_back(3)
	print(dump(a))
	a:erase(2)
	print(dump(a))
	a:erase(1)
	print(dump(a))
	--a:erase("1")
	a:erase(1)
	print(dump(a))
	a:push_back(1)
	a:push_front("22")
	a:push_back(33)
	a:push_front(4)
	a:push_back("55")
	a:push_front(6)
	print(dump(a))

	print("---~~~")
	for k,v in a:pairs() do
		print(k,v)
	end
	print("---~~~")
end

print(CList)
test()
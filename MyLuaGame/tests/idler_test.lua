
package.path = package.path .. ";../?.lua;../cocos/?.lua;../src/?.lua"

globals = _G
DEBUG = 99

-- require "cocos_init"

require "cocos2d.functions"

require "util.print_r"
require "util.itertools"
require "util.arraytools"
require "easy.idler"
require "easy.idlercomputer"


local ia = idler.new(1)
local ib = idler.new(2)

local ic1 = idlereasy.when(ia, function (self, val)
	print('compute when ic1', val)
	return true, 10 + val
end)

local ic2 = idlereasy.any({ia, ib}, function (self, vala, valb)
	print('compute any ic2', vala, valb)
	return true, 10 + vala + valb
end)

local ic3 = idlereasy.when(ic2, function (self, val)
	print('compute when ic3', val)
	return true, val >= 15
end)

local ic4 = idlereasy.select({ia, ib}, {ib}, function (self, vala, valb)
	print('compute select ic4', vala, valb)
	return true, vala + valb
end)

local if1 = idlereasy.if_(ic3, function (self, val)
	print('compute if1', val)
end)

local if2 = idlereasy.if_not(ic3, function (self, val)
	print('compute if2', val)
end)

local ifall = idlereasy.if_all({ic1, ic3}, function (self, val1, val3)
	print('compute ifall', val1, val3)
end)

local ifany = idlereasy.if_any({ic1, ic3}, function (self, val1, val3)
	print('compute ifany', val1, val3)
end)

print('ia', ia:get_())
print('ib', ib:get_())
print('ic1', ic1:get_())
print('ic2', ic2:get_())
print('ic3', ic3:get_())
print('ic4', ic4:get_())
print('ifall', ifall:get_())
print('ifany', ifany:get_())

print('ia:set(3)', ia:set(3))
print('ic1', ic1:get_())
print('ic2', ic2:get_())
print('ic3', ic3:get_())
print('ic4', ic4:get_())
-- print('ic1:set(1)', ic1:set(1)) -- error, idlercomputer no set


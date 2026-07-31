
package.path = package.path .. ";../?.lua;../cocos/?.lua;../src/?.lua"

globals = _G
DEBUG = 99

-- require "cocos_init"

require "cocos2d.functions"

require "util.print_r"
require "util.itertools"
require "util.arraytools"
require "easy.table"
require "easy.idler"
require "easy.idlercomputer"

local t = {x=1, [2]=2, hello={1,2,3}}
-- local itable2 = idler.new(t)
local itable = idlertable.new(t)
print('t', t)
print('itable', itable)
print('itable:get_()', itable:get_())
print('itable:proxy()', itable:proxy())
print('itable:proxy():idler()', itable:proxy():idler())
itable:addListener(function (val, oldval, idler)
	print('on changed 111', val, oldval, idler)
	print_r(val)
end)

local itable = itable:proxy()
print(type(itable))
print_r(itable)

print('========= change value, no changed log')

t.x = 10

print('========= change value, print changed log')

print('itable.x', itable.x)
itable.x = 11

print('=========')

itable[2] = 22

print('=========')

itable[3] = 33
itable.z = 'zzzz'

print('========= set nil, delete')

itable.z = nil

print('========= nest table')

itable.hello[4] = 4

print_r(t)
print('itable.x', itable.x)
assert(itable.x == t.x, 'x not same')

print('1 itable:idler()', itable:idler())
print('2 itable:idler()', itable:idler())
assert(itable:idler() == itable:idler(), 'idler not same')

print('itable.hello:idler()', itable.hello:idler())
assert(itable.hello:idler() == nil, 'nest idler is not nil')

print('========= nest idlertable')

assert(itable.hello()==t.hello, 'proxy contain table which not same')

helloidler = idlertable.new(itable.hello())
helloidler2 = idlertable.new(t.hello)
helloidler:addListener(function (val, oldval, idler)
	print('on changed [helloidler]', val, oldval, idler)
	print_r(val)
end)


print('=== t111')
print_r(t)
print(t.hello)

-- itable.hello = helloidler:proxy()
itable.hello = helloidler:proxy()()
-- itable.hello2 = {'hehehehehe'}

print('=== t222')
print_r(t)
print(t.hello)

print('========= nest table, only 111 changed log')

itable.hello[5] = 333333


print('========= helloidler, only [helloidler] changed log')

local hello = helloidler:proxy()
hello[6] = 4444
print_r(t)

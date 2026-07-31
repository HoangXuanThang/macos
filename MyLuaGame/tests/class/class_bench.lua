require "test_env"

require "util.print_r"
ProFi = require "util.ProFi"

---------------
CC1 = class("CC1")

function CC1:ctor()
	self.a = 1
end


local N = 500000

ProFi:start()
local t = {a = 1}
local function test1()
	for i = 1, N do
		local a = t.a
		-- local b = t.b
		-- t.c = 3
	end
end
test1()
ProFi:stop()
ProFi:writeReport('class_bench1.txt')

ProFi:reset()

ProFi:start()
local obj = CC1.new()
local function test2()
	for i = 1, N do
		local a = obj.a
		-- local b = obj.b
		-- obj.c = 3
	end
end
test2()
ProFi:stop()
ProFi:writeReport('class_bench2.txt')
require "test_env"

require "util.print_r"

---------------
CC1 = class("CC1")

CC1.cc1_static = "class_var"
function CC1:ctor( ... )
	print("CC1:ctor")
	self.cc1 = "obj_var1"
end

function CC1:test( ... )
	print("CC1:test")
end

function CC1:test2( ... )
	print("CC1:test2")
end

function CC1:test4( ... )
	print("CC1:test4")
end

function CC1:__tostring()
	print ("CC1:__tostring")
	cclogWarn("!!")
	return "CC1:__tostring return " .. self.__cid
end

--------------
CC2 = class("CC2", CC1)

function CC2:ctor( ... )
	print("CC2:ctor")
	self.cc2 = "obj_var2"
	print(self.cc2)
end

function CC2:__setter(k, v)
	print("CC2:__setter", self, self.__class, self.__cname, k, v)
end

function CC2:test( ... )
	print("CC2:test")
	super(...)
end

function CC2:test3( ... )
	print("CC2:test3")
	print("member function is virtual")
	self:test()
	print("use super")
	superFunc("test", ...)
	print("class function")
	CC2.test(self)
	print("super class function")
	CC1.test(self)

end

function CC2:setvar_test()
	print("prepare assign", self, self.__class, self.__cname)
	print(self.cc2)
	self.cc2 = "CC2:test3"
	self.cc2_new = "CC2:test3 new"
	self.cc2_new = "CC2:test3 new2"
end
----------------
CC3 = class("CC3", CC2)

function CC3:ctor( ... )
	print("CC3:ctor")
	self.cc3 = "obj_var3"
end

function CC3:test( ... )
	print("CC3:test")
	superFunc("test", ...)
end

function CC3:test2( ... )
	print("CC3:test2")
	super(...)
end

function CC3:test3( aa )
	print("CC3:test3", aa, self)
	super(aa)
	--CC2.test3(self, aa)
	print("return", self.cc2, self.cc2_new)
end

---------------
CCT1 = class("CCT1")

---------------------
print("---test derived class ctor---")
local a = CC3.new()
print("---1---")
a:test()
print("---2---")
a:test2()
print("---3---")
a:test3(123)
print("---4---")
a:test4()
print("---setvar_test---")
a:setvar_test()
print("---class function test---")
CC3:test3()
print(a, CC3)

print("===============")
print("---string test1---")
print(a:__tostring())
print("---string test2---")
print(tostring(a))
print("---string test3---")
print(a)
print("---string test4---")
print(CCT1.new())

print(a.cc1, a["cc1"], rawget(a, "cc1"))
print(a.cc1_static, a["cc1_static"], rawget(a, "cc1_static"))
print(CC1.cc1_static, CC1["cc1_static"], rawget(CC1, "cc1_static"))
print(CC3.cc1_static, CC3["cc1_static"], rawget(CC3, "cc1_static"))
print(a.test, a["test"], rawget(a, "test"))
print(a.__class.test, a.__class["test"], rawget(a.__class, "test"))
print(a.test4, a["test4"], rawget(a, "test4"))
print(a.__class.test4, a.__class["test4"], rawget(a.__class, "test4"))

print("===============")
print_r(a)

print("===============")
if _vtbl then
	for k,v in pairs(_vtbl) do
		print(k, v.name, v.cls.__cname)
	end
end

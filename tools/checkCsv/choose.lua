require "list"
-- local luaiconv = require "luaiconv"
print("please choose checking method:")
print("", 0, "all", "check all")
for i,v in ipairs(checkMethod) do
	print("", i, v[1], v[2])
end
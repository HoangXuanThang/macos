print('!!!!! hello', gRootViewProxy)
local s = ""
for k, v in pairs(gRootViewProxy) do
	s = s .. string.format("%s=%s\n", k, v)
end
return "show it in game\n" .. s
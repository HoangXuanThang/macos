package.path = package.path .. ";../cocos/?.lua;../scripts/?.lua"
require "extern"
require "util.print_r"
require "luastl.map"

csv = {}
csv['stage'] = {
	[1] = {
		name = 'test',
		bkground = 'csv.stage.test_bk',
		terrian = 'csv.stage.test_tr',
		width = 1136,
		height = 640,
		x = 0,
		y = 0
	},
	[3] = {
		name = 'test',
		bkground = 'csv.stage.test_bk',
		terrian = 'csv.stage.test_tr',
		width = 1136,
		height = 640,
		x = 0,
		y = 0
	},
	__size = 2
}

function csvPairs(t)
	return function (t, idx)
		nk, nv = next(t, idx)
		while nk ~= nil and type(nk) ~= "number" do
			nk, nv = next(t, nk)
		end
		return nk, nv
	end, t, nil
end

print("pairs--------")

for k,v in pairs(csv.stage) do
	print (k,v)
end

print("next--------")

print(next(csv.stage))
print(next(csv.stage,1))
print(next(csv.stage,"__size"))
print(next(csv.stage,3))

print("csvPairs1--------")
for k,v in csvPairs(csv.stage) do
	print (k,v)
end
print("csvPairs2--------")
for k,v in csvPairs(csv.stage) do
	print (k,v)
end
print("csvPairs3--------")
for k,v in csvPairs(csv.stage[1]) do
	print (k,v)
end
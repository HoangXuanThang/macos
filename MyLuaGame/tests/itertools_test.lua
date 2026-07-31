
local itertools = require "util.itertools"


local a, b = {}, {}
for i=1, 10 do
	a[i] = i*100
	b['k'..i] = 'v'..i
end

print(#itertools.keys(b), itertools.keys(b)[2])
print(#itertools.values(b), itertools.values(b)[2])

print('---size---')
print('a=',itertools.size(itertools.keys(a)))
print('a=',itertools.size(itertools.ikeys(a)))
print('b=',itertools.size(itertools.keys(b)))
print('b=',itertools.size(itertools.ikeys(b)))

print('---chain size---')
print('a+b=',itertools.size(itertools.chain(itertools.keys(a), itertools.keys(b))))
print('a+b=',itertools.size(itertools.chain(itertools.ikeys(a), itertools.ikeys(b))))

print('---ikeys1---')
cnt = 0
for k, v in itertools.ikeys(a) do
	print('a=', k, v)
	cnt = cnt + 1
end
print('cnt', cnt)

print('---ikeys2---')
cnt = 0
for k, v in itertools.ikeys(b) do
	print('b=', k, v)
	cnt = cnt + 1
end
print('cnt', cnt)

print('---ivalues1---')
cnt = 0
for k, v in itertools.ivalues(a) do
	print('a=', k, v)
	cnt = cnt + 1
end
print('cnt', cnt)

print('---ivalues2---')
cnt = 0
for k, v in itertools.ivalues(b) do
	print('b=', k, v)
	cnt = cnt + 1
end
print('cnt', cnt)

print('---iitems1---')
cnt = 0
for k, v in itertools.iitems(a) do
	print('a=', k, v, v[1], v[2])
	cnt = cnt + 1
end
print('cnt', cnt)

print('---iitems2---')
cnt = 0
for k, v in itertools.iitems(b) do
	print('b=', k, v, v[1], v[2])
	cnt = cnt + 1
end
print('cnt', cnt)

print('---minmax---')
print(itertools.min(a))
print(itertools.max(a))

print('---minmaxkv---')
print(itertools.min(itertools.keys(a)))
print(itertools.max(itertools.keys(a)))
print(itertools.min(itertools.values(a)))
print(itertools.max(itertools.values(a)))

print('---minmaxikv---')
print(itertools.min(itertools.ikeys(a)))
print(itertools.max(itertools.ikeys(a)))
print(itertools.min(itertools.ivalues(a)))
print(itertools.max(itertools.ivalues(a)))
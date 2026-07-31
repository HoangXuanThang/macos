
-----------------------------
-- HTTP GET

local _zlib = require('3rd.zlib2')
local zuncompress = _zlib.uncompress

function sendHttpRequest(reqType, reqUrl, reqBody, resType, cb)
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = resType
	-- xhr.timeout = 5
	xhr:open(reqType, reqUrl)
	if reqType == 'GET' then
		xhr:setRequestHeader("Accept-Encoding", "gzip")
	end
	local function _onReadyStateChange(...)
		local encode = string.match(xhr:getAllResponseHeaders(), "Content%-Encoding:%s*(gzip)")
		if encode == 'gzip' then
			xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_BLOB
			xhr.response = zuncompress(xhr.response)
		end
		cb(xhr)
	end
	if cb then xhr:registerScriptHandler(_onReadyStateChange) end
	if reqBody then xhr:send(reqBody)
	else xhr:send() end
end

function doGET(reqUrl, cb)
	print('doGET', reqUrl)
	return sendHttpRequest("GET", reqUrl, nil, cc.XMLHTTPREQUEST_RESPONSE_BLOB, function(xhr)
		if xhr.status == 200 then
			cb(xhr.response)
		else
			if #xhr.response > 0 then
				cb(xhr.response)
			else
				print('err %s %s', xhr.status, xhr.statusText)
				cb(nil, xhr.statusText)
			end
		end
	end)
end
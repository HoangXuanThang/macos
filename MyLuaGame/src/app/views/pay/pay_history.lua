local PayHistory = PayHistory or {};
local instance = nil;
local TAG = "PayHistory";
local TLOG = function(msg)
    print(TAG, msg, "TLOG");

end
function PayHistory:getMe()
    if not instance then
        instance = self:ctor()
    end

    return instance;
end
function PayHistory:ctor()

    self:Init();
    
    return self
end
function PayHistory:Init()
    self.currentUser = "";
    self.Data = {};	
    self.Money = 0
    --self:SyncData();
end

function PayHistory:PostInformation()
    print("PayHistory PostInformation");
end



function  PayHistory:setCurrentUser(userId)
	self.currentUser = userId;	
end
function PayHistory:SyncData(userName,callback)
	  
	-- if (self.currentUser == nil or self.currentUser=="") then
    --     self.currentUser = userDefault.getForeverLocalKey("account", nil, {rawKey = true})
    --     if(self.currentUser == "") then
    --         self.currentUser = userDefault.getForeverLocalKey("accountQuick", nil, {rawKey = true})
    --     end
	-- 	-- return;
	-- end
    self.currentUser = userName
    if (self.currentUser == nil or self.currentUser=="") then
        
		return;
	end

    local params = string.format("account=%s&",self.currentUser);
    print("param", params)
    gGameApp.net:sendHttpRequest("POST",CARD_HISTORY_CFG, params,
        cc.XMLHTTPREQUEST_RESPONSE_STRING, function(xhr)
            
            if xhr.status == 200 then
                local res = json.decode(xhr.response)
                if (res.code == 0) then
                    print("request okay")
                    self.Data = res.message
                    self.Money = res.money
                   
                    if (callback~=nil) then  
                        callback(true,res.message,res.money)
                    end
                    
                else
                    print("request okay but not true response")
					self.Data = {};
                    if (callback~=nil) then  
                        callback(false,{},0)
                    end
                end
            else
                print("request not okay")
				self.Data = {};
                if (callback~=nil) then  
                    callback(false,{},0)
                end
            end
        end)

   

end
function PayHistory:GetHistory()
   
    return self.Data,self.Money;
end
return PayHistory;

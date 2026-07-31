local StarSwapReceiveBoxView = class("StarSwapReceiveBoxView", Dialog)
StarSwapReceiveBoxView.RESOURCE_FILENAME = "receive_prompt_box.json"
StarSwapReceiveBoxView.RESOURCE_BINDING = {
	["content.list"] = "contentList",
	["content.tipText"] = "tipText",
	["content.count"] = "contentCount",
	content = "content",
	closeBtn = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	btnOkCenter = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onReceive")
			}
		}
	},
	["btnOkCenter.title"] = {
		binds = {
			event = "effect",
			data = {
				outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 }
			}
		}
	}
}

function StarSwapReceiveBoxView:onCreate(params)
	self.count = params.count

	idlereasy.when(self.count, function(_, count)
		if count <= 0 then
			return
		end

		self:getReceiveData()
		self.contentCount:text(count)
		adapt.oneLinePos(self.tipText, self.count, cc.p(10, 0))
		self:refreshView()
	end)
	Dialog.onCreate(self)
end

function StarSwapReceiveBoxView:getReceiveData()
	local data = {}
	local realTime = time.getTime()
	local createTime = gGameModel.role:read("created_time")
	local deliverRecord = gGameModel.role:read("card_star_swap_times_deliver_record")

	for id, v in orderCsvPairs(csv.card_star_swap_times_deliver) do
		if not deliverRecord or not deliverRecord[id] then
			local hour, min = time.getHourAndMin(v.time)
			local effectTime = time.getNumTimestamp(v.date, hour, min)
			local endTime = time.getNumTimestamp(v.endDate, hour, min)
			local vipLevel = gGameModel.role:read("vip_level")
			local roleLevel = gGameModel.role:read("level")

			if v.type == 3 then
				local startRoleTime = time.getNumTimestamp(v.validRoleCreatedEarliestDate)
				local endRoleTime = time.getNumTimestamp(v.validRoleCreatedLatestDate)

				if v.param <= roleLevel and effectTime <= realTime and realTime <= endTime and createTime <= endRoleTime and startRoleTime <= createTime then
					table.insert(data, {
						id = id,
						startTime = v.date,
						endTime = v.endDate,
						type = v.type,
						value = v.param,
						award = v.starSwapTimes
					})
				end
			elseif v.type == 2 then
				if v.param <= roleLevel and effectTime <= realTime and realTime <= endTime then
					table.insert(data, {
						id = id,
						startTime = v.date,
						endTime = v.endDate,
						type = v.type,
						value = v.param,
						award = v.starSwapTimes
					})
				end
			elseif v.type == 1 and v.param <= vipLevel and effectTime <= realTime and realTime <= endTime then
				table.insert(data, {
					id = id,
					startTime = v.date,
					endTime = v.endDate,
					type = v.type,
					value = v.param,
					award = v.starSwapTimes
				})
			end
		end
	end

	table.sort(data, function(a, b)
		return a.id < b.id
	end)

	self.receiveData = data
end

function StarSwapReceiveBoxView:refreshView()
	local curData = self.receiveData[1]
	local text = ""
	-- local startDay = string.format(gLanguageCsv.yearMonthDay, time.getYearMonthDay(curData.startTime))
	-- local endDay = string.format(gLanguageCsv.yearMonthDay, time.getYearMonthDay(curData.endTime))

	if curData.type == 2 or curData.type == 3 then
		text = string.format(gLanguageCsv.starReceive1, curData.value)
	elseif curData.type == 1 then
		text = string.format(gLanguageCsv.starReceive2, uiEasy.getVipStr(curData.value).str)
	end

	local content = self.content

	content:removeChildByName("richText")

	content = rich.createWithWidth(text, 44, nil, 850)
	content = content:addTo(self.content)
	content = content:xy(400, 290)

	content:name("richText")
	uiEasy.createItemsToList(self, self.contentList, curData.award, {
		margin = 20,
		scale = 0.9,
		onAfterBuild = function(list)
			list:setItemAlignCenter()
		end
	})
end

function StarSwapReceiveBoxView:onReceive()
	local curData = self.receiveData[1]

	gGameApp:requestServer("/game/role/card_star_swap/times/get", function(tb)
		if self.count:read() <= 0 then
			self:addCallbackOnExit(function()
				gGameUI:showGainDisplay(tb)
			end)
			self:onClose()
		else
			gGameUI:showGainDisplay(tb)
		end
	end, curData.id)
end

function StarSwapReceiveBoxView:onClose()
	Dialog.onClose(self)
end

return StarSwapReceiveBoxView




local ActivityChristmasAward = class("ActivityChristmasAward", Dialog)

ActivityChristmasAward.RESOURCE_FILENAME = "activity_christmas_award.json"
ActivityChristmasAward.RESOURCE_BINDING = {
    ["btnClose"] = {
		binds = {
			event = "touch",
			methods = { ended = bindHelper.self("onClose") }
		},
	},
    ["item"] = "item",
    ["proVal"] = "proVal",
    ["list"] = {
        varname = "awardList",
        binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("boxAwards"),
				item = bindHelper.self("item"),
				totalDrawNum = bindHelper.self("totalDrawNum"),
				itemAction = {isAction = true},
                dataOrderCmp = function(a, b)
					if a.state ~= b.state then
						return a.state > b.state
					end
					return a.csvId < b.csvId
				end,
				onItem = function(list, node, k, v)
                    local childs = node:multiget("num", "txt1", "txt2", "list", "btnGet", "bg")
					
                    local cfg = csv.draw_count[v.csvId]
                    childs.num:text(cfg.count)

                    local grayState = 1
                    if list.totalDrawNum < cfg.count then
                        -- 未完成
                        grayState = 2
                        childs.btnGet:get("txt"):text(gLanguageCsv.notReach)

                        cache.setShader( childs.btnGet, false, "hsl_gray")
						text.deleteAllEffect( childs.btnGet:get("txt"))
						text.addEffect( childs.btnGet:get("txt"), {color = ui.COLORS.DISABLED.WHITE})
                    else
                        -- 完成
                        if v.state == 1 then
                            cache.setShader( childs.btnGet, false, "normal")
                            childs.btnGet:setTouchEnabled(true)
                            bind.click(list, childs.btnGet, { method = functools.partial(list.clickItem, k, v) })
                            childs.btnGet:get("txt"):text(gLanguageCsv.commonTextGet)
                            text.addEffect(childs.btnGet:get("txt"), {color = ui.COLORS.NORMAL.WHITE,outline = {color = ui.NEWCOLORS.OUTLINE.YELLOW,  size = 4}})
                        else
                            childs.btnGet:get("txt"):text(gLanguageCsv.received)
                            cache.setShader( childs.btnGet, false, "hsl_gray")
                            text.deleteAllEffect( childs.btnGet:get("txt"))
                            text.addEffect( childs.btnGet:get("txt"), {color = ui.COLORS.DISABLED.WHITE})
                        end
                    end

                    uiEasy.createItemsToList(list, childs.list, cfg.award, {scale = 0.9, margin = 50})

                    text.addEffect(childs.txt1, {
                        outline = { color = ui.COLORS.BLACK, size = 4 } 
                    })

                    text.addEffect(childs.num, {
                        outline = { color = ui.COLORS.BLACK, size = 4 } 
                    })

                    text.addEffect(childs.txt2, {
                        outline = { color = ui.COLORS.BLACK, size = 4 } 
                    })
                   
				end,
			},
			handlers = {
				clickItem = bindHelper.self("onBoxAwardClick"),
			},
		},
    }

}


function ActivityChristmasAward:onCreate(activityId)
    self.activityId = activityId
    local yyCfg = csv.yunying.yyhuodong[activityId]

    self:initModel()

    self.boxAwards = idlers.newWithMap({})

    local yydata = self.yyhuodongs[activityId] or {}
    local info = yydata.info or {}
    self.totalDrawNum = info.limit_counter_all or 0
    self.proVal:text(string.format("祈愿次数: %s", self.totalDrawNum))

    idlereasy.any({self.getDiamondAwardState}, function(_, awardState)
        local awards = {}
        local boxSate = awardState[game.DRAW_BOX_TYPE.CHRISTMAS] or {}
        for k, v in orderCsvPairs(csv.draw_count) do
            if v.huodongID == self.activityId then
                awards[k] = {
                    csvId = k,
                    state = boxSate[k] or 1,
                }
            end
        end
        dataEasy.tryCallFunc(self.awardList, "updatePreloadCenterIndex")
        self.boxAwards:update(awards)
    end)

    Dialog.onCreate(self, {blackType = 1})

end

function ActivityChristmasAward:initModel()
	self.yyhuodongs = gGameModel.role:read("yyhuodongs")
    self.getDiamondAwardState = gGameModel.role:getIdler("draw_sum_box") --钻石宝箱领取状态(1可领取，2已领取)
end

-- 宝箱领取
function ActivityChristmasAward:onBoxAwardClick(_, id, v)
    local yyId = self.activityId
    local boxState = self.boxAwards:at(id):read().state

    local cfg = csv.draw_count[v.csvId]
    if self.totalDrawNum < cfg.count then
        return
    end

	if boxState == 1 then
		gGameApp:requestServer("/game/lottery/yy/draw/box/get", function(cb)
			gGameUI:showGainDisplay(csv.draw_count[id].award, {
				raw = false,
				cb = function()
					-- self.downPanel:get("item" .. (idx + 1)):get("result"):visible(false)
					-- self:initAward()
				end
			})
		end, yyId, id)
		return
	end
end

return ActivityChristmasAward
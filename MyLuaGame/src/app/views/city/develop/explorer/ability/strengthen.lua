-- 神器 注灵
local ExplorerAbilityStrengthenView = class("ExplorerAbilityStrengthenView", Dialog)

--技能描述
local function getSkillStr(str, level, maxLevel)
    local list = string.split(str, "$")
    local desc = ""
    for i, v in pairs(list) do
        local s = v
        local pos = string.find(s, "skillLevel")
        if pos then
            local symbol = ""
            if list[i + 1] and string.find(list[i + 1], "^%%") then
                symbol = "%"
                list[i + 1] = string.gsub(list[i + 1], "^%%", "")
            end
            local num = eval.doFormula(v, { skillLevel = level, math = math })
            if level == 0 then
                num = 0
            end
            local nextNum = eval.doFormula(v, { skillLevel = level + 1, math = math })
            s = num .. symbol
            local nextStr = (nextNum - num) .. symbol
            if tonumber(num) < tonumber(nextNum) and level < maxLevel then
                s = string.format(gLanguageCsv.abilitySkillAddDesc, s, nextStr)
            end
            s = "#C0x01A001#+" .. s .. "#C0x5B545B#"
        end
        desc = desc .. s
    end
    return desc
end


ExplorerAbilityStrengthenView.RESOURCE_FILENAME = "explore_ability_strengthen.json"
ExplorerAbilityStrengthenView.RESOURCE_BINDING = {
    ["frame.btnClose"] = {
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onClose") }
        },
    },
    ["frame.title"] = {
        varname = "title",
        binds = {
            event = "effect",
            data = ui.TITLE_STYLE_1
        },
    },
    ["panel.skill"] = "skill",
    ["panel.level"] = "skillLv",
    ["panel.infoPanel"] = "infoPanel",
    ["panel.infoPanel.title"] = "levelTitle",
    ["panel.infoPanel.itemAttr"] = "itemAttr",
    ["panel.infoPanel.descs"] = "descs",
    ["panel.list"] = "list",
    ["panel.tips"] = "tips",
    ["panel.btnSure"] = {
        varname = "btnSure",
        binds = {
            event = "touch",
            methods = { ended = bindHelper.self("onStrengthenClick") }
        },
    },
}

function ExplorerAbilityStrengthenView:onCreate(params, cb)
    self.expID = params.expID
    self.abilityId = params.id
    self.cb = cb

    self:initModel()

    idlereasy.any({ self.explorers, self.items, self.gold }, function(_, explorers, items, gold)
        local abilities = explorers[self.expID].abilities or {}
        local abilityCsv = csv.explorer.ability[self.abilityId]
        local levelMax = abilityCsv.levelMax
        local name = abilityCsv["name_"..LOCAL_LANGUAGE] or abilityCsv.name
        if abilityCsv.effectType == 2 then
            self.title:text(name)
        else
            self.title:text(name .. gLanguageCsv.equipStrengthen)
        end

        local level = abilities[abilityCsv.position] or 0

        self.skill:get("icon"):texture(abilityCsv.icon)
        self.skillLv:text(string.format("Lv. %s/%s", level, levelMax))

        local isMax = level >= levelMax

        self.levelTitle:get("level"):text(string.format("Lv.%s", level))
        if isMax then
            self.levelTitle:get("arrow"):hide()
            self.levelTitle:get("next"):hide()
        else
            self.levelTitle:get("next"):text(string.format("Lv.%s", level + 1))
        end

        itertools.invoke({ self.itemAttr, self.descs }, "hide")

        if abilityCsv.effectType == 2 then
            self.skill:get("top"):scale(1.7)
            self.descs:show()
            local desc = getSkillStr(csv.skill[abilityCsv.skillID].describe, level, abilityCsv.levelMax)
            beauty.textScroll({
                list = self.descs,
                strs = "#C0x5B545B#" .. desc,
                isRich = true,
                align = "left",
                fontSize = 36,
            })
        else
            self.itemAttr:show()
            local str = getLanguageAttr(abilityCsv.attrType1)
            local val = dataEasy.getAttrValueString(abilityCsv.attrType1, abilityCsv.attrNum1[level] or "0%")
            self.itemAttr:get("txtNod"):text(str)
            self.itemAttr:get("txt"):text(val)

            if isMax then
                self.itemAttr:get("arrow"):hide()
                self.itemAttr:get("next"):hide()
            else
                local nxtVal = dataEasy.getAttrValueString(abilityCsv.attrType1, abilityCsv.attrNum1[level + 1] or 0)
                self.itemAttr:get("next"):text(nxtVal)
            end
        end

        local canStrengthen = 1
        for k, preID in orderCsvPairs(abilityCsv.preID) do
            local preLv = abilities[preID] or 0
            if preLv < 1 then
                canStrengthen = 2
                break
            end
        end

        self.tips:visible(canStrengthen == 2)

        uiEasy.setBtnShader(self.btnSure, self.btnSure:get("txt"), isMax and 2 or canStrengthen)

        if isMax then
            self.list:hide()
            self.btnSure:get("txt"):text(gLanguageCsv.levelMax)
        else
            local costDatas = {}
            for k, v in csvMapPairs(abilityCsv.seqCost) do
                local ownNum = items[k]
                if k == "gold" then
                    ownNum = gold
                end
                table.insert(costDatas, { key = k, num = ownNum, targetNum = v, id = k })
            end

            uiEasy.createItemsToList(self, self.list, costDatas, {
                scale = 0.8,
                margin = 10,
                onAfterBuild = function()
                    self.list:setItemAlignCenter()
                end
            })
        end
        text.addEffect(self.btnSure:get("txt"), { outline = { color = ui.NEWCOLORS.OUTLINE.YELLOW, size = 4 } })
    end)

    Dialog.onCreate(self, { blackType = 1 })
end

function ExplorerAbilityStrengthenView:initModel()
    self.gold = gGameModel.role:getIdler("gold")
    self.items = gGameModel.role:getIdler("items")
    self.explorers = gGameModel.role:getIdler("explorers")
end

function ExplorerAbilityStrengthenView:onClose()
    self:addCallbackOnExit(self.cb)

    Dialog.onClose(self)
end

function ExplorerAbilityStrengthenView:onStrengthenClick()
    local abilityCsv = csv.explorer.ability[self.abilityId]
    for k, v in csvMapPairs(abilityCsv.seqCost) do
        local ownCount = dataEasy.getNumByKey(k)
        if ownCount < v then
            gGameUI:showTip(gLanguageCsv.materialsNotEnough)
            return
        end
    end

    gGameApp:requestServer("/game/explorer/ability/strength", function(tb)

    end, self.expID, abilityCsv.position)
end

return ExplorerAbilityStrengthenView

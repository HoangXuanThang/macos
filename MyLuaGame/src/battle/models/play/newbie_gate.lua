--
-- 新手战斗关卡
--

-- 特殊指定操作数据
local FIX_OPERATOR_DATA = {
	[1] = {
		[1] = {
			fixSpeedrank = true,                 -- 固定行动顺序，否则正常按速度执行
			speedrank = { 8, 7, 9, 10, 11, 12, 6, 2, 4 }, --1, 3, 8, 9, 5, 6, 10, 11,1, 2, 3, 7, 8, 9, 4, 5, 6, 10, 11, 12
			input = {
				[2] = {
					targetId = 8,
					skillId = 3332,
				},
				[7] = {
					targetId = 2,
					skillId = 35432,
				},
				[8] = {
					targetId = 2,
					skillId = 19312,
				},
				[9] = {
					targetId = 2,
					skillId = 132,
				},
				[4] = {
					targetId = 8,
					skillId = 22422,
				},
				[6] = {
					targetId = 8,
					skillId = 33532,
				},
				[10] = {
					targetId = 2,
					skillId = 5932,
				},
				[11] = {
					targetId = 2,
					skillId = 20732,
				},
				[12] = {
					targetId = 2,
					skillId = 36832,
				},
			},
		},
		[2] = {
			fixSpeedrank = true,       -- 固定行动顺序，否则正常按速度执行
			speedrank = { 8, 7, 9, 10, 11, 6 }, --
			input = {
				[6] = {
					targetId = 9,
					skillId = 333533,
				},
				[12] = {
					targetId = 2,
					skillId = 36833,
				},
				[8] = {
					targetId = 2,
					skillId = 19313,
				},
				[7] = {
					targetId = 2,
					skillId = 35433,
				},
				[9] = {
					targetId = 2,
					skillId = 133,
				},
				[10] = {
					targetId = 2,
					skillId = 5933,
				},
				[11] = {
					targetId = 2,
					skillId = 20733,
				},
			},
		},
		[3] = {
			fixSpeedrank = true, -- 固定行动顺序，否则正常按速度执行
			speedrank = { 2, 6 },
			input = {
				[2] = {
					targetId = 11,
					skillId = 3333,
				},
				[6] = {
					targetId = 11,
					skillId = 333533,
				},
			},
		}
	}
}

local NewbieGate = class("NewbieGate", battlePlay.Gate)
battlePlay.NewbieGate = NewbieGate

-- 战斗模式设置 手动
NewbieGate.OperatorArgs = {
	isAuto       = false,
	isFullManual = false,
	canHandle    = true,
	canPause     = false,
	canSpeedAni  = false,
	canSkip      = false,
}

function NewbieGate:ctor(scene)
	battlePlay.Gate.ctor(self, scene)

	if APP_CHANNEL == "none" or APP_CHANNEL == "luo" or dataEasy.isSkipNewbieBattle() then
		self.OperatorArgs = clone(NewbieGate.OperatorArgs)
		self.OperatorArgs.canSkip = true
	end

	self.fixOperatorData = {}
end

function NewbieGate:getSortOrderTb()
	if self.fixOperatorData.speedrank then
		return self.fixOperatorData.speedrank
	end
	return battlePlay.Gate.getSortOrderTb(self)
end

function NewbieGate:newWaveAddObjsStrategy()
	self:addCardRoles(1)
	self:addCardRoles(2)
	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

-- 不显示波次效果
function NewbieGate:onNewWavePlayAni()
	self.curWave = self.curWave + 1 -- 波数增加
	self.curRound = 0            -- 回合数重置
	self.totalRoundBattleTurn = 0
	-- wave的波数设置
	gRootViewProxy:notify('setWaveNumber', self.curWave, self.waveCount)
	battleEasy.queueEffect('delay', { lifetime = 300 }) -- 稍微短一点
	self.scene:waitNewWaveAniDone()
end

function NewbieGate:onNewRound()
	if FIX_OPERATOR_DATA[self.curWave] then
		self.fixOperatorData = FIX_OPERATOR_DATA[self.curWave][self.curRound + 1] or {}
	else
		self.fixOperatorData = {}
	end
	battlePlay.Gate.onNewRound(self)
end

function NewbieGate:speedRankSort()
	if self.fixOperatorData.fixSpeedrank then
		-- 获取存活对象
		local tobeDel = {}
		local hash = arraytools.hash(self.fixOperatorData.speedrank, true)
		local curLefts = itertools.filter(self.roundLeftHeros, function(id, data)
			local obj = data.obj
			if not obj or obj:isRealDeath() or not hash[obj.seat] then
				table.insert(tobeDel, id)
				return nil
			end
			return data
		end)
		for i = table.length(tobeDel), 1, -1 do
			table.remove(self.roundLeftHeros, tobeDel[i])
		end
		table.sort(curLefts, function(data1, data2)
			local obj1, obj2 = data1.obj, data2.obj
			return hash[obj1.seat] < hash[obj2.seat]
		end)
		local objTb = {}
		for _, data in ipairs(curLefts) do
			table.insert(objTb, data.obj)
		end
		local firstData = curLefts[1]
		self:setLeftHerosIndex(firstData)
		-- 这个顺序里面包含了能行动的和不能行动的, 不包含那些已经行动过了的
		self.attackerArray = objTb
		return true
	else
		return battlePlay.Gate.speedRankSort(self)
	end
end

function NewbieGate:triggerAllPassiveSkills()
	self.scene:onAllPassive(battle.PassiveSkillTypes.enter)
	for _, seat in self:ipairsByGateOrder() do
		local obj = self.scene:getObjectBySeatExcludeDead(seat)
		if obj then
			obj:initedTriggerPassiveSkill(true)
		end
	end

	self.scene:updateBuffByNode(battle.BuffTriggerPoint.onHolderAfterEnter)
end

-- 一次战斗过程,包括开始 中间 结束，开始条件不满足时,中间不执行,结束无论如何都会执行一次
function NewbieGate:onceBattle(targetId, skillId)
	local input = self.fixOperatorData.input or {}
	if input[self.curHero.seat] then
		if input[self.curHero.seat].endingSpine then
			self:onOver()
			return
		end
		local target
		-- 检测开始的条件
		if self:beginBattleTurn() then
			-- targetId => seat
			targetId = input[self.curHero.seat].targetId
			skillId = input[self.curHero.seat].skillId
			target = self.scene:getObjectBySeatExcludeDead(targetId)

			self.curHero.handleChooseTarget = target
			self:runBattleTurn({ skill = skillId }, target)

			-- 自动选择技能后，不能再点击技能
			battleEasy.queueNotify("autoSelectSkill", targetId, skillId)
		end
		-- 结束判断
		self:endBattleTurn(target)
	else
		battlePlay.Gate.onceBattle(self, targetId, skillId)
	end
end

-- 发请求后 直接返回城镇
function NewbieGate:postEndResultToServer(cb)
	local endsTb = self:makeEndViewInfos()
	gRootViewProxy:raw():postEndResultToServer("/game/role/guide/newbie", function(tb)
		cb(endsTb, tb)
	end, -1)
end

function NewbieGate:onOver()
	-- onceBattle 中会重复触发这里的逻辑 因此需要阻断
	if self.isOver then return end
	self.isOver = true
	battleEasy.queueEffect(function()
		self.scene.autoFight = false
		gRootViewProxy:proxy():newbieEndPlayAni()
		--battleEasy.queueEffect('delay', {lifetime = 1000 * 410 / 30})
	end)

	self.scene:playEnd()
end

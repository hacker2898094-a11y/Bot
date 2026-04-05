-- CONFIG
local DIST = 400
local ATTACK_DISTANCE = 3
local IDEAL_MIN = 2.5
local IDEAL_MAX = 3.5

local player = game.Players.LocalPlayer
local vim = game:GetService("VirtualInputManager")

local enabled = true

-- CHAT
pcall(function()
    game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Auto bot lua active!!!","All")
end)

-- GUI
local gui = Instance.new("ScreenGui")
pcall(function() gui.Parent = game.CoreGui end)

local ball = Instance.new("Frame")
ball.Parent = gui
ball.Size = UDim2.new(0,40,0,40)
ball.Position = UDim2.new(0.5,-20,0.5,-20)
ball.BackgroundColor3 = Color3.fromRGB(0,255,0)
ball.BorderSizePixel = 0
ball.Active = true
ball.Draggable = true
Instance.new("UICorner", ball).CornerRadius = UDim.new(1,0)

-- BASE
local function getChar()
    return player.Character or player.CharacterAdded:Wait()
end

local function press(key)
    vim:SendKeyEvent(true,key,false,game)
    vim:SendKeyEvent(false,key,false,game)
end

local function punch()
    local p = ball.AbsolutePosition
    local s = ball.AbsoluteSize
    local x,y = p.X + s.X/2, p.Y + s.Y/2

    vim:SendMouseButtonEvent(x,y,0,true,game,0)
    vim:SendMouseButtonEvent(x,y,0,false,game,0)
end

-- TARGET
local function getTarget()
    local char = getChar()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local closest, dist = nil, DIST

    for _,v in pairs(game.Players:GetPlayers()) do
        if v ~= player and v.Character then
            local tHRP = v.Character:FindFirstChild("HumanoidRootPart")
            if tHRP then
                local mag = (tHRP.Position - hrp.Position).Magnitude
                if mag < dist then
                    closest = v
                    dist = mag
                end
            end
        end
    end

    return closest
end

-- LOCK
local function lock(target)
    local char = getChar()
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not (hrp and target and target.Character) then return end

    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end

    local velocity = tHRP.Velocity or Vector3.new(0,0,0)
    local predicted = tHRP.Position + (velocity * 0.1)

    hrp.CFrame = CFrame.new(hrp.Position, predicted)
end

-- DISTÂNCIA
local function adjustDistance(target)
    local char = getChar()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    if not (hrp and hum and target and target.Character) then return end

    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return end

    local offset = tHRP.Position - hrp.Position
    local dist = offset.Magnitude
    local dir = Vector3.new(offset.X,0,offset.Z)

    if dist > IDEAL_MAX then
        hum:MoveTo(tHRP.Position)
    elseif dist < IDEAL_MIN then
        hrp.CFrame = hrp.CFrame - dir.Unit * 0.5
    end
end

-- DESVIO
local function targetDodged(target)
    local char = getChar()
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not (hrp and target and target.Character) then return true end

    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not tHRP then return true end

    local dist = (tHRP.Position - hrp.Position).Magnitude
    return dist > 6
end

-- MOVIMENTO
local function moveTo(target)
    local char = getChar()
    local hum = char:FindFirstChildOfClass("Humanoid")

    if hum and target and target.Character then
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if tHRP then
            hum:MoveTo(tHRP.Position)
        end
    end
end

-- BLOCK
local lastBlock = 0

local function smartBlock(target)
    local char = getChar()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")

    if not (hrp and tHRP) then return false end

    local dist = (tHRP.Position - hrp.Position).Magnitude
    if dist > 10 then return false end

    if tick() - lastBlock > 0.8 then
        vim:SendKeyEvent(true,"F",false,game)
        task.wait(0.3)
        vim:SendKeyEvent(false,"F",false,game)

        lastBlock = tick()
        return true
    end

    return false
end

-- COMBATE FINAL CORRIGIDO
local attacking = false
local lastCounter = 0

local function combatAI(target)
    if attacking then return end

    local char = getChar()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local tHRP = target.Character:FindFirstChild("HumanoidRootPart")

    if not (hrp and tHRP) then return end

    local dist = (tHRP.Position - hrp.Position).Magnitude

    smartBlock(target)

    if dist > ATTACK_DISTANCE then
        moveTo(target)
        return
    end

    attacking = true

    -- 👊 6x M1
    for i = 1,6 do
        if targetDodged(target) then attacking = false return end
        adjustDistance(target)
        lock(target)
        punch()
        task.wait(0.18)
    end

    task.wait(0.2)

    press("One")
    task.wait(1)

    press("Q")
    task.wait(0.25)

    -- 👊 4x M1
    for i = 1,4 do
        if targetDodged(target) then attacking = false return end
        adjustDistance(target)
        lock(target)
        punch()
        task.wait(0.18)
    end

    task.wait(0.2)

    press("Two")
    task.wait(1)

    press("Three")

    -- COUNTER
    local now = tick()
    if dist < 8 and (now - lastCounter > 3) then
        press("Four")
        lastCounter = now
    end

    attacking = false
end

-- AUTO G
task.spawn(function()
    while true do
        task.wait(60)
        press("G")
    end
end)

-- LOOP
while enabled do
    task.wait()

    local target = getTarget()

    if target and target.Character then
        moveTo(target)
        combatAI(target)
    end
end

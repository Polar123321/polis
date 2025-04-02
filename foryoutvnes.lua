-- Key System Part





-- Key system part



local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local localPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Humanoid = LocalPlayer.Character.Humanoid





-- Sistema de ESP para baús
local ChestESPEnabled = false
local ChestESPObjects = {}
local ChestConnections = {}

-- Cores por tipo de baú
local chestColors = {
    ["Rare Chest"] = Color3.fromRGB(0, 150, 255),
    ["Legendary Chest"] = Color3.fromRGB(255, 100, 0),
    ["Mythical Chest"] = Color3.fromRGB(200, 0, 200)
}

local function createChestESP(model)
    if not ChestESPEnabled then return end
    
    local meshPart = model:FindFirstChildWhichIsA("MeshPart", true)
    local prompt = meshPart and meshPart:FindFirstChildWhichIsA("ProximityPrompt")
    if not prompt then return end
    
    local chestName = prompt.ObjectText or "Unknown"
    if chestName == "Common Chest" or chestName == "Uncommon Chest" then return end
    
    -- Limpa ESP anterior
    if ChestESPObjects[model] then
        for _, obj in pairs(ChestESPObjects[model]) do obj:Destroy() end
    end
    
    local chestColor = chestColors[chestName] or Color3.fromRGB(255, 255, 255)
    
    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Parent = model
    highlight.FillColor = chestColor
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.8
    highlight.OutlineTransparency = 0.2
    highlight.Name = "ChestESP"
    
    -- BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.Adornee = meshPart
    billboard.AlwaysOnTop = true
    billboard.Parent = meshPart
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    
    -- Background
    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    bg.Parent = billboard
    
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0.2, 0)
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
        ColorSequenceKeypoint.new(1, chestColor:Lerp(Color3.new(0, 0, 0), 0.7))
    })
    gradient.Parent = bg
    
    -- Labels
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -8, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 4, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = chestName
    nameLabel.TextColor3 = chestColor
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = billboard
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, -8, 0.5, 0)
    distLabel.Position = UDim2.new(0, 4, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = Color3.new(1, 1, 1)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 10
    distLabel.TextXAlignment = Enum.TextXAlignment.Left
    distLabel.Parent = billboard
    
    ChestESPObjects[model] = {highlight, billboard}
end

local function removeChestESP(model)
    if ChestESPObjects[model] then
        for _, obj in pairs(ChestESPObjects[model]) do obj:Destroy() end
        ChestESPObjects[model] = nil
    end
end

local function updateChestDistances()
    while ChestESPEnabled do
        local player = game.Players.LocalPlayer
        local playerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        
        if playerRoot then
            for model, objects in pairs(ChestESPObjects) do
                local meshPart = model:FindFirstChildWhichIsA("MeshPart", true)
                if meshPart then
                    local dist = (playerRoot.Position - meshPart.Position).Magnitude
                    local distLabel = objects[2]:FindFirstChild("TextLabel", true)
                    
                    if distLabel and distLabel:IsA("TextLabel") and distLabel.Position.Y.Scale > 0 then
                        distLabel.Text = string.format("%.0f m", dist)
                    end
                end
            end
        end
        
        task.wait(0.5)
    end
end




local noStunEnabled = false
local noStunConnection
local bodyGyro, bodyVelocity
local currentValue = 16 -- Valor inicial do WalkSpeed (usando a mesma variável do slider)

-- Função para ativar/desativar o NoStun
local function toggleNoStun()
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
        local rootPart = character.HumanoidRootPart
        local humanoid = character.Humanoid

        if noStunEnabled then
            -- Impede stun ajustando propriedades do Humanoid constantemente
            humanoid.PlatformStand = false
            humanoid.Sit = false

            -- Mantém a rotação fixa para evitar empurrões
            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bodyGyro.P = 10000
            bodyGyro.D = 100
            bodyGyro.CFrame = rootPart.CFrame
            bodyGyro.Parent = rootPart

            -- Impede stun sem travar o jogador
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(50000, 0, 50000) -- Apenas controla o eixo X e Z
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.Parent = rootPart

            -- Mantém o efeito de NoStun constantemente
            noStunConnection = game:GetService("RunService").Heartbeat:Connect(function()
                humanoid.PlatformStand = false
                humanoid.Sit = false
                bodyGyro.CFrame = rootPart.CFrame

                -- Movimentação horizontal (frente, trás, esquerda, direita)
                local direction = Vector3.new(0, 0, 0)
                local camera = workspace.CurrentCamera

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    direction = direction + camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    direction = direction - camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    direction = direction - camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    direction = direction + camera.CFrame.RightVector
                end

                -- Remove a componente Y (vertical) da direção
                direction = Vector3.new(direction.X, 0, direction.Z)

                -- Normaliza a direção e aplica a velocidade
                if direction.Magnitude > 0 then
                    -- Ajustando a velocidade para deixar o movimento mais lento
                    direction = direction.Unit * (math.min(currentValue) / 2)  -- Multiplicamos a velocidade por 2 para tornar o movimento mais rapido
                    bodyVelocity.Velocity = Vector3.new(direction.X, rootPart.Velocity.Y, direction.Z) -- Mantém a gravidade ativa
                else
                    bodyVelocity.Velocity = Vector3.new(0, rootPart.Velocity.Y, 0) -- Mantém a gravidade ativa
                end
            end)
        else
            -- Desativa NoStun
            if noStunConnection then
                noStunConnection:Disconnect()
            end
            if bodyVelocity then
                bodyVelocity:Destroy()
            end
            if bodyGyro then
                bodyGyro:Destroy()
            end
        end
    end
end

ChestESPEnabled = false

-- Função para ativar/desativar o Chest ESP
local function toggleChestESP(value)
    ChestESPEnabled = value
    if ChestESPEnabled then
        -- Adiciona ESP para baús existentes
        for _, model in ipairs(workspace.Effects:GetChildren()) do
            if model:IsA("Model") then
                createChestESP(model)
            end
        end

        -- Detecta novos baús adicionados
        local chestConnection = workspace.Effects.ChildAdded:Connect(function(model)
            if model:IsA("Model") then
                task.wait(1) -- Pequeno delay para garantir que carregou
                createChestESP(model)
            end
        end)
        table.insert(ChestConnections, chestConnection)

        -- Inicia a atualização de distância
        coroutine.wrap(updateChestDistances)()
    else
        -- Remove ESP de todos os baús
        for model in pairs(ChestESPObjects) do
            removeChestESP(model)
        end

        -- Limpa as conexões
        for _, connection in ipairs(ChestConnections) do
            connection:Disconnect()
        end
        ChestConnections = {}
    end
end



local ESPEnabled = false
local ESPObjects = {}
local connections = {}

-- Configurações personalizáveis
local ESPConfig = {
    AllyColor = Color3.fromRGB(0, 255, 100), -- Verde suave para aliados
    EnemyColor = Color3.fromRGB(255, 50, 50), -- Vermelho suave para inimigos
    HighlightTransparency = 0.8, -- Preenchimento quase transparente
    OutlineTransparency = 0.2, -- Contorno sutil
    TextSize = 14, -- Tamanho do texto
    TextFont = Enum.Font.GothamMedium, -- Fonte moderna
    ShowDistance = true, -- Mostrar distância
    ShowHealth = true, -- Mostrar vida
    ShowAllies = false, -- Mostrar aliados
    ShowEnemies = true, -- Mostrar inimigos
    TextOffset = Vector3.new(0, 2.5, 0), -- Posição do texto acima da cabeça
    BackgroundTransparency = 0.7, -- Transparência do fundo do texto
}






local function createVendingMachineESP(value)
    iisESPEnabled = value

    local player = game.Players.LocalPlayer
    if not player or not player.Character then
        warn("[ESP] Erro: Player não encontrado.")
        return
    end

    local envFolder = workspace:FindFirstChild("Env")
    if not envFolder then
        warn("[ESP] Erro: workspace.Env não encontrado.")
        return
    end

    local function createTextLabel(item, labelName, text)
        if not item or item:FindFirstChild(labelName) then
            return
        end

        -- Verifica se o Model possui uma parte válida
        local adorneePart = item:FindFirstChild("PrimaryPart") or item:FindFirstChildWhichIsA("BasePart")
        if not adorneePart then
            warn("O Model não possui uma parte válida para Adornee:", item.Name)
            return
        end

        -- Criando BillboardGui
        local billboard = Instance.new("BillboardGui")
        billboard.Name = labelName
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.Adornee = adorneePart
        billboard.AlwaysOnTop = true
        billboard.Parent = item

        -- Criando TextLabel
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextScaled = true
        textLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dourado
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.Text = text

        textLabel.Parent = billboard
        print("BillboardGui criada para:", item.Name)
    end

    local function removeTextLabels(labelName)
        for _, item in ipairs(envFolder:GetChildren()) do
            local label = item:FindFirstChild(labelName)
            if label then
                label:Destroy()
            end
        end
    end

    local function updateTextLabels(labelName, conditionFunc, getTextFunc)
        while iisESPEnabled do
            pcall(function()
                if not workspace:FindFirstChild("Env") then
                    warn("[ESP] workspace.Env não encontrado, encerrando ESP.")
                    iisESPEnabled = false
                    return
                end

                for _, item in ipairs(workspace.Env:GetChildren()) do
                    -- Verifica se o nome é "VendingMachine" e se atende à condição
                    if item.Name == "VendingMachine" and conditionFunc(item) then
                        createTextLabel(item, labelName, getTextFunc(item))
                    end
                end
            end)
            task.wait(1) -- Atualiza a cada 1s
        end
        removeTextLabels(labelName) -- Remove as labels quando desativado
    end

    -- Atualiza a função de condição e obtenção de texto para usar atributos
    if iisESPEnabled then
        task.spawn(function()
            updateTextLabels("VendingMachineText", function(item)
                -- Verifica se o item é um Model e possui o atributo "VendingType"
                return item:IsA("Model") and item:GetAttribute("VendingType") ~= nil
            end, function(item)
                -- Obtém o valor do atributo "VendingType"
                return item:GetAttribute("VendingType") or "Unknown"
            end)
        end)
    else
        removeTextLabels("VendingMachineText")
    end
end






-- Função para verificar se um jogador é inimigo
local function isEnemy(player)
    -- Adicione sua lógica para determinar se o jogador é inimigo
    return true -- Temporariamente, considera todos como inimigos
end

-- Função para criar ESP em um jogador
local function createESP(player)
    if player == game.Players.LocalPlayer then return end -- Ignora o próprio jogador

    local function applyESP(character)
        if not character then return end

        -- Verifica se o ESP já foi aplicado
        if ESPObjects[player] then return end

        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local head = character:FindFirstChild("Head")
        if not rootPart or not head then return end

        -- Define a cor com base no tipo de jogador
        local color = isEnemy(player) and ESPConfig.EnemyColor or ESPConfig.AllyColor

        -- Criar Highlight (Brilho)
        local highlight = Instance.new("Highlight")
        highlight.Parent = character
        highlight.FillColor = color
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255) -- Contorno branco
        highlight.FillTransparency = ESPConfig.HighlightTransparency
        highlight.OutlineTransparency = ESPConfig.OutlineTransparency
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Garante que fique acima de outros objetos

        -- Criar BillboardGui (Textos)
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 200, 0, 50) -- Tamanho ajustado
        billboard.StudsOffset = ESPConfig.TextOffset -- Posição acima da cabeça
        billboard.Adornee = head
        billboard.Parent = character
        billboard.AlwaysOnTop = true
        billboard.Name = "PlayerESPBillboard"

        -- Fundo semi-transparente
        local background = Instance.new("Frame")
        background.Size = UDim2.new(1, 0, 1, 0)
        background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        background.BackgroundTransparency = ESPConfig.BackgroundTransparency
        background.BorderSizePixel = 0
        background.Parent = billboard

        -- Nome do Jogador
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = color
        nameLabel.TextSize = ESPConfig.TextSize
        nameLabel.Font = ESPConfig.TextFont
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Contorno preto para melhor legibilidade
        nameLabel.Parent = billboard

        -- Distância e Vida
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, 0, 0.5, 0)
        infoLabel.Position = UDim2.new(0, 0, 0.5, 0)
        infoLabel.BackgroundTransparency = 1
        infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- Branco
        infoLabel.TextSize = ESPConfig.TextSize
        infoLabel.Font = ESPConfig.TextFont
        infoLabel.TextStrokeTransparency = 0.5
        infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0) -- Contorno preto
        infoLabel.Text = "Carregando..."
        infoLabel.Parent = billboard

        -- Guardar objetos na tabela
        ESPObjects[player] = {highlight, billboard, nameLabel, infoLabel}
    end

    -- Aplica o ESP e reconstrói se o jogador morrer
    local characterAddedConnection = player.CharacterAdded:Connect(function(character)
        task.wait(1) -- Espera carregar
        applyESP(character)
    end)
    table.insert(connections, characterAddedConnection)

    if player.Character then
        applyESP(player.Character)
    end
end

-- Remover ESP de um jogador
local function removeESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            obj:Destroy()
        end
        ESPObjects[player] = nil
    end
end

-- Atualizar Distância e Vida de todos os jogadores
local function updateESP()
    while ESPEnabled do
        for player, objects in pairs(ESPObjects) do
            local character = player.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local localCharacter = game.Players.LocalPlayer.Character
            local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

            if rootPart and localRoot and humanoid then
                local distance = (localRoot.Position - rootPart.Position).Magnitude
                local healthText = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                objects[4].Text = "Dist: " .. math.floor(distance) .. "m | Vida: " .. healthText
            else
                objects[4].Text = "Fora de alcance"
            end
        end
        task.wait(0.3) -- Atualiza a cada 0.3s
    end
end

-- Função para ativar/desativar o ESP
local function toggleESP(value)
    ESPEnabled = value
    if ESPEnabled then
        -- Adiciona ESP para todos os jogadores
        for _, player in ipairs(game.Players:GetPlayers()) do
            if (ESPConfig.ShowEnemies and isEnemy(player)) or (ESPConfig.ShowAllies and not isEnemy(player)) then
                createESP(player)
            end
        end

        -- Conecta para novos jogadores
        local playerAddedConnection = game.Players.PlayerAdded:Connect(function(player)
            if (ESPConfig.ShowEnemies and isEnemy(player)) or (ESPConfig.ShowAllies and not isEnemy(player)) then
                createESP(player)
            end
        end)
        table.insert(connections, playerAddedConnection)

        -- Inicia a atualização de distância e vida
        coroutine.wrap(updateESP)()
    else
        -- Remove ESP de todos os jogadores
        for player in pairs(ESPObjects) do
            removeESP(player)
        end

        -- Limpa as conexões
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        connections = {}
    end
end

-- 📍 Tabela de Localizações para Teleporte
local teleport_table = {
    
}

local flyEnabled = false
local flySpeed = 50
local flyConnection

local function toggleFly()
    local character = localPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then return end
    local rootPart = character.HumanoidRootPart
    local humanoid = character.Humanoid

    if flyEnabled then

        -- Se já tem uma conexão ativa, evita criar outra
        if flyConnection then flyConnection:Disconnect() end

        -- Mantém o player no ar sem que o servidor perceba
        flyConnection = RunService.Heartbeat:Connect(function()
            if flyEnabled then
                local direction = Vector3.zero
                local camera = workspace.CurrentCamera

                if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                    direction += camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                    direction -= camera.CFrame.LookVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    direction -= camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    direction += camera.CFrame.RightVector
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    direction += Vector3.new(0, 1, 0)
                end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    direction -= Vector3.new(0, 1, 0)
                end

                if direction.Magnitude > 0 then
                    direction = direction.Unit * flySpeed
                end

                rootPart.CFrame = rootPart.CFrame + direction * 0.02 -- Move suavemente
                rootPart.Velocity = Vector3.zero -- Evita problemas de gravidade
            else
                -- Se o Fly for desativado, limpa corretamente
                if flyConnection then flyConnection:Disconnect() flyConnection = nil end
            end
        end)
    else
        -- Desativa o Fly
        if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    end
end

print(5639.86865, -92.762001, -16611.4688, -1, 0, 0, 0, 1, 0, 0, 0, -1)

local cancelTeleport = false -- Global flag to cancel teleport

local TweenService = game:GetService("TweenService")

local function bypass_teleport(destination)
    local character = localPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
        local humanoidRootPart = character.HumanoidRootPart
        local humanoid = character.Humanoid
        local startPosition = humanoidRootPart.Position
        local camera = workspace.CurrentCamera

        -- 🚀 Ativa o fly TEMPORARIAMENTE durante a subida
        flyEnabled = true
        toggleFly()

        -- ⬆️ Subida mais suave e realista
        local targetHeight = 4
        local ascentTime = 1 -- ⏳ Deixa a subida mais lenta

        local ascentTween = TweenService:Create(
                humanoidRootPart,
                TweenInfo.new(ascentTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- 🌟 Mais suave
                {CFrame = CFrame.new(startPosition.X, targetHeight, startPosition.Z)}
        )

        ascentTween:Play()
        ascentTween.Completed:Wait()

        -- 🏹 Movimentação suave no plano XZ com desvio de obstáculos
        local speed = 1.4
        local position = Vector3.new(startPosition.X, targetHeight, startPosition.Z)

        while not cancelTeleport and (Vector2.new(position.X, position.Z) - Vector2.new(destination.X, destination.Z)).Magnitude > speed do
            local direction = (Vector3.new(destination.X, targetHeight, destination.Z) - position).Unit
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {character} -- Ignora o jogador
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

            local raycastResult = workspace:Raycast(position, direction * speed, raycastParams)
            if raycastResult then
                -- 🚧 Obstáculo detectado, tenta encontrar um novo caminho
                local newDirection = nil
                for angle = -90, 90, 15 do -- Tenta ângulos de -90° a 90° em incrementos de 15°
                    local rotatedDirection = CFrame.Angles(0, math.rad(angle), 0):VectorToWorldSpace(direction)
                    local testRay = workspace:Raycast(position, rotatedDirection * speed, raycastParams)
                    if not testRay then
                        newDirection = rotatedDirection
                        break
                    end
                end

                if newDirection then
                    direction = newDirection.Unit
                else
                    -- 🚫 Sem caminho disponível, cancela o teleporte
                    Fluent:Notify({
                        Title = "Teleport Stopped!",
                        Content = "No clear path to destination.",
                        Duration = 8
                    })
                    cancelTeleport = true
                    break
                end
            end

            -- Move o jogador suavemente
            position = position + direction * speed
            humanoidRootPart.CFrame = CFrame.new(position)
            task.wait(1 / 60)
        end

        if not cancelTeleport then
            humanoidRootPart.CFrame = CFrame.new(destination.X, targetHeight, destination.Z)
        end

        cancelTeleport = false -- Reseta a flag após o teleporte

        -- 🚀 Desativa o fly no final do teleporte
        flyEnabled = false
        toggleFly()

    end
end


local function InstaTeleport(destination)
    local character = localPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local hrp = character.HumanoidRootPart
        if teleport_table[destination] then
            hrp.CFrame = CFrame.new(teleport_table[destination])
            task.wait(0.1)
            local args = {
                [1] = "self"
            }

            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("KnockedOut"):FireServer(unpack(args))
        else
            warn("Local de teleporte inválido!")
        end
    end
end




local function cancel_teleport()
    cancelTeleport = true
end


local Window = Fluent:CreateWindow({
    Title = "Polis Hub " .. "v3 " .. "Rank: Developer",
    SubTitle = "by Polar",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

--Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    InstaTP = Window:AddTab({ Title = "Insta TP", Icon = "cloud-lightning" }),
    TweenTP = Window:AddTab({ Title = "Tween TP", Icon = "move" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "folder"}),
    AutoFarm = Window:AddTab({ Title = "AutoFarm", Icon = "crosshair"}),
    Debug = Window:AddTab({ Title = "Debug", Icon = "bug"})
}


local Options = Fluent.Options

do


    local priquito = Tabs.Main:AddButton({
        Title = "Infinite Yield (Dont Use this.)",
        Description = "",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
        end
    })





    for name, position in pairs(teleport_table) do
        Tabs.TweenTP:AddButton({
            Title = name:gsub("(Patched) _", " "):gsub("^%l", string.upper), -- Formata o nome corretamente
            Description = "Teleport to " .. name:gsub("_", " "), -- Formata a descrição
            Callback = function()
                bypass_teleport(position) -- Teleporta para a posição correspondente
            end
        })
    end

    for name, position in pairs(teleport_table) do
        Tabs.InstaTP:AddButton({
            Title = name:gsub("(Patched) _", " "):gsub("^%l", string.upper), -- Formata o nome corretamente
            Description = "Instantly teleport to " .. name:gsub("_", " "), -- Formata a descrição
            Callback = function()
                InstaTeleport(name) -- Chama a função InstaTeleport diretamente
            end
        })
    end

    local isFarming = false
    Tabs.AutoFarm:AddToggle("AutoFarm", {
        Title = "Rifle Farm",
        Description = "Auto Target Enemies using a rifle, and kill them",
        Default = false,
        Callback = function(value)
            isFarming = value -- Atualiza a variável global
            local function equipRifle()
                local player = game.Players.LocalPlayer
                if player and player.Backpack then
                    local rifle = player.Backpack:FindFirstChild("Rifle")
                    if rifle then
                        rifle.Parent = player.Character
                        return true
                    end
                end
                return false
            end

            local function isHoldingRifle()
                local player = game.Players.LocalPlayer
                if player and player.Character then
                    return player.Character:FindFirstChild("Rifle") ~= nil
                end
                return false
            end

            local function findNearestNPC()
                local nearestNPC = nil
                local nearestDistance = math.huge
                local player = game.Players.LocalPlayer
                if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local playerPosition = player.Character.HumanoidRootPart.Position

                    for _, npc in ipairs(workspace.NPCs:GetChildren()) do
                        if npc.Name ~= "Becky" and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Head") then
                            local npcPosition = npc.HumanoidRootPart.Position
                            local distance = (playerPosition - npcPosition).Magnitude

                            if distance > 10 and distance < nearestDistance then
                                nearestDistance = distance
                                nearestNPC = npc
                            end
                        end
                    end
                end
                return nearestNPC
            end

            local function farm()
                while isFarming do
                    if not isHoldingRifle() then
                        if not equipRifle() then
                            isFarming = false
                            break
                        end
                    end

                    local nearestNPC = findNearestNPC()

                    if nearestNPC then
                        local headPosition = nearestNPC.Head.Position
                        local startCFrame = CFrame.new(game.Players.LocalPlayer.Character.HumanoidRootPart.Position, headPosition)

                        local fireArgs = {
                            [1] = "fire",
                            [2] = {
                                ["Start"] = startCFrame,
                                ["Gun"] = "Rifle",
                                ["joe"] = "true",
                                ["Position"] = headPosition
                            }
                        }

                        pcall(function()
                            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("CIcklcon"):FireServer(unpack(fireArgs))
                        end)

                        local reloadArgs = {
                            [1] = "reload",
                            [2] = { ["Gun"] = "Rifle" }
                        }
                        pcall(function()
                            game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("CIcklcon"):WaitForChild("gunFunctions"):InvokeServer(unpack(reloadArgs))
                        end)
                    end

                    wait(0.1)
                end
            end

            if isFarming then
                task.spawn(farm)
            end
        end
    })

    Tabs.Main:AddToggle("WalkWater", {
        Title = "Walk On Water",
        Description = "Walks on Water",
        Default = false,
        Callback = function(value)
            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then
                warn("[WalkOnWater] Erro: HumanoidRootPart não encontrado.")
                return
            end

            if value then
                local part = Instance.new("Part")
                part.Parent = workspace
                part.Size = Vector3.new(999999999999999, 1.7, 999999999999999)
                part.Name = "WalkOnWater"
                part.CFrame = CFrame.new(hrp.Position.X, workspace.Env.Ocean.Position.Y + 1, hrp.Position.Z)
                part.Anchored = true
                part.CanCollide = true
                part.Transparency = 1 -- Opcional (torna invisível)

            else
                local oldPart = workspace:FindFirstChild("WalkOnWater")
                if oldPart then oldPart:Destroy() end
            end
        end
    })



    Tabs.ESP:AddToggle("PlayerESP", {
        Title = "Player ESP",
        Description = "ESP Players to kill them",
        Default = false,
        Callback = function(value)
            toggleESP(value)
        end
    })

    Tabs.ESP:AddToggle("MedalESP", {
        Title = "Medal ESP",
        ButtonName = "Medal ESP",
        Description = "Highlight all Medal that spawns on map",
        Callback = function(value)
            isESPEnabled = value -- Atualiza a variável global

            -- Verificação básica antes de executar
            local player = game.Players.LocalPlayer
            if not player or not player.Character or not workspace:FindFirstChild("Effects") then
                warn("[MedalESP] Erro: Player ou workspace.Effects não encontrado.")
                return
            end

            local function createTextLabel(medal)
                if not medal or medal:FindFirstChild("MedalText") then
                    return
                end

                -- Tenta encontrar uma parte visível da Medal
                local part = medal:IsA("Model") and medal.PrimaryPart or medal:FindFirstChildWhichIsA("BasePart") or medal
                if not part then return end -- Se não tiver uma peça válida, sai da função

                local billboard = Instance.new("BillboardGui")
                billboard.Name = "MedalText"
                billboard.Size = UDim2.new(0, 100, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 2, 0) -- Eleva o texto acima da Medal
                billboard.Adornee = part
                billboard.AlwaysOnTop = true
                billboard.Parent = part

                local textLabel = Instance.new("TextLabel")
                textLabel.Size = UDim2.new(1, 0, 1, 0)
                textLabel.BackgroundTransparency = 1
                textLabel.TextScaled = true
                textLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dourado
                textLabel.Font = Enum.Font.SourceSansBold
                textLabel.Text = medal.Name -- Exibe o nome correto da Medal (o nome do Model)

                textLabel.Parent = billboard
            end

            local function removeTextLabels()
                if not workspace:FindFirstChild("Effects") then
                    return
                end
                for _, item in ipairs(workspace.Effects:GetChildren()) do
                    if item:IsA("Model") or item:IsA("Part") then
                        local label = item:FindFirstChild("MedalText")
                        if label then label:Destroy() end
                    end
                end
            end

            local function updateTextLabels()
                while isESPEnabled do
                    if not workspace:FindFirstChild("Effects") then
                        warn("[MedalESP] workspace.Effects não encontrado, encerrando ESP.")
                        isESPEnabled = false
                        return
                    end
                    for _, item in ipairs(workspace.Effects:GetChildren()) do
                        if item:IsA("Model") or item:IsA("Part") then
                            if string.find(item.Name, "Medal") then
                                createTextLabel(item) -- Agora passa o Model inteiro, não só a parte
                            end
                        end
                    end
                    wait(1) -- Atualiza a cada 1s
                end
                removeTextLabels() -- Remove as labels quando desativado
            end

            if isESPEnabled then
                task.spawn(updateTextLabels)
            else
                removeTextLabels()
            end
        end
    })


    -- Cria o Toggle para ativar/desativar o Chest ESP
    Tabs.ESP:AddToggle("ChestESP", {
        Title = "Chest ESP",
        Description = "Active Chest ESP (Rare, Legendary, Mythical) not Common & Uncommon",
        Default = false,
        Callback = function(value)
            toggleChestESP(value)
        end
    })


    local iisESPEnabled = false

    Tabs.ESP:AddToggle("VendingESP", {
        Title = "Vending Machine ESP",
        Description = "Highlight all Vending Machines that spawn on the map",
        Default = false,
        Callback = function(value)
            iisESPEnabled = value
            createVendingMachineESP(iisESPEnabled)
        end
    })


    Tabs.Player:AddToggle("NoStun", {
        Title = "No Stun",
        ButtonName = "No Stun",
        Description = "Avoid Stuns",
        Default = false,
        Callback = function(value)
            noStunEnabled = value
            toggleNoStun()
        end
    })

    local InfiniteJumpEnabled = false
    local jumpConnection
    local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid")

    local jumpDelay = 0.3
    local lastJumpTime = 0
    Tabs.Player:AddToggle("InfiniteJump", {
        Title = "Infinite Jump",
        Default = false,
        Description = "Infinitely jumps the user",
        Callback = function(value)
            InfiniteJumpEnabled = value

            -- Se já tiver conexão, desconecta antes de criar uma nova
            if jumpConnection then
                jumpConnection:Disconnect()
                jumpConnection = nil
            end

            if InfiniteJumpEnabled then
                jumpConnection = UserInputService.JumpRequest:Connect(function()
                    local currentTime = tick()
                    if humanoid and currentTime - lastJumpTime >= jumpDelay then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        lastJumpTime = currentTime
                    end
                end)
            end
        end
    })

    local bubblelol = false
    local bubblep -- Variável para armazenar a bolha criada, se necessário
    local heartbeatConnection -- Variável para a conexão do Heartbeat

    Tabs.Main:AddToggle("SwinOnWaterWithDevilFruit", {
        Title = "Swim On Water With Devil Fruit",
        Description = "Swim On Water With Devil Fruit",
        Default = false,
        Callback = function(value)
            bubblelol = value
            local events = ReplicatedStorage:WaitForChild("Events")
            local bubbleEvent = events:WaitForChild("Bubble")

            if bubbleEvent then
                print("Bubble event found. Firing server event.")
                bubbleEvent:FireServer()
            else
                warn("Error: Event 'Bubble' not found!")
                return
            end

            local main = localPlayer.PlayerGui.BubbleHP.Main
            local bubble = main.Bubble
            local character = Workspace.PlayerCharacters:FindFirstChild(localPlayer.Name)

            if character and bubblelol then
                -- Verifique se a variável 'inBubble' já existe
                local inBubble = character:FindFirstChild("inBubble")

                -- Se não existir, crie o 'inBubble'
                if not inBubble then
                    inBubble = Instance.new("BoolValue")
                    inBubble.Name = "inBubble"
                    inBubble.Parent = character
                end

                -- Verifica se o 'inBubble' é verdadeiro
                if inBubble.Value == true then
                    -- Se a bolha já estiver ativa, kicka o jogador
                    localPlayer:Kick("YOU'RE IN BUBBLE VALUE IS ALREADY TRUE! DO NOT ACTIVATE THIS WHILE IN BUBBLE OR YOU'LL BE BANNED!")
                    return
                end

                -- Criar a bolha
                bubblep = Instance.new("Part")
                bubblep.Name = "coatBubble"
                bubblep.Shape = Enum.PartType.Ball -- Forma esférica para representar uma bolha
                bubblep.BrickColor = BrickColor.new("Pastel Blue")
                bubblep.Color = Color3.fromRGB(128, 187, 219)
                bubblep.Material = Enum.Material.Glass
                bubblep.Size = Vector3.new(7, 7, 7) -- Tamanho maior para cobrir o personagem
                bubblep.Anchored = false -- Não ancorado para permitir movimento
                bubblep.CanCollide = false
                bubblep.Transparency = 0.5
                bubblep.Parent = character

                -- Atualizar a posição da bolha para seguir o HumanoidRootPart
                local runService = game:GetService("RunService")

                -- Conectar o Heartbeat para atualizar a posição da bolha
                heartbeatConnection = runService.Heartbeat:Connect(function()
                    -- Atualiza a posição da bolha para seguir o HumanoidRootPart
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        bubblep.CFrame = character.HumanoidRootPart.CFrame
                    else
                        warn("HumanoidRootPart not found for " .. character.Name)
                    end
                end)

                -- Configurações do UI
                inBubble.Value = true
                main.Active = true
                main.Visible = true
                bubble.Active = true
                bubble.Visible = true

                task.wait(0.5)
                print("Bubble activated successfully.")
            else
                print(localPlayer.Name .. " does not have the 'inBubble' object.")
                task.wait(0.6)
                print("Returning for safety.")
            end

            -- Se o toggle for desmarcado, destrói a bolha e desativa o UI
            if not bubblelol then
                if bubblep then
                    bubblep:Destroy()
                end

                -- Desconectar o Heartbeat se a bolha for removida
                if heartbeatConnection then
                    heartbeatConnection:Disconnect()
                end

                if main then
                    main.Active = false
                    main.Visible = false
                end

                if bubble then
                    bubble.Active = false
                    bubble.Visible = false
                end

                if character then
                    local inBubble = character:FindFirstChild("inBubble")
                    if inBubble then
                        inBubble.Value = false
                    end
                end
            end
        end
    })

    -- Referência global para o botão (para podermos atualizá-lo)
    local botaoRaid = nil

    -- Função para remover códigos de cor do texto
    local function removerCodigosDeCor(texto)
        -- Verificação de entrada inicial
        if not texto then
            return nil
        end

        -- Verificação de tipo mais robusta
        if type(texto) ~= "string" and typeof(texto) ~= "string" then
            return texto
        end

        -- Verificação de string vazia
        if texto == "" then
            return texto
        end

        -- Verifica o tamanho da string (limite para prevenir operações em strings muito grandes)
        local tamanhoLimite = 100000-- 100KB
        if #texto > tamanhoLimite then
            warn("Aviso: String muito grande para processamento de remoção de cores")
            return texto
        end

        -- Protege contra padrões muito complexos que podem causar backtracking excessivo
        local function gsub_seguro(str, pattern, repl, limit)
            local status, resultado = pcall(function()
                return str:gsub(pattern, repl, limit)
            end)

            if not status then
                warn("Erro ao remover padrão de cor:", resultado)
                return str
            end

            return resultado
        end

        -- Contador para evitar loops infinitos em substituições
        local contadorSubstituicoes = 0
        local maxSubstituicoes = 100000000
        local textoLimpo = texto
        local textoAnterior = ""

        -- Loop de segurança para evitar substituições infinitas
        while textoLimpo ~= textoAnterior and contadorSubstituicoes < maxSubstituicoes do
            textoAnterior = textoLimpo

            -- Remove códigos de cor do formato <font color="RRGGBB">texto</font>
            textoLimpo = gsub_seguro(textoLimpo, "<font[^>]*>(.-)</font>", "%1")

            -- Remove códigos de cor Rich Text como [rgb(r,g,b)] ou [#RRGGBB]
            textoLimpo = gsub_seguro(textoLimpo, "%[rgb%([^%)]+%)]", "")
            textoLimpo = gsub_seguro(textoLimpo, "%[#%x+%]", "")

            -- Remove qualquer outro formato de cor que possa estar presente
            textoLimpo = gsub_seguro(textoLimpo, "<color=[^>]+>", "")
            textoLimpo = gsub_seguro(textoLimpo, "</color>", "")

            contadorSubstituicoes = contadorSubstituicoes + 1
        end

        -- Avisa se atingiu o limite de substituições
        if contadorSubstituicoes >= maxSubstituicoes then
            warn("Aviso: Número máximo de substituições atingido ao remover códigos de cor")
        end

        return textoLimpo
    end



    -- Função para verificar se um objeto existe e é do tipo esperado
    local function verificarObjeto(objeto, tipo, nome)
        if not objeto then
            warn("⚠️ ERRO CRÍTICO: Objeto " .. nome .. " não encontrado!")
            return false
        end

        if not objeto:IsA(tipo) then
            warn("⚠️ ERRO CRÍTICO: Objeto " .. nome .. " não é do tipo " .. tipo .. "!")
            return false
        end

        return true
    end

    -- Modifique a função obterTituloRaid para usar a nova função
    local function obterTituloRaid()
        -- Verificação do Workspace
        if not workspace then
            warn("⚠️ ERRO FATAL: Workspace não disponível!")
            return "ERRO: Workspace indisponível"
        end

        -- Verificação da pasta Islands
        local islands = workspace:FindFirstChild("Islands")
        if not verificarObjeto(islands, "Folder", "Islands") then
            return "ERRO: Pasta Islands não encontrada"
        end

        -- Verificação do Reino
        local roseKingdom = islands:FindFirstChild("Rose Kingdom")
        if not verificarObjeto(roseKingdom, "Model", "Rose Kingdom") then
            return "ERRO: Rose Kingdom não encontrado"
        end

        -- Verificação da Factory
        local factory = roseKingdom:FindFirstChild("Factory")
        if not verificarObjeto(factory, "Model", "Factory") then
            return "ERRO: Factory não encontrada"
        end

        -- Verificação da Porta
        local frontDoor = factory:FindFirstChild("FrontDoor")
        if not verificarObjeto(frontDoor, "Model", "FrontDoor") then
            return "ERRO: Porta frontal não encontrada"
        end

        -- Verificação da parte Top
        local top = frontDoor:FindFirstChild("Top")
        if not verificarObjeto(top, "BasePart", "Top") then
            return "ERRO: Parte superior não encontrada"
        end

        -- Verificação do BillboardGui
        local billboard = top:FindFirstChild("BillboardGui")
        if not verificarObjeto(billboard, "BillboardGui", "BillboardGui") then
            return "ERRO: BillboardGui não encontrado"
        end

        -- Verificação da TextLabel
        local textLabel = billboard:FindFirstChild("TextLabel")
        if not verificarObjeto(textLabel, "TextLabel", "TextLabel") then
            return "ERRO: TextLabel não encontrado"
        end

        -- Verificação do texto
        if not textLabel.Text or typeof(textLabel.Text) ~= "string" then
            warn("⚠️ ERRO: TextLabel tem valor inválido!")
            return "ERRO: Valor inválido"
        end

        if textLabel.Text == "" then
            warn("⚠️ ALERTA: TextLabel está vazia!")
            return "RAID INDISPONÍVEL"
        end

        -- Remover códigos de cor antes de retornar o texto
        local textoLimpo = removerCodigosDeCor(textLabel.Text)

        -- Sucesso - retorna o texto validado e limpo
        print("✓ Título da raid obtido com sucesso: " .. textoLimpo)
        return textoLimpo
    end


    -- Função para criar o botão apenas uma vez
    local function criarBotaoRaid()
        -- Verifica se já temos um botão criado
        if botaoRaid then
            warn("⚠️ Botão já foi criado anteriormente. Pulando criação.")
            return botaoRaid
        end

        -- Verifica se a Tab existe
        if not Tabs or not Tabs.Debug then
            warn("⚠️ ERRO: Tabs.Debug não encontrado!")
            return nil
        end

        local tituloAtual

        -- Tenta obter o título com proteção contra erros
        local sucesso, resultado = pcall(function()
            return obterTituloRaid()
        end)

        if sucesso then
            tituloAtual = resultado
        else
            warn("⚠️ ERRO FATAL ao obter título da raid: " .. tostring(resultado))
            tituloAtual = "ERRO DE SISTEMA"
        end

        -- Validação final do título antes de atribuir ao botão
        if typeof(tituloAtual) ~= "string" then
            tituloAtual = tostring(tituloAtual) or "ERRO DE TIPO"
        end

        -- Cria o botão uma única vez
        local novoBotao = nil
        local sucesso = pcall(function()
            novoBotao = Tabs.Debug:AddButton({
                Title = tituloAtual,
                Description = "Raid atual: " .. tituloAtual,
                Callback = function()
                    -- Verificar novamente o título no momento do clique para garantir atualização
                    local tituloAtualizado = obterTituloRaid()
                    print("Botão da raid clicado: " .. tituloAtualizado)

                    -- Seu código para ação do botão aqui
                    -- ...
                end
            })
        end)

        if not sucesso or not novoBotao then
            warn("⚠️ ERRO CRÍTICO: Falha ao criar botão!")
            return nil
        end

        print("✓ Botão da raid criado com sucesso!")
        return novoBotao
    end

    -- Função para atualizar APENAS o texto do botão existente
    local function atualizarTextoBotao()
        -- Verifica se o botão existe
        if not botaoRaid then
            warn("⚠️ O botão ainda não foi criado!")
            botaoRaid = criarBotaoRaid()
            if not botaoRaid then
                warn("⚠️ Não foi possível criar o botão para atualização!")
                return false
            end
        end

        local tituloAtual

        -- Tenta obter o título com proteção contra erros
        local sucesso, resultado = pcall(function()
            return obterTituloRaid()
        end)

        if sucesso then
            tituloAtual = resultado
        else
            warn("⚠️ ERRO FATAL ao obter título da raid: " .. tostring(resultado))
            tituloAtual = "ERRO DE SISTEMA"
        end

        -- Validação final do título antes de atualizar
        if typeof(tituloAtual) ~= "string" then
            tituloAtual = tostring(tituloAtual) or "ERRO DE TIPO"
        end

        -- Atualiza APENAS o título do botão existente
        if botaoRaid.UpdateButton then
            -- Se o seu sistema de UI tiver uma função UpdateButton
            local atualizado = pcall(function()
                botaoRaid:UpdateButton({
                    Title = tituloAtual,
                    Description = "Raid atual: " .. tituloAtual
                })
            end)

            if not atualizado then
                warn("⚠️ Falha ao atualizar botão usando UpdateButton")
            else
                print("✓ Título do botão atualizado para: " .. tituloAtual)
            end
        elseif botaoRaid.SetTitle then
            -- Se o seu sistema de UI tiver uma função SetTitle
            local atualizado = pcall(function()
                botaoRaid:SetTitle(tituloAtual)

                -- Tenta também atualizar a descrição se disponível
                if botaoRaid.SetDescription then
                    botaoRaid:SetDescription("Raid atual: " .. tituloAtual)
                end
            end)

            if not atualizado then
                warn("⚠️ Falha ao atualizar botão usando SetTitle")
            else
                print("✓ Título do botão atualizado para: " .. tituloAtual)
            end
        elseif type(botaoRaid) == "table" then
            -- Tentativa genérica para interfaces baseadas em tabela
            botaoRaid.Title = tituloAtual
            botaoRaid.Description = "Raid atual: " .. tituloAtual

            -- Forçar atualização visual se houver um método de refresh
            if botaoRaid.Refresh then
                botaoRaid:Refresh()
            end

            print("✓ Propriedades do botão atualizadas, mas pode ser necessário refresh visual")
        else
            warn("⚠️ Não foi possível determinar como atualizar o botão existente!")
            return false
        end

        return true
    end

    -- Configuração do monitoramento da TextLabel
    local function configurarMonitoramento()
        -- Referência segura para o TextLabel
        local textLabelRef

        -- Tenta obter referência com segurança
        pcall(function()
            textLabelRef = workspace.Islands["Rose Kingdom"].Factory.FrontDoor.Top.BillboardGui.TextLabel
        end)

        if not textLabelRef then
            warn("⚠️ ERRO: Não foi possível configurar monitoramento de título")
            return
        end

        -- Configurar Changed event com proteção contra erros
        local conexao
        conexao = textLabelRef:GetPropertyChangedSignal("Text"):Connect(function()
            if not textLabelRef or not textLabelRef.Parent then
                warn("⚠️ TextLabel removida, desconectando monitoramento")
                if conexao then conexao:Disconnect() end
                return
            end

            print("✓ Título da raid atualizado: " .. textLabelRef.Text)
            atualizarTextoBotao() -- Apenas atualiza o texto, não cria novo botão
        end)

        -- Salvaguarda para desconexão durante cleanup
        game:GetService("Players").LocalPlayer.AncestryChanged:Connect(function()
            if conexao then conexao:Disconnect() end
        end)

        return conexao
    end

    -- Inicialização
    local function inicializar()
        -- Criar o botão uma única vez
        botaoRaid = criarBotaoRaid()

        if not botaoRaid then
            warn("⚠️ Falha na criação inicial do botão!")
            return false
        end

        -- Configurar o monitoramento
        local conexao = configurarMonitoramento()

        -- Sistema de recuperação para verificar a cada 30 segundos (apenas atualiza, não cria novos)
        spawn(function()
            while wait(30) do
                pcall(atualizarTextoBotao)
            end
        end)

        return botaoRaid ~= nil
    end

    -- Executar inicialização com tentativas
    local tentativas = 0
    local maxTentativas = 5
    local sucesso = false

    while not sucesso and tentativas < maxTentativas do
        tentativas = tentativas + 1
        sucesso = pcall(function()
            return inicializar()
        end)

        if not sucesso then
            warn("⚠️ Tentativa " .. tentativas .. " falhou. Tentando novamente em 2 segundos...")
            wait(2)
        end
    end

    if not sucesso then
        warn("⚠️⚠️⚠️ FALHA CRÍTICA: Não foi possível inicializar o sistema após " .. maxTentativas .. " tentativas!")
    else
        print("✓✓✓ Sistema de monitoramento de raid inicializado com sucesso!")
    end




    Tabs.Main:AddSlider("Slider", {
        Title = "Walkspeed",
        Description = "",
        Default = 16,
        Min = 0,
        Max = 400,
        Rounding = 1,
        Callback = function(Value)
            currentValue = 16
            if currentLoop then
                currentLoop:Disconnect()
                currentLoop = nil
            end

            currentValue = tonumber(Value) or 16

            if currentValue > 0 then
                currentLoop = RunService.Heartbeat:Connect(function()
                    local character = localPlayer.Character
                    if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                        character.Humanoid.WalkSpeed = 16
                        local direction = character.Humanoid.MoveDirection
                        if direction.Magnitude > 0 then
                            local speedMultiplier = 1.2
                            local additionalMovement = direction * (currentValue / 100) * speedMultiplier
                            character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame + additionalMovement
                        end
                    end
                end)
            end
        end
    })



    local AntiAfk = false
    Tabs.AutoFarm:AddToggle("AntiAfk", {
        Title = "Anti AFK",
        ButtonName = "Anti AFK",
        Default = false,
        Description = "Activates/Deactivates Anti AFK",
        Callback = function(value)
            AntiAfk = value
            task.spawn(function()
                while AntiAfk do
                    pcall(function()
                        local keys = {0x5A, 0x58, 0x56, 0x4C} -- Z, X, V, L
                        local randomKey = keys[math.random(1, #keys)]
                        keypress(randomKey)
                        task.wait(0.05)
                        keyrelease(randomKey)
                    end)
                    task.wait(3)
                end
            end)
        end
    })
end


-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- InterfaceManager (Allows you to have a interface managment system)

-- Hand the library over to our managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- You can add indexes of elements the save manager should ignore
SaveManager:SetIgnoreIndexes({})

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/specific-game")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)


Window:SelectTab(1)

Fluent:Notify({
    Title = "Fluent",
    Content = "The script has been loaded.",
    Duration = 8
})

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()

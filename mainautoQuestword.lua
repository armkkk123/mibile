local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "🔥 โหมดทดสอบปุ่มพ่นไฟ Mobile",
   LoadingTitle = "Dragon Adventures Mobile Tester",
   LoadingSubtitle = "by Antigravity",
   Theme = "DarkBlue",
})

local Tab = Window:CreateTab("🧪 เมนูทดสอบ", 4483362458)
local LP = game.Players.LocalPlayer

-- ฟังก์ชันค้นหาเส้นทางปุ่มบนมือถือ
local function getFireButton()
    local JumpBtn = LP:FindFirstChild("PlayerGui") 
        and LP.PlayerGui:FindFirstChild("HUDGui") 
        and LP.PlayerGui.HUDGui:FindFirstChild("BottomFrame") 
        and LP.PlayerGui.HUDGui.BottomFrame:FindFirstChild("MobileControlsFrame") 
        and LP.PlayerGui.HUDGui.BottomFrame.MobileControlsFrame:FindFirstChild("TouchControlFrame") 
        and LP.PlayerGui.HUDGui.BottomFrame.MobileControlsFrame.TouchControlFrame:FindFirstChild("JumpButton") 
        
    local fireBtn = JumpBtn and JumpBtn:FindFirstChild("Frame") and JumpBtn.Frame:FindFirstChild("Fire")
    return JumpBtn, fireBtn
end

-- ฟังก์ชันรีฟิลหลอดพ่นไฟ
local function refillDragonBreathFuel(dragon)
    pcall(function()
        if dragon then
            local df = dragon:FindFirstChild("CurrentBreathFuel")
            local mf = dragon:FindFirstChild("MaxBreathFuel")
            if df and mf then
                df.Value = mf.Value
                if dragon:FindFirstChild("Remotes") and dragon.Remotes:FindFirstChild("ActionSync") then
                    dragon.Remotes.ActionSync:FireServer("BreathFuel", mf.Value)
                end
            end
        end
    end)
end

-- ดึงมังกรปัจจุบัน
local function getActiveDragonModel()
    local dragonsFolder = workspace:FindFirstChild("PlayerDragons")
    if not dragonsFolder then return nil end
    for _, dragon in ipairs(dragonsFolder:GetChildren()) do
        local ownerObj = dragon:FindFirstChild("Owner")
        if ownerObj and ownerObj.Value == LP then
            return dragon
        end
    end
    return nil
end

Tab:CreateButton({
   Name = "วิธีที่ 1: Remote Event (แบบตรงๆ ของ PC)",
   Callback = function()
        local dragon = getActiveDragonModel()
        local breathR = dragon and dragon:FindFirstChild("Remotes") and dragon.Remotes:FindFirstChild("BreathFireRemote")
        if dragon then refillDragonBreathFuel(dragon) end
        
        if breathR then
            Rayfield:Notify({Title = "ทดสอบ 1", Content = "กำลังส่งคำสั่ง FireServer", Duration = 2})
            breathR:FireServer(true)
            task.wait(2)
            breathR:FireServer(false)
        else
            Rayfield:Notify({Title = "Error", Content = "ไม่พบ Remote หรือมังกรยังไม่เกิด", Duration = 2})
        end
   end,
})

Tab:CreateButton({
   Name = "วิธีที่ 2: Signal & GetConnections (แฮกพุ่ม UI)",
   Callback = function()
        local JumpBtn, fireBtn = getFireButton()
        if not JumpBtn then 
            Rayfield:Notify({Title = "Error", Content = "หาปุ่มบนจอไม่เจอ (ต้องขี่มังกรบนมือถือ)", Duration = 2})
            return 
        end
        
        Rayfield:Notify({Title = "ทดสอบ 2", Content = "กำลังใช้ FireSignal ยิงเข้า UI โดยตรง", Duration = 2})
        local targets = {fireBtn, JumpBtn}
        if firesignal or getconnections then
            for _, target in ipairs(targets) do
                if target and target:IsA("GuiObject") then
                    local mockInput = {UserInputType = Enum.UserInputType.Touch, UserInputState = Enum.UserInputState.Begin}
                    if firesignal then
                        pcall(function() firesignal(target.InputBegan, mockInput) end)
                        pcall(function() firesignal(target.MouseButton1Down) end)
                        pcall(function() firesignal(target.Activated) end)
                        pcall(function() firesignal(target.TouchTap) end)
                    end
                    if getconnections then
                        pcall(function()
                            for _, conn in pairs(getconnections(target.InputBegan)) do conn:Fire(mockInput) end
                            for _, conn in pairs(getconnections(target.MouseButton1Down)) do conn:Fire() end
                            for _, conn in pairs(getconnections(target.Activated)) do conn:Fire() end
                        end)
                    end
                end
            end
        end
   end,
})

Tab:CreateButton({
   Name = "วิธีที่ 3: VIM จำลองเมาส์คลิก (เหมือนใช้นิ้วเคาะ)",
   Callback = function()
        local JumpBtn, fireBtn = getFireButton()
        if not fireBtn then return end
        
        Rayfield:Notify({Title = "ทดสอบ 3", Content = "กำลังจำลองคลิกเมาส์กึ่งกลางปุ่ม", Duration = 2})
        local inset, _ = game:GetService("GuiService"):GetGuiInset()
        local cx = fireBtn.AbsolutePosition.X + (fireBtn.AbsoluteSize.X / 2) + inset.X
        local cy = fireBtn.AbsolutePosition.Y + (fireBtn.AbsoluteSize.Y / 2) + inset.Y
        
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
        task.wait(1)
        vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
   end,
})

Tab:CreateButton({
   Name = "วิธีที่ 4: VIM จำลองทัชสกรีน (ทดสอบระบบจอ)",
   Callback = function()
        local JumpBtn, fireBtn = getFireButton()
        if not fireBtn then return end
        
        Rayfield:Notify({Title = "ทดสอบ 4", Content = "กำลังจำลองปลายนิ้วแตะกึ่งกลางปุ่ม", Duration = 2})
        local inset, _ = game:GetService("GuiService"):GetGuiInset()
        local cx = fireBtn.AbsolutePosition.X + (fireBtn.AbsoluteSize.X / 2) + inset.X
        local cy = fireBtn.AbsolutePosition.Y + (fireBtn.AbsoluteSize.Y / 2) + inset.Y
        
        local vim = game:GetService("VirtualInputManager")
        vim:SendTouchEvent(22, 0, cx, cy)
        task.wait(1)
        vim:SendTouchEvent(22, 2, cx, cy)
   end,
})

Rayfield:Notify({Title = "🔥 พร้อมทดสอบ", Content = "ให้ลูกพี่ขี่มังกร แล้วกดปุ่มทดสอบทีละวิธนะีครับ", Duration = 4})

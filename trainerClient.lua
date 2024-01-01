--[[
Controls the NPC and has the NPC checks

Author: JoePlato
Version: 1/1/2024

 
]]
--Services(Run By roblox)
local repStorage     = game:GetService("ReplicatedStorage")
local Players        = game:GetService("Players")
local chatService    = game:GetService("Chat")
local tweenService   = game:GetService("TweenService")
local UIS            = game:GetService("UserInputService")

--Constants(DO NOT CHANGE)
local plr            = Players.LocalPlayer
local character      = plr.Character
local humanoid       = character.Humanoid
local humanoidRoot   = character.HumanoidRootPart
local curCam         = workspace.CurrentCamera

local trainingParts  = workspace.trainingParts            
local trainerCam     = trainingParts.trainerCam
local trainerPad     = trainingParts.trainerPad         -- This section references the workspace parts that are not the NPC
local trainerPos     = trainerPad.Epico
local facesCam       = trainingParts.facesCam

local interAction    = trainingParts.interAction         -- This is the part where the player runs into it to start

local trainerGui     = plr.PlayerGui:WaitForChild("trainerGui")
local fadeFrame      = trainerGui.Frame

local pads           = trainingParts.Pads        --can add more pads just make there name the next number
local padsTaken      = pads.PadsTaken

local trainerEvents  = repStorage.trainerEvents
local functions      = trainerEvents.functions
local models         = trainerEvents.models             --These are all the stuff in repliucated storage that allow the server and client to comunicate
local events         = trainerEvents.events
local walkToParts    = trainingParts.walkToParts
local initilize      = events.initilize
local finalize       = events.finalize

local NPC            = models.TrainingNPC:Clone() -- Model can be changed(dont delete body parts)
local npcRoot        = NPC.HumanoidRootPart
local NPCHead        = NPC.Head
local animateScript  = script.Parent:WaitForChild("npcAnimate")          --This section references the trainer NPC in the workspace
local aciveAn        = script.activateAnimations
local emoteEvent     = animateScript.PlayEmote
local sflPart        = NPC.sflPart



--Variables(editable via the script)
local wrongStuff     = 0
local currentPad
local min
local max
local PadsOr 
local hasKicked      = false
--Settings(Edit depending on your games preferences)
local Info           = TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.InOut,0,false,0)    --These are the values for tweening the NPC(when it rotates)     
local pos1           = walkToParts.pos1  --These are for the posittion that the NPC walks to
local pos2           = walkToParts.pos2
local pos3           = walkToParts.pos3
--functions
function pickPad(padsNum)
	--[[
	determines which pad the player will stand on
	
	Args:
		padsNum(int): The pad number the player should be standing on
	]]
	local pickedPad = pads[tostring(padsNum)]
	currentPad = pickedPad
	playerWalk(pickedPad.Epico.Position)
	
	humanoidRoot.CFrame = pickedPad.Epico.CFrame
end

function tweenCamera()
	--[[
	Tweens the cam to face the NPC
	
	]]
	local TI = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local Goal = {CFrame = trainerCam.CFrame}
	local An = tweenService:Create(curCam, TI, Goal)
	curCam.CameraType = Enum.CameraType.Scriptable
	An:Play()
	task.wait(3)
end

function npcChat(input,waitTime)
	--[[
	uses roblox chat service to make the NPC speak
	
	Args:
		input(object):  is an object off strings containing diolauge
		waitTime(float): how long until the NPC says the next thing
	]]
	for _, section in pairs(input) do
		chatService:Chat(NPCHead,section,"White")
		if waitTime then
			task.wait(waitTime)
		else
			task.wait(3)
		end
	end
	
end

function TM(Model,CF)
	--[[
	Tweens the NPC towards a given CFrame 
	
	Args:
		Model(model): References the NPC
		CF(CFrame): the CFrame that the model should match
	]]
	local DummyValue=Instance.new('CFrameValue')
	DummyValue.Value=Model:GetPrimaryPartCFrame()
	DummyValue:GetPropertyChangedSignal('Value'):Connect(function()
		Model:SetPrimaryPartCFrame(DummyValue.Value)
	end)
	local Tween = tweenService:Create(DummyValue,Info,{Value=CF})
	Tween:Play()
	task.wait(1)
	DummyValue:Destroy()
end

function fadeUi(fadeType)
	--[[
	Fades in an out of the training UI
	
	Args:
		fadeType(string): checks if the transparency of the frame increase gradually or decrease
	]]
	if fadeType == "in" then
		repeat task.wait()
			fadeFrame.BackgroundTransparency = fadeFrame.BackgroundTransparency + 0.1
		until fadeFrame.BackgroundTransparency >= 1
	elseif  fadeType == "out" then
		repeat task.wait()
			fadeFrame.BackgroundTransparency = fadeFrame.BackgroundTransparency - 0.1
		until fadeFrame.BackgroundTransparency <= 0
	end
end

function turnChat(input)
	--[[
	Main function that runs the turns check
	
	Args:
		input(string): checks what typer of Turn it is
	]]
	PadsOr = currentPad.Epico.Orientation.Y
	npcChat({'That is a '..input..' now you try. You will have 5 seconds'})
	if input == "Right Turn" then
		currentPad.Epico.Orientation = Vector3.new(0,PadsOr-90,0)
		chatService:Chat(NPCHead,"Right, Turn!","White")
	elseif input == "Left Turn" then
		currentPad.Epico.Orientation = Vector3.new(0,PadsOr+90,0)
		chatService:Chat(NPCHead,"Left, Turn!","White")
	elseif input == "Centre Turn" then
		currentPad.Epico.Orientation = currentPad.Orientation 
		chatService:Chat(NPCHead,"Centre, Turn!","White")
		
	end
	min = currentPad.Epico.Orientation.Y-10
	max = currentPad.Epico.Orientation.Y+10
	task.wait(5)
	local CheckRot = CheckRotation(Vector3.new(0,min,0), Vector3.new(0,max,0), true)
	if CheckRot then
		chatService:Chat(NPCHead,"Great Job","White")
		task.wait(3)
	else
		chatService:Chat(NPCHead,"Thats incorrect, you should have faced this way!","White")
		humanoidRoot.CFrame = currentPad.Epico.CFrame
		task.wait(3)
	end
end

function CheckRotation(RotationAmountMin, RotationAmountMax, Check)
	--[[
	Helper function of turnChat to check the players rotation  
	
	Args:
		RotationAmountMin(float): Minimum a player can be off the rotation value
		RotationAmountMax(float): Maximum a player can be off the rotation value
		Check(bool): Value for latter use default set to true
	Returns:
		boolean: If the player is facing the proper direction
	]]
	print(game.Players.LocalPlayer.Character.HumanoidRootPart.Orientation.Y)
	if Check and currentPad.Epico.Orientation.Y-10 <= -180 or currentPad.Epico.Orientation.Y+10 >= 180 then
		if game.Players.LocalPlayer.Character.HumanoidRootPart.Orientation.Y >= -180 and game.Players.LocalPlayer.Character.HumanoidRootPart.Orientation.Y <= -170 or game.Players.LocalPlayer.Character.HumanoidRootPart.Orientation.Y >= 170 and game.Players.LocalPlayer.Character.HumanoidRootPart.Orientation.Y <= 180 then
			
			return true
		else
			return false
		end
	else
		if game.Players.LocalPlayer.Character.HumanoidRootPart.Orientation.Y >= RotationAmountMin.Y and game.Players.LocalPlayer.Character.HumanoidRootPart.Orientation.Y <= RotationAmountMax.Y then
		
			return true
		else
			return false
		end
	end
end
function npcWalk(Position)
	-- Makes the NPC walk to the position of Position
	repeat task.wait(0.01)
		NPC.Humanoid:MoveTo(Position)
	until (NPC.HumanoidRootPart.Position - Position).magnitude <= 2.5
	
end

function playerWalk(Position)
	-- Makes the player walk to the position of Position
	repeat task.wait()
		humanoid:MoveTo(Position)
	until (humanoidRoot.Position - Position).magnitude <= 2.5

end

function checkBehind()
	--Checks if the player is drectly behind the NPC with around 0.05 error
	repeat task.wait() 
		local humLookVector = character.Head.CFrame.LookVector
		local NPClookVector = NPC.Head.CFrame.LookVector
		local dotProduct = humLookVector:Dot(NPClookVector)
	until dotProduct > 0.95
	playerWalk(sflPart.Position)
	humanoid.WalkSpeed = 0
	humanoid.JumpHeight = 0
end

local function initJump()
	--Checks if the player has jumped when they should have  
	print("init jumping")
	humanoid.JumpHeight = 7.2
	UIS.InputBegan:Connect(function(key)
		if key.KeyCode == Enum.KeyCode.Space then
			hasKicked = true
			task.wait()
			humanoid.JumpHeight = 0
		end
	end)
end

function checkKick()
	--Runs through the diolauge for checking if the player has kicked
	if hasKicked then
		chatService:Chat(NPCHead,"Good Job For kicking","White")
		task.wait(3)
		chatService:Chat(NPCHead,"MARCH!","White")
	else
		chatService:Chat(NPCHead,"You should have kicked like this!","White")
		task.wait(1)
		humanoid.Jump = true
		task.wait(3)
		chatService:Chat(NPCHead,"MARCH!","White")
	end
end
function checkIncor()
	--Checks if you got more than 2 questions wrong on ther quiz
	if wrongStuff > 2 then
		plr:Kick("You failed rejoin to try again")
	end
end
--event
NPC.Parent         = trainingParts -- These couple lines of code before initilize spawn in the NPC only on the client side so that others can not see it.
npcRoot.CFrame     = trainerPos.CFrame
npcRoot.Anchored   = true
aciveAn:Fire(NPC) --Animates the NPC
initilize.OnClientEvent:Connect(function(padsTaken,introSpeech,turnsIntroSpeech,rightTurnSpeech,leftTurnSpeech,cenTurnSpeech,sflSpeech,kickSpeech)
	--[[
	Main event function that kicks off the process  
	
	Args:
		padsTaken(int): The pad number that the player is suposed to stand on
		...Speech(object): Object of strings that contyains the the NPC diolague
	]]
	local taskCoro       = coroutine.create(initJump) --Allows This function to run seperatly from the overall stuff(multi threading :) )
	emoteEvent:Invoke("wave")
	pickPad(padsTaken)
	tweenCamera()
	npcChat(introSpeech)
	npcChat(turnsIntroSpeech)
	npcChat(rightTurnSpeech)
	fadeUi("out")
	NPC.HumanoidRootPart.CFrame = NPC.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(180), 0)
	curCam.CameraType = Enum.CameraType.Scriptable
	curCam.CFrame = trainerCam.CFrame
	fadeUi("in")
	local c = NPC.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(-90), 0)
	TM(NPC,c)
	task.wait(2)
	curCam.CameraType = Enum.CameraType.Custom
	NPC.HumanoidRootPart.CFrame = NPC.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(-90), 0)
	turnChat("Right Turn")
	chatService:Chat(NPCHead,"Now try another turn on your own.","White")
	turnChat("Right Turn")
	npcChat(leftTurnSpeech)
	fadeUi("out")
	curCam.CameraType = Enum.CameraType.Scriptable
	curCam.CFrame = facesCam.CFrame
	fadeUi("in")
	TM(NPC,NPC.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(90), 0))
	task.wait(2)
	NPC.HumanoidRootPart.CFrame = NPC.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(-90), 0)
	curCam.CameraType = Enum.CameraType.Custom
	turnChat("Left Turn")
	npcChat(cenTurnSpeech)
	fadeUi("out")
	curCam.CameraType = Enum.CameraType.Scriptable
	curCam.CFrame = facesCam.CFrame
	fadeUi("in")
	TM(NPC,NPC.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(180), 0))
	task.wait(2)
	NPC.HumanoidRootPart.CFrame = NPC.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(180), 0)
	curCam.CameraType = Enum.CameraType.Custom
	turnChat("Centre Turn")
	checkIncor()
	npcRoot.Anchored   = false
	npcWalk(pos1.Position)
	npcWalk(pos2.Position)
	NPC.HumanoidRootPart.CFrame = pos2.CFrame
	task.wait(0.1)
	npcRoot.Anchored   = true
	npcChat(sflSpeech,5)
	checkBehind()
	npcChat(kickSpeech)
	coroutine.resume(taskCoro)
	task.wait(5)
	coroutine.close(taskCoro)
	checkKick()
	npcRoot.Anchored = false
	task.spawn(function() --Does a similar thing to the coroutine 
		npcWalk(pos3.Position)
	end)
	humanoid.WalkSpeed = 16
	task.wait(1)
	task.spawn(function()
		playerWalk(pos3.Position)	
	end)
	task.wait(2)
	fadeUi("out")
	task.wait(0.5)
	finalize:FireServer() --This last part is the ending section of the stuff
	NPC:Destroy()
	fadeUi("in")
	task.wait(1)
	
	script.Disabled = true
end)

local MorphService = {
	StorageLocationCache = {}
}

-- // Types
export type MorphType = "Accessory" | "Appearance" -- Accessory for gear, hats, clothing. Appearance for ears, hair, beards, etc
export type MorphDataOptions = {
	Character: Model, -- Player character
	Morph: Model, -- Morph model
	Type: MorphType,
	Decorators: {(Character: Model) -> nil}?, -- Additional functions
	Options: {
		OverwriteExistingMorphs: boolean?, -- Delete existing morphs --> default: false
		IncludeExtraInstances: boolean?, -- Include instances inside the morph e.g. Clothing, BodyColor --> default: false
		StorageLocation: Folder? -- Where the morph folder is e.g. Character --> default: Character
	}?
}

-- // Private Functions
local function WeldParts(Part0: BasePart, Part1: BasePart, Name: string): Weld
	local Weld = Instance.new("Weld")
	Weld.Name = Name or "Weld"
	
	Weld.Part0 = Part0
	Weld.Part1 = Part1
	
	Weld.C0 = CFrame.new()
	Weld.C1 = Part1.CFrame:ToObjectSpace(Part0.CFrame)
	
	Weld.Parent = Part0
	return Weld
end

local function ApplyMorphToCharacter(Data: MorphDataOptions)
	local Options = Data.Options
	
	if Options then
		if Options.IncludeExtraInstances then
			for _, Child: Instance in ipairs(Data.Morph:GetChildren()) do
				if Child:IsA("Model") then continue end

				Child:Clone().Parent = Data.Character
			end
		end
		
		if Options.OverwriteExistingMorphs then
			local MorphFolder = MorphService.GetMorphStorageFolder(Data.Character)
			if MorphFolder then
				MorphFolder:ClearAllChildren()
			end
		end
	end
	
	for _, MorphLimb in ipairs(Data.Morph:GetChildren()) do
		if not MorphLimb:IsA("Model") then continue end
		
		local BodyPart = Data.Character:FindFirstChild(MorphLimb.Name)
		if not BodyPart or not BodyPart:IsA("BasePart") then return warn(`{script.Name} :: Morph limb '{MorphLimb.Name}' is not a BasePart or does not exist in character`) end
		
		local MorphFolder = MorphService.GetMorphStorageFolder(Data.Character)
		if not MorphFolder then
			MorphFolder = MorphService.CreateMorphStorageFolder(Data.Character, Options and Options.StorageLocation or Data.Character)
		end
		
		local Morph = MorphLimb:Clone()
		Morph.Name = `Limb_{MorphLimb.Name}`
		Morph:SetAttribute("MorphType", Data.Type)
		
		Morph:PivotTo(BodyPart.CFrame)
		Morph.PrimaryPart:Destroy()
		
		if #Morph:GetChildren() <= 0 then
			Morph:Destroy()
			return
		end
		
		for _, Part: BasePart in ipairs(Morph:GetDescendants()) do
			if not Part:IsA("BasePart") then continue end
			print(Part)
			
			Part.Massless = true
			Part.CanCollide = false
			Part.CanQuery = false
			Part.CanTouch = false
			Part.Anchored = false
			
			WeldParts(BodyPart, Part, `{Data.Type}Weld`)
		end
		
		Morph.Parent = MorphFolder
	end
end

-- // Public Functions
function MorphService.RemoveAccesoies(Character: Model)
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid then return warn(`Humanoid is nil in character '{Character.Name}'`) end
	
	Humanoid:RemoveAccessories()
end

function MorphService.RemoveCharacterClothing(Character: Model)
	for _, Clothing in ipairs(Character:GetChildren()) do
		if not Clothing:IsA("Clothing") and not Clothing:IsA("ShirtGraphic") then continue end
		
		Clothing:Destroy()
	end
end

function MorphService.RemovePackage(Character: Model)
	local Head = Character:FindFirstChild("Head")
	
	if Head and Head:FindFirstChild("Mesh") then
		Head:FindFirstChild("Mesh"):Destroy()
		
		local NewMesh = Instance.new("SpecialMesh")
		NewMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
		NewMesh.Parent = Head
	end
	
	for _, CharacterMesh in ipairs(Character:GetChildren()) do
		if not CharacterMesh:IsA("CharacterMesh") then continue end
		
		CharacterMesh:Destroy()
	end
end

function MorphService.CreateMorphStorageFolder(Character: Model, Parent: Instance, Name: string?): Folder
	local StorageFolder = Instance.new("Folder")
	StorageFolder.Name = Name or `{Character.Name}_Morph`
	StorageFolder.Parent = Parent
	
	return StorageFolder
end

function MorphService.GetMorphStorageFolder(Character: Model): Folder?
	local FoundFolder = Character:FindFirstChild(`{Character.Name}_Morph`, true)
	
	if FoundFolder then
		return FoundFolder
	end
	
	for Index, StorageFolder in ipairs(MorphService.StorageLocationCache) do
		if StorageFolder == nil then table.remove(MorphService.StorageLocationCache, Index) end
		
		if typeof(StorageFolder) == "Instance" and StorageFolder:IsA("Folder") then
			FoundFolder = StorageFolder:FindFirstChild(`{Character.Name}_Morph`, true)
			
			if FoundFolder and FoundFolder:IsA("Folder") then
				return FoundFolder
			end
		end
	end
	
	return nil
end

function MorphService:ApplyMorph(Data: MorphDataOptions)
	local DecoratorFunctions = Data.Decorators
	local Options = Data.Options

	if Options and Options.StorageLocation then
		MorphService.StorageLocationCache[Options.StorageLocation.Name] = Options.StorageLocation
	end

	if DecoratorFunctions then
		for _, Function in ipairs(DecoratorFunctions) do
			pcall(Function, Data.Character)
		end
	end

	ApplyMorphToCharacter(Data)
end

return MorphService

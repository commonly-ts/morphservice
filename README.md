# MorphService
Source code from Morphs and Custom Characters tutorial: https://www.youtube.com/watch?v=_ZMzPdyh6jE

# Setup
Copy paste the code into a `ModuleScript` and place it inside either `ReplicatedStorage`, `ServerScriptService` or `ServerStorage`. There is a R6 Morph Template RBXM file which contains a dummy that you can place objects onto to create a morph.

# Applying Morphs

Example R6 morph layout

![image](https://github.com/user-attachments/assets/5962f54b-7ffd-43d2-bee2-6938f1bb2c71)

By default, morphs containing shirt and pants will be automatically applied. Models inside the morph must be named as body parts in a character. Each body part model should contain a "middle" part that is a reference point for where parts inside that body part will be placed.

Example code for applying a morph when a player spawns
```luau
-- Services
local PlayerService = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Variables
local MorphService = require(ServerStorage:FindFirstChild("MorphService"))
local MorphTempalte = ServerStorage:FindFirstChild("Morph")

-- Connections
PlayerService.PlayerAdded:Connect(function(Player)
	-- Using CharacterAppearanceLoaded to avoid character loading overriding morphs
	Player.CharacterAppearanceLoaded:Connect(function(Character)
		-- Init morph settings
		local MorphData: MorphService.MorphDataOptions = {
			Character = Character,
			Morph = MorphTempalte,
			Type = "Accessory", -- "Accessory" for gear, hats, clothing. "Appearance" for ears, hair, beards, etc
			Options = {
				OverwriteExistingMorphs = true, -- Whether to add two or more morphs together or remove any existing one
				IncludeExtraInstances = true -- Whether to insert instances inside the Morph model other than clothing and models
			},
			Decorators = { -- Different functions that can be applied
				MorphService.RemovePackage,
				MorphService.RemoveCharacterClothing,
				MorphService.RemoveAccesoies
			}
		}

		-- Apply the morph
		MorphService:ApplyMorph(MorphData)
		
	end)
end)
```

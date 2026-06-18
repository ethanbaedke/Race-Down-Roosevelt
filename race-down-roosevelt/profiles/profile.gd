class_name Profile extends Resource

@export var name:String = "New Player"
@export var icon:CompressedTexture2D = preload("res://profiles/empty_profile_icon.png")

# Copys all data (shallow) from another profile to this profile.
# This is primarily used for saving profile edits, where a temporary copy is used.
func copy_profile(other:Profile) -> void:
	
	self.name = other.name
	self.icon = other.icon

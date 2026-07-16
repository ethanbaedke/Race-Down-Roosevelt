class_name ItemData extends Resource

enum ItemType {
	BOOST,
	INVINCIBILITY,
	AI,
	SPEED,
}

@export var item_name:String = "New Item"
@export var item_icon:CompressedTexture2D = preload("res://profiles/diamond_profile_icon.png")
@export var item_type:ItemType = ItemType.BOOST

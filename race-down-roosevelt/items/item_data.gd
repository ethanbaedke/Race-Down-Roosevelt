class_name ItemData extends Resource

enum ItemType {
	BOOST,
}

@export var item_icon:CompressedTexture2D = preload("res://profiles/diamond_profile_icon.png")
@export var item_type:ItemType = ItemType.BOOST

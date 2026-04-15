class_name HexData
extends Resource

enum ClueType {
	DEFAULT, # Not a special clue, just a normal number
	CIRCLE,
	TRIANGLE,
	RECTANGLE,
}

@export var number: int
@export var state: Hex.State
@export var given: bool
@export var clue_type: ClueType
@export_flags(
		"Top Left",
		"Top",
		"Top Right",
		"Bottom Right",
		"Bottom",
		"Bottom Left",
		) var borders: int


func _init(p_number: int = 0, p_state: Hex.State = Hex.State.NORMAL, p_given: bool = false,
		p_clue_type: ClueType = ClueType.DEFAULT, p_borders: int = 0) -> void:
	number = p_number
	state = p_state
	given = p_given
	clue_type = p_clue_type
	borders = p_borders

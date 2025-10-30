class_name HexData
extends Resource

@export var number: int
@export var state: Hex.State
@export var given: bool


func _init(p_number: int = 0, p_state: Hex.State = Hex.State.NORMAL, p_given: bool = false) -> void:
	number = p_number
	state = p_state
	given = p_given

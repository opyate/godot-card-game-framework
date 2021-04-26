class_name CFMatchObject
extends HBoxContainer

var match_maker
var match_id: String

onready var match_name := $MatchName

func _ready() -> void:
	pass

func setup(_match_name, _match_id, _match_maker) -> void:
	match_name.text = _match_name
	match_id = _match_id
	match_maker = _match_maker
	

func _on_JoinMatch_pressed() -> void:
	match_maker.nakama_client.join_match(match_id)
	match_maker.current_match_name_label.text = match_name.text
	

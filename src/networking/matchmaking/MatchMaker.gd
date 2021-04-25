class_name CFMatchMaker
extends PanelContainer

const _MATCH_OBJECT_SCENE_PATH = CFConst.NAKAMA_MATCHMAKING_PATH + "MatchObject.tscn"
const _MATCH_OBJECT_SCENE = preload(_MATCH_OBJECT_SCENE_PATH)
export(PackedScene) var match_object_scene = _MATCH_OBJECT_SCENE

# If I set the variable directly here, for some reason the static typing
# stops working
onready var nakama_client : CFNakamaClient
onready var authenticate_button = $VBC/HBC/Authenticate
onready var connection_status = $VBC/HBC/ConnectionStatus
onready var new_match_name = $VBC/HBoxContainer/NewMatchName
onready var matches_list = $VBC/HSplitContainer/ScrollContainer/Matches
onready var _timer = $LobbyRefresh

func _ready() -> void:
	nakama_client = cfc.nakama_client
	if cfc.game_settings.has('nakama_auth_token'):
		var session = nakama_client.restore_session()
		if session is GDScriptFunctionState:
			session = yield(session, "completed")
		new_match_name.text = session.username + "'s game"
	authenticate_button.get_popup().connect("index_pressed", self, "_on_auth_selected")
	nakama_client.socket.connect("received_notification", self, "_on_notification")
	_timer.connect("timeout", self, "refresh_available_matches")


func _on_CreateMatch_pressed() -> void:
#	var new_match = nakama_client.create_match()
#	if new_match is GDScriptFunctionState:
#		new_match = yield(new_match, "completed")
#	if new_match.is_exception():
#		return
	var payload := {"label": new_match_name.text}
	var new_match: NakamaAPI.ApiRpc = yield(
			nakama_client.client.rpc_async(
			nakama_client.session, "create_match", JSON.print(payload)),
			"completed"
	)
#	print_debug(new_match)


func _on_auth_selected(index: int) -> void:
	var pop : PopupMenu = authenticate_button.get_popup()
	var session: NakamaSession = yield(
			nakama_client.authenticate(pop.get_item_text(index), 'CGFNakamaDemo'), 
			"completed"
	)
	nakama_client.authenticate(pop.get_item_text(index), 'CGFNakamaDemo')
	nakama_client.curr_email = pop.get_item_text(index)
	nakama_client.curr_pass = 'CGFNakamaDemo'
	connection_status.text = "Authenticated As: " + pop.get_item_text(index)
	new_match_name.text = session.username + "'s game"


func _on_LineEdit_text_entered(new_text: String) -> void:
	nakama_client.join_match(new_text)

func refresh_available_matches() -> void:
	if not nakama_client.session.valid or nakama_client.session.expired:
		return
#	print_debug(nakama_client.session.valid, nakama_client.session.expired)
	var matches: NakamaAPI.ApiRpc = yield(
		nakama_client.client.rpc_async(nakama_client.session, "get_all_matches", ""), "completed"
	)
	var payload = JSON.parse(matches.payload).result
	for curr_match in payload:
		var match_listed = false
		for m in matches_list.get_children():
			m.queue_free()
		var match_object = match_object_scene.instance()
		matches_list.add_child(match_object)
		match_object.setup(curr_match.label, curr_match.match_id, self)
#	print_debug(matches.payload)

func _on_notification(p_notification : NakamaAPI.ApiNotification):
	print_debug(p_notification)
	print_debug(p_notification.content)


func _on_NewMatchName_text_entered(new_text: String) -> void:
	_on_CreateMatch_pressed()

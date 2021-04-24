class_name CFNakamaClient
extends Reference

const SCHEME = "http"
const HOST = "193.164.132.214"
const PORT = 7350
const SERVER_KEY = "card_game_framework"

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
var curr_email: String
var curr_pass: String

func _init() -> void:
	client = Nakama.create_client(SERVER_KEY, HOST, PORT, SCHEME)
	socket = Nakama.create_socket_from(client)
	if cfc.game_settings.has('nakama_auth_token'):
		restore_session()

func authenticate(email, password) -> bool:
	# Use yield(client.function(), "completed") to wait for the request to complete.
	session = yield(client.authenticate_email_async(email, password), "completed")
	cfc.set_setting('nakama_email', email)
	cfc.set_setting('nakama_auth_token', session.token)
	if session.is_valid():
		print("Authenticated with Nakama succesfully as " + email + ".")
		yield(socket.connect_async(session), "completed")	
	else:
		print("Nakama Authentication failed!")
	return(session.is_valid())
	
func restore_session() -> bool:
	session = NakamaClient.restore_session(cfc.game_settings.nakama_auth_token)
	if session.valid and not session.expired:
		print("Existing nakama session restored")
		yield(socket.connect_async(session), "completed")	
	else:
		if curr_email and curr_pass:
			authenticate(curr_email, curr_pass)
		else:
			print("Nakama session has expired. Please authenticate again!")
	return(session.is_valid())


func create_match() -> void:
	if not session.valid or session.expired:
		if curr_email and curr_pass:
			authenticate(curr_email, curr_pass)
	var created_match : NakamaRTAPI.Match = yield(socket.create_match_async(), "completed")
	if created_match.is_exception():
	  print("An error occured: %s" % created_match)
	  return
	print(created_match.match_id)

func join_match(match_id: String) -> void:
	var joined_match = yield(socket.join_match_async(match_id), "completed")
	if joined_match.is_exception():
		print("An error occured: %s" % joined_match)
		return
	for presence in joined_match.presences:
		print("User id %s name %s'." % [presence.user_id, presence.username])	

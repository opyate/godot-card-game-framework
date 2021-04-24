class_name CFNakamaClient
extends Reference

const SCHEME = "http"
const HOST = "193.164.132.214"
const PORT = 7350
const SERVER_KEY = "defaultkey"

var client: NakamaClient
var session: NakamaSession

func _init() -> void:
	client = nakama.create_client(SERVER_KEY, HOST, PORT, SCHEME)
	if not cfc.game_settings.has('nakama_auth_token'):
		authenticate("mail@dbzer0.com", "Start123$")
	else:
		restore_session()

func authenticate(email, password) -> bool:
	# Use yield(client.function(), "completed") to wait for the request to complete.
	session = yield(client.authenticate_email_async(email, password), "completed")
	cfc.set_setting('nakama_email', email)
	cfc.set_setting('nakama_auth_token', session.token)
	if session.is_valid():
		print("Authenticated with Nakama succesfully as " + email + ".")
	else:
		print("Nakama Authentication failed!")
	return(session.is_valid())
	
func restore_session() -> bool:
	var session = NakamaClient.restore_session(cfc.game_settings.nakama_auth_token)
	if session.valid and not session.expired:
		print("Existing nakama session restored")
	else:
		print("Nakama session has expired. Please authenticate again!")
		authenticate("mail@dbzer0.com", "Start123$")
	return(session.is_valid())

-- Module that controls the game world. The world's state is updated every `tickrate` in the
-- `match_loop()` function.

local match_control = {}

local nk = require("nakama")


-- Custom operation codes. Nakama specific codes are <= 0.
local OpCodes = {
    card_created = 1,
    card_deleted = 2,
    card_moved = 3,
    update_state = 4
}

-- Command pattern table for boiler plate updates that uses data and state.
local commands = {}

-- Updates the position in the game state
commands[OpCodes.card_created] = function(data, state)
    local card_id = data.card_id
    if state.cards[card_id] == nil then
        state.cards[card_id] = {}
		state.cards[card_id]["owner"] = data.owner
		state.cards[card_id]["name"] = data.card_name
		state.cards[card_id]["position"] = data.position
		state.cards[card_id]["container"] = data.container
	else
		state.cards[card_id]["owner"] = data.owner
		state.cards[card_id]["name"] = data.card_name
		state.cards[card_id]["position"] = data.position
		state.cards[card_id]["container"] = data.container
    end
end

-- Updates the horizontal input direction in the game state
commands[OpCodes.card_deleted] = function(data, state)
    local card_id = data.card_id
end

-- Updates whether a character jumped in the game state
commands[OpCodes.card_moved] = function(data, state)
    local card_id = data.card_id
end

-- When the match is initialized. Creates empty tables in the game state that will be populated by
-- clients.
function match_control.match_init(context, params)
    local gamestate = {
        presences = {},
		cards = {},
        names = {}
    }
    local tickrate = 10
	local label = "CGF Game"
	if params.label ~= nil then
		nk.logger_info("Set Name to label")
		label = params.label
	end
	nk.logger_info(string.format("Params: %s", nk.json_encode(params)))
	nk.logger_info(string.format("Game Label: %s", label))
	nk.logger_info(string.format("Game Label: %s", params.label))
    return gamestate, tickrate, label
end

-- When someone tries to join the match. Checks if someone is already logged in and blocks them from
-- doing so if so.
function match_control.match_join_attempt(_, _, _, state, presence, _)
    if state.presences[presence.user_id] ~= nil then
        return state, false, "User already logged in."
    end
    return state, true
end

-- When someone does join the match. Initializes their entries in the game state tables with dummy
-- values until they spawn in.
function match_control.match_join(_, dispatcher, _, state, presences)
    for _, presence in ipairs(presences) do
        state.presences[presence.user_id] = presence
        state.names[presence.user_id] = "User"
    end

    return state
end


function match_control.match_leave(_, _, _, state, presences)
    for _, presence in ipairs(presences) do
        state.presences[presence.user_id] = nil
        state.names[presence.user_id] = nil
    end
    return state
end

-- Called `tickrate` times per second. Handles client messages and sends game state updates. Uses
-- boiler plate commands from the command pattern except when specialization is required.
function match_control.match_loop(_, dispatcher, _, state, messages)
    for _, message in ipairs(messages) do
        local op_code = message.op_code

        local decoded = nk.json_decode(message.data)

        -- Run boiler plate commands (state updates.)
        local command = commands[op_code]
        if command ~= nil then
            commands[op_code](decoded, state)
        end
    end

    local data = {
        ["cards"] = state.cards
    }
    local encoded = nk.json_encode(data)

    dispatcher.broadcast_message(OpCodes.update_state, encoded)

    return state
end

function match_control.match_terminate(_, _, _, state, _)
    return state
end

return match_control

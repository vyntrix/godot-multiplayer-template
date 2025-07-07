extends Node

@export var app_id: String = "480"

const PACKET_READ_LIMIT: int = 32

var lobby_data
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 3
var lobby_vote_kick: bool = false
var steam_id: int = 0
var steam_username: String = ""

func _ready() -> void:
	initialize_steam()

	# Connect to Steam callbacks
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)
	Steam.lobby_data_update.connect(_on_lobby_data_update)

#region P2P Requests
func _on_lobby_data_update(_success: int, _lobby_id: int, _member_id: int):
	get_lobby_members()

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		# Successfully joined the lobby
		lobby_id = this_lobby_id
		get_lobby_members()
		make_p2p_handshake()
	else:
		# Failed to join the lobby, handle the error
		var fail_reason: String

		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."

		print_rich("[color=red]Failed to join this chat room: %s[/color]" % fail_reason)

# Handles an incoming P2P session request from a remote user.
# @param remote_id The Steam ID of the requester.
func _on_p2p_session_request(remote_id: int):
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	print("%s is requesting a P2P session" % this_requester)
	Steam.acceptP2PSessionWithUser(remote_id)
	get_lobby_members()
	make_p2p_handshake()

func _on_p2p_session_connect_fail(_steam_id: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with %s: no error given" % steam_id)
	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with %s: target user not running the same game" % steam_id)
	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with %s: local user doesn't own app / game" % steam_id)
	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with %s: target user isn't connected to Steam" % steam_id)
	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with %s: connection timed out" % steam_id)
	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with %s: unused" % steam_id)
	# Else no known error
	else:
		print("WARNING: Session failure with %s: unknown error %s" % [steam_id, session_error])

# Initiates a peer-to-peer handshake by sending a handshake packet to the peer with ID 0.
# The packet contains the local user's Steam ID and username.
#
# This function is typically used to establish an initial connection or verify identity
# between peers in a multiplayer session using Steam networking.
func make_p2p_handshake():
	send_p2p_packet(0, {"message": "handshake", "steam_id": steam_id, "username": steam_username})

# Sends voice data to peers via P2P packet.
# @param voice_data: PackedByteArray containing the encoded voice data to be sent.
# The packet includes the sender's Steam ID and username for identification.
func send_voice_data(voice_data: PackedByteArray):
	send_p2p_packet(1, {"voice_data": voice_data, "steam_id": steam_id, "username": steam_username})

# Sends a P2P packet to specified Steam lobby members or a specific target.
#
# @param this_target: int - Determines the packet's recipient(s):
#     0 - Sends to all lobby members except self on channel 0.
#     1 - Sends to all lobby members except self on channel 1.
#     Any other value - Sends to the specified Steam ID on channel 0.
# @param packet_data: Dictionary - The data to be sent, which will be serialized and transmitted.
#
# The function uses Steam's P2P networking to send reliable packets. It skips sending to self.
func send_p2p_packet(this_target: int, packet_data: Dictionary):
	var send_type: int = Steam.P2P_SEND_RELIABLE
	var channel: int = 0
	var this_data: PackedByteArray
	this_data.append_array(var_to_bytes(packet_data))
	if this_target == 0:
		if lobby_members.size() > 1:
			for member in lobby_members:
				if member["steam_id"] != steam_id:
					Steam.sendP2PPacket(member["steam_id"], this_data, send_type, channel)
	elif this_target == 1:
		print(lobby_members)
		if lobby_members.size() > 1:
			for member in lobby_members:
				if member["steam_id"] != steam_id:
					Steam.sendP2PPacket(member["steam_id"], this_data, send_type, 1)
	else:
		Steam.sendP2PPacket(this_target, this_data, send_type, channel)

func get_lobby_members():
	lobby_members.clear()
	var num_of_lobby_members: int = Steam.getNumLobbyMembers(lobby_id)
	for member in range(0, num_of_lobby_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)

		lobby_members.append({
			"steam_id": member_steam_id,
			"steam_name": member_steam_name
		})

# Reads all available P2P message packets up to a defined limit.
#
# This function recursively reads P2P packets using the Steam API until either:
# - No more packets are available, or
# - The specified PACKET_READ_LIMIT is reached.
#
# @param read_count The current number of packets read in this invocation (used for recursion and limiting).
func read_all_p2p_msg_packets(read_count: int = 0):
	if read_count >= PACKET_READ_LIMIT:
		return
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_msg_packet()
		read_all_p2p_msg_packets(read_count + 1)

# Reads all available P2P voice packets up to a specified limit.
#
# This recursive function checks for available P2P voice packets and processes them.
#
# @param read_count The current number of packets read in this invocation (default is 0).
func read_all_p2p_voice_packets(read_count: int = 0):
	if read_count >= PACKET_READ_LIMIT:
		return
	if Steam.getAvailableP2PPacketSize(1) > 1:
		read_p2p_voice_packet()
		read_all_p2p_voice_packets(read_count + 1)

# Reads an incoming P2P message packet from Steam networking.
# - Checks for available packet size and reads the packet if present.
# - Warns if a non-empty packet size yields an empty packet.
# - Extracts the sender's Steam ID and packet data.
# - Converts the packet data from bytes to a readable dictionary.
# - Handles specific message types, such as "handshake", and performs actions like printing join notifications and updating lobby members.
func read_p2p_msg_packet():
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)

		if this_packet.is_empty() or this_packet == null:
			print("WARNING: read an empty packet with non-zero size!")

		var _packet_sender: int = this_packet["remote_steam_id"]
		var packet_code: PackedByteArray = this_packet["data"]
		var readable_data: Dictionary = bytes_to_var(packet_code)

		if readable_data.has("message"):
			match readable_data["message"]:
				"handshake":
					print("PLAYER: ", readable_data["username"], " has joined.")
					get_lobby_members()

# Reads a P2P voice packet from Steam networking.
#
# This function checks for available P2P packets using Steam's API. If a packet is available,
# it reads the packet and extracts the sender's Steam ID and the packet data. The data is then
# deserialized into a readable dictionary. If the packet contains voice data, it locates the
# corresponding player in the scene and processes the voice data for that player.
#
# Warnings:
# - Prints a warning if a non-empty packet size is reported but the packet is empty or null.
func read_p2p_voice_packet():
	var packet_size: int = Steam.getAvailableP2PPacketSize(1)
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 1)

		if this_packet.is_empty() or this_packet == null:
			print("WARNING: read an empty packet with non-zero size!")

		var packet_sender: int = this_packet["remote_steam_id"]
		var packet_code: PackedByteArray = this_packet["data"]
		var readable_data: Dictionary = bytes_to_var(packet_code)

		#print("Packet: %s" % readable_data)

		if readable_data.has("voice_data"):
			print("reading ", readable_data["username"], "'s voice data.")
			var players_in_scene: Array = get_tree().get_nodes_in_group("players")
			for player in players_in_scene:
				if player.steam_id == packet_sender:
					player.process_voice_data(readable_data, "network")
				else:
					# TODO: ERROR CHECKING
					pass
#endregion

func initialize_steam() -> void:
	# Set the environment variables for Steam
	OS.set_environment("SteamAppId", app_id)
	OS.set_environment("SteamGameId", app_id)
	var initialize_response: Dictionary = Steam.steamInitEx()

	# Check if Steam initialized successfully
	if initialize_response["status"] == 0:
		print_rich("[color=green]Steam is Running![/color]")
		steam_id = Steam.getSteamID()
		steam_username = Steam.getPersonaName()

	# Check if Steam failed to initialize
	if initialize_response["status"] > Steam.STEAM_API_INIT_RESULT_OK:
		print_rich("[color=red]Failed to initialize Steam [/color] | Shutting Down: %s" % initialize_response)
		get_tree().quit()

	# Check if the user owns the game
	if !Steam.isSubscribed():
		print_rich("[color=red]User does not own this game.[/color]")
		get_tree().quit()

func _process(_delta: float) -> void:
	# If in a lobby, read all P2P message packets and voice packets
	if lobby_id > 0:
		read_all_p2p_msg_packets()
		read_all_p2p_voice_packets()

	# Run Steam callbacks to ensure proper communication with the Steam API
	Steam.run_callbacks()

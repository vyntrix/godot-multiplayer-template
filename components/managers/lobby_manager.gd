class_name LobbyManager extends Node

## INFO: Export variables
@export var network_manager: NetworkManager
@export var map_spawner: MultiplayerSpawner
@export var map_manager: MapManager
@export var menu_manager: MenuManager

@export_group("Local Lobby")
var local_lobby_id = 1
@export var local_addr: String = "127.0.0.1"
@export var local_port: int = 5000
@export var local_max_players: int = 4

@export_group("Steam Lobby")
var steam_lobby_id = 1
@export var lobby_v_box_container: VBoxContainer
@export var steam_local_max_players: int = 4

## INFO: Signals
signal on_singleplayer_lobby_created
signal on_local_lobby_created
signal on_steam_lobby_created

func _ready():
	map_spawner.spawn_function = map_manager.spawn_map
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_kicked.connect(_on_lobby_kicked)

	check_command_line()

func _on_lobby_kicked(lobby_id: int, _admin_id: int, _due_to_disconnect: int) -> void:
	Steam.leaveLobby(lobby_id)
	menu_manager.show_main_canvas()
	menu_manager.hide_all_menus()
	menu_manager._on_public_multiplayer_button_pressed()

func _on_lobby_joined(_lobby: int, _permissions: int, _locked: bool, response: int):
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		menu_manager.hide_main_canvas()

func _on_lobby_join_requested(_this_lobby_id: int, friend_id: int) -> void:
	var owner_name: String = Steam.getFriendPersonaName(friend_id)
	print("Joining %s's lobby..." % owner_name)

func check_command_line() -> void:
	var these_arguments: Array = OS.get_cmdline_args()
	if these_arguments.size() > 0:
		if these_arguments[0] == "+connect_lobby":
			if int(these_arguments[1]) > 0:
				print_rich("[color=green]Command line lobby ID[/color]: ", these_arguments[1])
				join_steam_lobby(int(these_arguments[1]))

#region Setup Methods
func setup_singleplayer_lobby():
	network_manager.reset_peer()

func setup_local_lobbies():
	network_manager.set_peer_mode(network_manager.PeerMode.LOCAL)
	network_manager.get_peer().peer_connected.connect(_on_local_player_connect_lobby)
	network_manager.get_peer().peer_disconnected.connect(_on_local_player_disconnect_lobby)

func setup_steam_lobbies():
	network_manager.set_peer_mode(network_manager.PeerMode.STEAM)
	network_manager.get_peer().lobby_created.connect(_on_steam_lobby_created)
	Steam.lobby_match_list.connect(_on_steam_lobby_match_list)
	open_steam_lobby_list()
#endregion

#region Creation Methods
func create_singleplayer_lobby():
	map_spawner.spawn(map_manager.lobby_scene_path)
	on_singleplayer_lobby_created.emit()

func create_local_lobby():
	if SteamManager.lobby_id == 0:
		var err = network_manager.get_peer().create_server(local_port, local_max_players)
		if err != OK: print(err)
		network_manager.update_multiplayer_peer()
		map_spawner.spawn(map_manager.lobby_scene_path)
		on_local_lobby_created.emit()

func create_steam_lobby():
	if SteamManager.lobby_id == 0:
		network_manager.get_peer().create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_PUBLIC, SteamManager.lobby_members_max)
		network_manager.update_multiplayer_peer()
		map_spawner.spawn(map_manager.lobby_scene_path)
		on_steam_lobby_created.emit()
#endregion

#region Join Methods
func join_local_lobby():
	var err = network_manager.get_peer().create_client(local_addr, local_port)
	if err != OK: print(err)
	network_manager.update_multiplayer_peer()

func join_steam_lobby(id):
	network_manager.get_peer().connect_lobby(id)
	network_manager.update_multiplayer_peer()
	steam_lobby_id = id
#endregion

func _on_local_player_connect_lobby(id):
	local_lobby_id = id
	print_rich("Player [color=green]", id, " Joined [/color]")

func _on_local_player_disconnect_lobby(id):
	print_rich("Player [color=red]", id, " Disconnected [/color]")

func _on_steam_lobby_created(connected: int, this_lobby_id: int) -> void:
	if connected == 1:
		steam_lobby_id = this_lobby_id
		SteamManager.lobby_id = this_lobby_id
		print_rich("[color=green]Created a lobby[/color]: ", steam_lobby_id)

		Steam.setLobbyJoinable(steam_lobby_id, true)

		Steam.setLobbyData(steam_lobby_id, "name", str(Steam.getPersonaName() + "'s Lobby"))
		Steam.setLobbyData(steam_lobby_id, "mode", "godot")

		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: ", set_relay)

func open_steam_lobby_list():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.addRequestLobbyListStringFilter("mode", "godot", Steam.LOBBY_COMPARISON_EQUAL)
	print("Requesting a lobby list")
	Steam.requestLobbyList()

func refresh_steam_lobby_list():
	for lobby in lobby_v_box_container.get_children():
		lobby.queue_free()

	open_steam_lobby_list()

func _on_steam_lobby_match_list(lobbies):
	for lobby in lobbies:
		var lobby_name: String = Steam.getLobbyData(lobby, "name")
		var _lobby_mode: String = Steam.getLobbyData(lobby, "mode")
		if lobby_name.is_empty():
			continue

		var lobby_num_members: int = Steam.getNumLobbyMembers(lobby)

		var lobby_btn: ServerPanel = menu_manager.server_panel.instantiate()
		lobby_v_box_container.add_child(lobby_btn)
		lobby_btn.server_name.text = lobby_name
		lobby_btn.player_count.text = "%s Player(s)" % lobby_num_members
		lobby_btn.name = "lobby_%s" % lobby
		lobby_btn.join_button.connect("pressed", Callable(self, "join_steam_lobby").bind(lobby))

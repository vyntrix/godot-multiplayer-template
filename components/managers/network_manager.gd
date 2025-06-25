class_name NetworkManager extends Node

var peer

enum PeerMode {
	STEAM,
	LOCAL,
	NONE
}

func get_peer():
	return peer

func update_multiplayer_peer():
	multiplayer.multiplayer_peer = get_peer()

func set_peer_mode(peer_mode: PeerMode):
	match peer_mode:
		PeerMode.STEAM:
			peer = SteamMultiplayerPeer.new()
		PeerMode.LOCAL:
			peer = ENetMultiplayerPeer.new()
		PeerMode.NONE:
			peer = null

	print_rich("Peer Mode Set To: [color=yellow]", PeerMode.keys()[peer_mode], "[/color]")

func reset_peer():
	set_peer_mode(PeerMode.NONE)

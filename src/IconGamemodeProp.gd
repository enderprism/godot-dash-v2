extends Node2D

class_name IconGamemodeProp

enum PlatformerState {
	BOTH,
	SIDESCROLLER_ONLY,
	PLATFORMER_ONLY,
}

@export var gamemode: Player.Gamemode
@export var platformer: PlatformerState

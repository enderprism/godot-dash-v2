extends Node

enum Scene {
	MAIN,
	EDITOR,
	LEVEL,
}

var previous: Scene


func from_main() -> bool:
	return previous == Scene.MAIN


func from_editor() -> bool:
	return previous == Scene.EDITOR


func from_level() -> bool:
	return previous == Scene.LEVEL

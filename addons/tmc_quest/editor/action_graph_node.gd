@tool
extends "res://addons/tmc_quest/editor/base_graph_node.gd"

@export var action: QuestAction: set = set_action

func _ready():
    set_action(action)

func set_action(new_action: QuestAction):
    action = new_action
    if not action:
        return
    title = new_action.name

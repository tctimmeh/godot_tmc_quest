@tool
extends "res://addons/tmc_quest/editor/base_graph_node.gd"

@export var action: QuestAction: set = set_action

func _ready():
    set_action(action)

func set_action(new_action):
    action = new_action
    if not action or not is_inside_tree():
        return
    title = action.name

@tool
extends "res://addons/tmc_quest/editor/base_graph_node.gd"

var action: QuestAction: set = set_action

func set_action(new_action: QuestAction):
    action = new_action
    if not action:
        return
    title = action.name

@tool
extends "res://addons/tmc_quest/editor/base_graph_node.gd"

var quest: Quest: set = set_quest

func set_quest(new_quest: Quest):
    quest = new_quest
    if not quest:
        return
    title = quest.name

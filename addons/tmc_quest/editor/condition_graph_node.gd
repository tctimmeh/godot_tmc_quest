@tool
extends "res://addons/tmc_quest/editor/base_graph_node.gd"

var condition: QuestCondition: set = set_condition

func set_condition(new_condition: QuestCondition):
    condition = new_condition
    if not condition:
        return
    title = condition.name

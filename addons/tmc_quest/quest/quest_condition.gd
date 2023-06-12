@tool
@icon("res://addons/tmc_quest/assets/condition_icon.svg")
class_name QuestCondition
extends Resource

@export var required: bool = true
@export var active: bool = false:
    get:
        return active
    set(val):
        active = val
        if val:
            _activated()
        else:
            _deactivated()
@export var always: bool = false
@export var passed := false:
    set = set_passed

@export var actions: Array[QuestAction]

@export var editor_pos := Vector2()

func _check() -> bool:
    # Implement this to check your condition
    return passed

func _activated():
    # called when activated
    pass

func _deactivated():
    # called when deactivated
    pass

func set_passed(val: bool):
    if val == passed:
        return

    passed = val
    if val:
        execute_actions()

func succeed():
    passed = true

func fail():
    passed = false

func add_action(action: QuestAction):
    actions.append(action)

func remove_action(action: QuestAction):
    actions.erase(action)

func execute_actions():
    for action in actions:
        action.execute()

func check() -> bool:
    return _check()

func activate():
    active = true

func deactivate():
    active = false

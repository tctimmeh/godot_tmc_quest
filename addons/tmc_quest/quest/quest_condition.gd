class_name QuestCondition
extends Resource

@export var name: String
@export var required: bool = true
@export var active: bool = false
@export var always: bool = false
@export var passed = false         # might be best to leave this be variant type
@export var actions: Array[QuestAction]

func succeed():
    if passed:
        return
    passed = true
    execute_actions()

func add_action(action: QuestAction):
    actions.append(action)

func execute_actions():
    for action in actions:
        action.execute()

func check():
    return false

func activate():
    active = true

func deactivate():
    active = false

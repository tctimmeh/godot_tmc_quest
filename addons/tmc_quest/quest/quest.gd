@tool
@icon("res://addons/tmc_quest/assets/quest_icon.svg")
class_name Quest
extends Resource

enum QuestOutcome {
    Incomplete = 0,
    Passed = 1,
}

@export var name: String = "New Quest"
@export_multiline var description: String

var _parent: WeakRef
var parent: Quest:
    get:
        return _parent.get_ref() if _parent else null
    set(val):
        _parent = weakref(val)

@export var subquests: Array[Quest]: set = set_subquests
@export var conditions: Array[QuestCondition]

@export var required: bool = true
@export var active: bool = false:
    get:
        return active
    set(val):
        active = val
        _activated() if val else _deactivated()
@export var hidden: bool = false
@export var tracking: bool = false
@export var complete: bool = false
@export var outcome: QuestOutcome

static func outcomes():
    return QuestOutcome

func _to_string():
    return "<Quest: %s, done=%s>" % [name, complete]

func set_subquests(quests: Array[Quest]):
    subquests = quests
    set_subquest_parents()

func set_subquest_parents():
    for quest in subquests:
        if not quest: # this can happen in the inspector when a new subquest is added
            continue  # the inspector adds a null until you fill it with an object
        quest.parent = self
        quest.set_subquest_parents()

func add_subquest(quest):
    quest.parent = self
    subquests.append(quest)

func remove_subquest(quest):
    quest.parent = null
    subquests.erase(quest)

func add_condition(condition):
    conditions.append(condition)
    if active and is_branch_active():
        condition.activate()

func remove_condition(condition: QuestCondition):
    condition.deactivate()
    conditions.erase(condition)

func is_branch_active():
# Is this branch of the quest tree fully active (this and all ancestors active)
    if not active:
        return false

    if not parent:
        return active

    return parent.is_branch_active()

func activate_conditions():
    for condition in conditions:
        condition.activate()

func deactivate_conditions(normal_only=false):
    for condition in conditions:
        if normal_only and condition.always:
            continue
        condition.deactivate()

# I am now allowed to track my conditions and progress the quest
func _activated():
    # Tell all my children that an ancestor was activated
    # If they are also active then they will need to activate their conditions
    for quest in subquests:
        quest.parent_activated()

    if is_branch_active():
        activate_conditions()

# An ancestor of my quest tree was just activated
func parent_activated():
    if not active:
        return

    # Tell all my children
    for quest in subquests:
        quest.parent_activated()

    # If I am active my activate my conditions
    if active:
        activate_conditions()

# I may not track my conditions or progress the quest
func _deactivated():
    for quest in subquests:
        quest.parent_deactivated()

    deactivate_conditions()

# An ancestor of mine was deactivated
func parent_deactivated():
    # Tell all my children
    for quest in subquests:
        quest.parent_deactivated()

    # always deactivate conditions if a parent isn't active
    deactivate_conditions()

func advance():
    if not active:
        return

    # Bottom-up accumulation
    for quest in subquests:
        quest.advance()

    for condition in conditions:
        var val = condition.check()
        if val:
            condition.succeed()
        else:
            condition.fail()

    check_for_success()

func has_always_conditions():
    var f = func is_always(x): return x.always
    return conditions.any(f)

func pass_quest():
    outcome = QuestOutcome.Passed
    complete = true
    tracking = false

    if has_always_conditions():
        deactivate_conditions(true)
        return

    active = false

func have_conditions_passed() -> bool:
    for condition in conditions:
        if condition.required and not condition.passed:
            return false
    return true

func have_subquests_passed() -> bool:
    for quest in subquests:
        if quest.required and quest.outcome != QuestOutcome.Passed:
            return false
    return true

func check_for_success():
    var subs_pass := have_subquests_passed()
    var conditions_pass := have_conditions_passed()

    if subs_pass and conditions_pass:
        pass_quest()
        return

    if outcome == QuestOutcome.Passed:
        complete = false
        outcome = QuestOutcome.Incomplete

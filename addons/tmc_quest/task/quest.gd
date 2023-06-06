class_name Task
extends Resource

enum TaskOutcome {
    Incomplete = 0,
    Passed = 1,
}

@export var name: String = "New Quest"
@export_multiline var description: String

var parent
@export var subtasks: Array[Task]: set = set_subtasks
@export var conditions: Array[TaskCondition]

@export var required: bool = true
@export var active: bool = false
@export var hidden: bool = false
@export var tracking: bool = false
@export var complete: bool = false
@export var outcome: TaskOutcome

static func outcomes():
    return TaskOutcome

func _to_string():
    return "<Quest: %s, done=%s>" % [name, complete]

func set_subtasks(tasks):
    subtasks = tasks
    var weak_self = weakref(self)
    for task in subtasks:
        task.parent = weak_self

func add_subtask(task):
    task.parent = self
    subtasks.append(task)

func remove_subtask(task):
    task.parent = null
    subtasks.erase(task)

func add_condition(condition):
    conditions.append(condition)
    if active and is_branch_active():
        condition.activate()

func is_branch_active():
# Is this branch of the task tree fully active (this and all ancestors active)
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

# I am now allowed to track my conditions and progress the task
func activate():
    active = true

    # Tell all my children that an ancestor was activated
    # If they are also active then they will need to activate their conditions
    for task in subtasks:
        task.parent_activated()

    if is_branch_active():
        activate_conditions()

# An ancestor of my task tree was just activated
func parent_activated():
    if not active:
        return

    # Tell all my children
    for task in subtasks:
        task.parent_activated()

    # If I am active my activate my conditions
    if active:
        activate_conditions()

# I may not track my conditions or progress the task
func deactivate():
    active = false

    for task in subtasks:
        task.parent_deactivated()

    deactivate_conditions()

# An ancestor of mine was deactivated
func parent_deactivated():
    # Tell all my children
    for task in subtasks:
        task.parent_deactivated()

    # always deactivate conditions if a parent isn't active
    deactivate_conditions()

func advance():
    if not active:
        return

    # Bottom-up accumulation
    for task in subtasks:
        task.advance()

    for condition in conditions:
        condition.check()

    check_for_success()

func has_always_conditions():
    var f = func is_always(x): return x.always
    return conditions.any(f)

func pass_task():
    outcome = TaskOutcome.Passed
    complete = true
    tracking = false

    if has_always_conditions():
        deactivate_conditions(true)
        return

    deactivate()

func have_conditions_passed() -> bool:
    for condition in conditions:
        if condition.required and not condition.passed:
            return false
    return true

func have_subtasks_passed() -> bool:
    for task in subtasks:
        if task.required and task.outcome != TaskOutcome.Passed:
            return false
    return true

func check_for_success():
    var subs_pass := have_subtasks_passed()
    var conditions_pass := have_conditions_passed()

    if subs_pass and conditions_pass:
        pass_task()
        return

    if outcome == TaskOutcome.Passed:
        complete = false
        outcome = TaskOutcome.Incomplete

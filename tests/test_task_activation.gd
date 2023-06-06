extends GutTest

var quest: Task

func before_each():
    quest = Task.new()

func test_activate_task_activate_own_conditions():
    var c = TaskCondition.new()
    quest.add_condition(c)
    assert_false(c.active)

    quest.activate()
    assert_true(c.active)

func test_activate_task_with_inactive_ancestor_does_not_activate_own_conditions():
    var t1 = Task.new()
    t1.name = "Task 1"
    var t2 = Task.new()
    t2.name = "Task 2"
    t1.add_subtask(t2)
    var c = TaskCondition.new()
    t2.add_condition(c)
    quest.add_subtask(t1)

    assert_false(t1.active)
    assert_false(t2.active)
    assert_false(c.active)
    assert_false(quest.active)

    quest.activate()
    assert_false(t1.active)
    assert_false(t2.active)
    assert_false(c.active)

    t2.activate()
    assert_false(c.active)

func test_deactivate_disables_own_conditions():
    var c = TaskCondition.new()
    quest.add_condition(c)
    quest.activate()

    assert_true(quest.active)
    assert_true(c.active)

    quest.deactivate()
    assert_false(c.active)

func test_deactivate_disables_conditions_on_all_subs():
    var t1 = Task.new()
    t1.activate()
    quest.add_subtask(t1)

    var t2 = Task.new()
    t1.add_subtask(t2)
    var c = TaskCondition.new()
    t2.add_condition(c)
    t2.activate()
    quest.activate()

    assert_true(c.active)

    quest.deactivate()
    assert_false(c.active)

func test_adding_condition_to_inactive_task_does_not_activate_condition():
    var c = TaskCondition.new()
    assert_false(c.active)

    quest.add_condition(c)
    assert_false(c.active)

func test_adding_condition_to_active_task_activates_condition():
    quest.activate()

    var c = TaskCondition.new()
    assert_false(c.active)

    quest.add_condition(c)
    assert_true(c.active)

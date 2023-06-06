extends GutTest

var quest: Task
var always_condition: TaskCondition
var normal_condition: TaskCondition

func before_each():
    quest = Task.new()
    quest.activate()

    always_condition = TaskCondition.new()
    always_condition.passed = true
    always_condition.always = true

    normal_condition = TaskCondition.new()
    normal_condition.passed = true

func test_deactivating_disables_task_and_all_conditions():
    quest.add_condition(always_condition)
    quest.add_condition(normal_condition)

    var t = Task.new()
    t.activate()
    quest.add_subtask(t)

    assert_true(always_condition.active)
    assert_true(normal_condition.active)
    assert_true(t.active)
    assert_true(quest.active)

    quest.deactivate()
    assert_false(always_condition.active)
    assert_false(normal_condition.active)
    assert_true(t.active)
    assert_false(quest.active)

func test_task_passes():
    quest.add_condition(always_condition)

    assert_false(quest.complete)
    quest.advance()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Passed)

func test_task_remains_active():
    quest.add_condition(always_condition)

    assert_true(quest.active)
    quest.advance()
    assert_true(quest.active)

func test_always_on_conditions_remain_active():
    quest.add_condition(always_condition)
    quest.add_condition(normal_condition)

    assert_true(always_condition.active)
    quest.advance()
    assert_true(always_condition.active)

func test_normal_conditions_are_deactivated():
    quest.add_condition(always_condition)
    quest.add_condition(normal_condition)

    assert_true(normal_condition.active)
    quest.advance()
    assert_false(normal_condition.active)

func test_task_reverts_to_incomplete_when_always_condition_no_longer_true():
    quest.add_condition(always_condition)
    quest.add_condition(normal_condition)

    assert_false(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Incomplete)
    assert_true(normal_condition.active)

    quest.advance()
    assert_true(quest.complete)
    assert_eq(quest.outcome, Task.outcomes().Passed)
    assert_false(normal_condition.active)
    assert_true(always_condition.active)

    always_condition.passed = false
    quest.advance()

    assert_eq(quest.outcome, Task.outcomes().Incomplete)
    assert_false(quest.complete)
    assert_true(always_condition.active)
    assert_false(normal_condition.active)

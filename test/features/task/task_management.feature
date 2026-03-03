Feature: Task Management
  As a family member
  I want to manage household chores
  So that tasks are completed and tracked

  Background:
    Given the app is running

  Scenario: View available tasks
    Given there are tasks in the family
    When I navigate to the task list
    Then I should see the list of available tasks

  Scenario: Create a new task
    Given I am a parent user
    When I tap the add task button
    And I enter task title {'Wash dishes'}
    And I enter task description {'Clean all dishes'}
    And I select difficulty {'easy'}
    And I tap the save button
    Then I should see {'Wash dishes'} text
    And a success message should be displayed

  Scenario: Claim an available task
    Given there is an available task "Take out trash"
    And I am logged in as a child
    When I tap on the task "Take out trash"
    And I tap the claim button
    Then the task should be assigned to me
    And the task status should be "assigned"

  Scenario: Complete a task
    Given I have a task "Clean room" assigned to me
    When I mark the task as complete
    Then the task status should be "pending_approval"
    And a notification should be sent to parents

  Scenario: Parent approves completed task
    Given there is a task pending approval
    And I am logged in as a parent
    When I approve the task
    Then the task status should be "completed"
    And points should be awarded to the child

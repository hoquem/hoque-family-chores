Feature: Counter Demo
  As a developer
  I want to see BDD tests pass
  So that I understand the TDD workflow

  Scenario: Initial counter value is zero
    Given the demo app is running
    Then I see {'0'} text

  Scenario: Increment counter
    Given the demo app is running
    When I tap the increment button
    Then I see {'1'} text

  Scenario: Increment counter multiple times
    Given the demo app is running
    When I tap the increment button
    And I tap the increment button
    And I tap the increment button
    Then I see {'3'} text

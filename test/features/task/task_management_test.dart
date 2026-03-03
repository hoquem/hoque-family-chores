// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/the_app_is_running.dart';
import './step/there_are_tasks_in_the_family.dart';
import './step/i_navigate_to_the_task_list.dart';
import './step/i_should_see_the_list_of_available_tasks.dart';
import './step/i_am_a_parent_user.dart';
import './step/i_tap_the_add_task_button.dart';
import './step/i_enter_task_title.dart';
import './step/i_enter_task_description.dart';
import './step/i_select_difficulty.dart';
import './step/i_tap_the_save_button.dart';
import './step/i_should_see_text.dart';
import './step/a_success_message_should_be_displayed.dart';
import './step/there_is_an_available_task_take_out_trash.dart';
import './step/i_am_logged_in_as_a_child.dart';
import './step/i_tap_on_the_task_take_out_trash.dart';
import './step/i_tap_the_claim_button.dart';
import './step/the_task_should_be_assigned_to_me.dart';
import './step/the_task_status_should_be_assigned.dart';
import './step/i_have_a_task_clean_room_assigned_to_me.dart';
import './step/i_mark_the_task_as_complete.dart';
import './step/the_task_status_should_be_pending_approval.dart';
import './step/a_notification_should_be_sent_to_parents.dart';
import './step/there_is_a_task_pending_approval.dart';
import './step/i_am_logged_in_as_a_parent.dart';
import './step/i_approve_the_task.dart';
import './step/the_task_status_should_be_completed.dart';
import './step/points_should_be_awarded_to_the_child.dart';

void main() {
  group('''Task Management''', () {
    Future<void> bddSetUp(WidgetTester tester) async {
      await theAppIsRunning(tester);
    }

    testWidgets('''View available tasks''', (tester) async {
      await bddSetUp(tester);
      await thereAreTasksInTheFamily(tester);
      await iNavigateToTheTaskList(tester);
      await iShouldSeeTheListOfAvailableTasks(tester);
    });
    testWidgets('''Create a new task''', (tester) async {
      await bddSetUp(tester);
      await iAmAParentUser(tester);
      await iTapTheAddTaskButton(tester);
      await iEnterTaskTitle(tester, 'Wash dishes');
      await iEnterTaskDescription(tester, 'Clean all dishes');
      await iSelectDifficulty(tester, 'easy');
      await iTapTheSaveButton(tester);
      await iShouldSeeText(tester, 'Wash dishes');
      await aSuccessMessageShouldBeDisplayed(tester);
    });
    testWidgets('''Claim an available task''', (tester) async {
      await bddSetUp(tester);
      await thereIsAnAvailableTaskTakeOutTrash(tester);
      await iAmLoggedInAsAChild(tester);
      await iTapOnTheTaskTakeOutTrash(tester);
      await iTapTheClaimButton(tester);
      await theTaskShouldBeAssignedToMe(tester);
      await theTaskStatusShouldBeAssigned(tester);
    });
    testWidgets('''Complete a task''', (tester) async {
      await bddSetUp(tester);
      await iHaveATaskCleanRoomAssignedToMe(tester);
      await iMarkTheTaskAsComplete(tester);
      await theTaskStatusShouldBePendingApproval(tester);
      await aNotificationShouldBeSentToParents(tester);
    });
    testWidgets('''Parent approves completed task''', (tester) async {
      await bddSetUp(tester);
      await thereIsATaskPendingApproval(tester);
      await iAmLoggedInAsAParent(tester);
      await iApproveTheTask(tester);
      await theTaskStatusShouldBeCompleted(tester);
      await pointsShouldBeAwardedToTheChild(tester);
    });
  });
}

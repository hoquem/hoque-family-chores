# Task Management System Specification

## Feature Overview
The Task Management System is the core feature that enables families to create, assign, track, and complete household chores with a gamified approach.

## Core Functionality

### 1. Task Creation
- **Purpose**: Allow family members to create new tasks
- **Input**: Title, description, difficulty, due date, assignee (optional), tags
- **Output**: New task with unique ID and points value
- **Validation**: Required fields, valid dates, family membership
- **Auto-assignments**: Points based on difficulty level

### 2. Task Assignment & Claiming
- **Purpose**: Manage task ownership and responsibility
- **Assignment Types**:
  - Direct assignment by task creator
  - Self-claiming from available tasks
  - Auto-assignment based on family rules
- **Status Transitions**: Available → Assigned → Completed

### 3. Task Completion Workflow
- **Purpose**: Structured process for task completion and approval
- **Workflow Steps**:
  1. Task assigned to user
  2. User marks task as completed
  3. Task enters "Pending Approval" status
  4. Parent/guardian reviews and approves/rejects
  5. Points awarded upon approval

### 4. Task Status Management
- **Status Types**:
  - `available`: Open for claiming
  - `assigned`: Currently assigned to someone
  - `pendingApproval`: Completed, waiting for approval
  - `needsRevision`: Rejected, requires changes
  - `completed`: Approved and finished

### 5. Task Filtering & Search
- **Filter Options**:
  - All tasks
  - My tasks (assigned to current user)
  - Available tasks
  - Completed tasks
  - Overdue tasks
  - Due today/tomorrow
- **Search**: By title, description, tags

## Technical Implementation

### Domain Layer
```dart
// Entities
- Task: Core task entity with all properties
- TaskSummary: Aggregated task statistics
- TaskStatus: Enum for task states
- TaskDifficulty: Enum for effort levels

// Use Cases
- CreateTaskUseCase: Create new tasks
- ClaimTaskUseCase: Claim available tasks
- CompleteTaskUseCase: Mark tasks as completed
- ApproveTaskUseCase: Approve completed tasks
- GetTasksUseCase: Retrieve task lists
- UpdateTaskUseCase: Modify existing tasks
- DeleteTaskUseCase: Remove tasks
- AssignTaskUseCase: Assign tasks to users
- StreamTasksUseCase: Real-time task updates

// Repositories
- TaskRepository: Abstract interface for task operations
```

### Data Layer
```dart
// Repositories
- FirebaseTaskRepository: Firebase Firestore implementation
- MockTaskRepository: Testing implementation

// Data Sources
- Firebase Firestore (primary)
- Local cache for offline support
```

### Presentation Layer
```dart
// Screens
- TaskListScreen: Main task listing
- AddTaskScreen: Task creation interface
- TaskDetailsScreen: Individual task view
- TasksScreen: Task management dashboard

// Widgets
- TaskListTile: Individual task display
- TaskSummaryWidget: Task statistics
- MyTasksWidget: User's assigned tasks
- QuickTaskPickerWidget: Quick task selection

// Providers
- TaskListNotifier: Manages task lists
- TaskCreationNotifier: Handles task creation
- AvailableTasksNotifier: Manages available tasks
- TaskSummaryNotifier: Task statistics
```

## User Interface

### Task List Screen
- Task cards with status indicators
- Filter tabs (All, My Tasks, Available, Completed)
- Search bar
- Sort options (due date, difficulty, points)
- Pull-to-refresh functionality
- Empty state handling

### Add Task Screen
- Form with validation
- Difficulty selector with point preview
- Due date picker
- Assignee dropdown (family members)
- Tags input
- Preview of points to be awarded

### Task Details Screen
- Complete task information
- Status indicator
- Action buttons (claim, complete, approve, reject)
- Comments/notes section
- Completion history

## Task Difficulty System

### Difficulty Levels
1. **Easy (10 points)**
   - Quick tasks, 5-15 minutes
   - Simple household chores
   - Example: Take out trash, make bed

2. **Medium (25 points)**
   - Moderate tasks, 15-30 minutes
   - Regular maintenance tasks
   - Example: Clean kitchen, do laundry

3. **Hard (50 points)**
   - Complex tasks, 30-60 minutes
   - Detailed cleaning or organization
   - Example: Deep clean bathroom, organize closet

4. **Challenging (100 points)**
   - Major tasks, 60+ minutes
   - Significant projects
   - Example: Spring cleaning, room renovation

## Task Lifecycle

### Creation Phase
1. User creates task with details
2. System assigns points based on difficulty
3. Task becomes available for claiming
4. Family members notified of new task

### Assignment Phase
1. User claims available task
2. Task status changes to "assigned"
3. Due date tracking begins
4. Reminders sent as due date approaches

### Completion Phase
1. User marks task as completed
2. Task enters "pending approval" status
3. Parent/guardian reviews completion
4. Approval or rejection with feedback

### Finalization Phase
1. Upon approval: Points awarded, task archived
2. Upon rejection: Task returns to "needs revision"
3. User can resubmit after making changes

## Data Models

### Task Entity
```dart
class Task {
  final TaskId id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskDifficulty difficulty;
  final DateTime dueDate;
  final UserId? assignedToId;
  final UserId? createdById;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Points points;
  final List<String> tags;
  final String? recurringPattern;
  final DateTime? lastCompletedAt;
  final FamilyId familyId;
}
```

### Task Summary
```dart
class TaskSummary {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int availableTasks;
  final int needsRevisionTasks;
  final int assignedTasks;
  final int dueToday;
  final int pointsEarned;
  final int completionPercentage;
}
```

## Error Handling

### Common Scenarios
1. **Network Issues**
   - Offline task creation (queued)
   - Sync when connection restored
   - Conflict resolution

2. **Validation Errors**
   - Field-specific error messages
   - Real-time validation feedback
   - Graceful error recovery

3. **Permission Issues**
   - Role-based access control
   - Clear permission denied messages
   - Escalation paths

## Performance Considerations

### Optimization Strategies
- Pagination for large task lists
- Lazy loading of task details
- Efficient filtering and sorting
- Background sync for offline support
- Image optimization for task photos

### Caching Strategy
- Local task cache for offline access
- Smart cache invalidation
- Incremental updates
- Background refresh

## Testing Strategy

### Unit Tests
- Task entity validation
- Use case business logic
- Repository operations
- Status transition rules

### Integration Tests
- End-to-end task workflows
- Firebase integration
- Offline/online sync
- Multi-user scenarios

### UI Tests
- Task creation flow
- Status transitions
- Filter and search functionality
- Error handling display

## Dependencies
- Firebase Firestore
- Riverpod for state management
- Flutter DateTime utilities
- Local storage for caching

## Future Enhancements

### Product Manager Suggestions

*   **Collaborative Family Quests:** Introduce large-scale "Family Quests" that require multiple family members to contribute.
*   **Kudos or High-Five System:** Allow family members to give each other "Kudos" or a virtual "High-Five" for a well-done task.
*   **Personalized Task Suggestions:** Utilize basic AI/ML to suggest tasks to users based on their history and preferences.

### Original Ideas

- Recurring task patterns
- Task templates
- Photo/video task completion
- Voice notes for tasks
- Task dependencies
- Automated task suggestions
- Integration with smart home devices

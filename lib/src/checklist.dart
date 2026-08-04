import 'core.dart';
import 'enums.dart';

/// A single task to include in a checklist sent via [Bot.sendChecklist] or
/// [Bot.editMessageChecklist].
class InputChecklistTask {
  /// Unique identifier of the task within the checklist, 1-1000000. Must be
  /// unique among all tasks in the checklist.
  final int id;

  /// Text of the task, 1-100 characters after entities parsing.
  final String text;

  /// Mode for parsing entities in [text]. Only `bold`, `italic`, `underline`,
  /// `strikethrough`, `spoiler`, and `custom_emoji` entities are allowed.
  final ParseMode? parseMode;

  /// Special entities in [text], as an alternative to [parseMode].
  final List<Json>? textEntities;

  /// Creates a checklist task with the given [id] and [text].
  const InputChecklistTask(
    this.id,
    this.text, {
    this.parseMode,
    this.textEntities,
  });

  /// Converts this task to the JSON shape Telegram's API expects.
  Json toJson() => {
        'id': id,
        'text': text,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (textEntities != null) 'text_entities': textEntities,
      };
}

/// A checklist to create, used with [Bot.sendChecklist] and
/// [Bot.editMessageChecklist] (both business-account-only).
class InputChecklist {
  /// Title of the checklist, 1-255 characters after entities parsing.
  final String title;

  /// Mode for parsing entities in [title].
  final ParseMode? parseMode;

  /// Special entities in [title], as an alternative to [parseMode].
  final List<Json>? titleEntities;

  /// The 1-30 tasks that make up the checklist.
  final List<InputChecklistTask> tasks;

  /// Whether other users can add tasks to the checklist.
  final bool? othersCanAddTasks;

  /// Whether other users can mark tasks as done or not done.
  final bool? othersCanMarkTasksAsDone;

  /// Creates a checklist with the given [title] and [tasks].
  const InputChecklist(
    this.title,
    this.tasks, {
    this.parseMode,
    this.titleEntities,
    this.othersCanAddTasks,
    this.othersCanMarkTasksAsDone,
  });

  /// Converts this checklist to the JSON shape Telegram's API expects.
  Json toJson() => {
        'title': title,
        if (parseMode != null) 'parse_mode': parseMode!.value,
        if (titleEntities != null) 'title_entities': titleEntities,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        if (othersCanAddTasks != null)
          'others_can_add_tasks': othersCanAddTasks,
        if (othersCanMarkTasksAsDone != null)
          'others_can_mark_tasks_as_done': othersCanMarkTasksAsDone,
      };
}

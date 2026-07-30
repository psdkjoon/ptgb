import 'core.dart';

/// Default permissions for non-admin members of a chat, used with
/// [Bot.setChatPermissions] and [Bot.restrictChatMember].
///
/// Every field defaults to `null` (unchanged); set a field to `false` to
/// revoke that permission, or `true` to grant it.
class ChatPermissions {
  /// Whether members can send text messages, contacts, invoices, locations, and venues.
  final bool? canSendMessages;
  /// Whether members can send audio files.
  final bool? canSendAudios;

  /// Whether members can send documents/files.
  final bool? canSendDocuments;

  /// Whether members can send photos.
  final bool? canSendPhotos;

  /// Whether members can send videos.
  final bool? canSendVideos;

  /// Whether members can send round video notes.
  final bool? canSendVideoNotes;

  /// Whether members can send voice messages.
  final bool? canSendVoiceNotes;

  /// Whether members can send polls. Requires [canSendMessages] to also be true.
  final bool? canSendPolls;

  /// Whether members can send stickers, GIFs, games, and inline bot results.
  final bool? canSendOtherMessages;

  /// Whether members can add link previews to their messages.
  final bool? canAddWebPagePreviews;

  /// Whether members can change the chat's title, photo, and other settings. Ignored in public supergroups.
  final bool? canChangeInfo;

  /// Whether members can invite new users to the chat.
  final bool? canInviteUsers;

  /// Whether members can pin messages. Ignored in public supergroups.
  final bool? canPinMessages;

  /// Whether members can create forum topics. Only relevant if forum topics are enabled.
  final bool? canManageTopics;

  /// Creates a set of permissions. Leave a field `null` to leave it unchanged.
  const ChatPermissions({
    this.canSendMessages,
    this.canSendAudios,
    this.canSendDocuments,
    this.canSendPhotos,
    this.canSendVideos,
    this.canSendVideoNotes,
    this.canSendVoiceNotes,
    this.canSendPolls,
    this.canSendOtherMessages,
    this.canAddWebPagePreviews,
    this.canChangeInfo,
    this.canInviteUsers,
    this.canPinMessages,
    this.canManageTopics,
  });

  /// Converts this permission set to the JSON shape Telegram's API expects,
  /// omitting any field left as `null`.
  Json toJson() => {
        if (canSendMessages != null) 'can_send_messages': canSendMessages,
        if (canSendAudios != null) 'can_send_audios': canSendAudios,
        if (canSendDocuments != null) 'can_send_documents': canSendDocuments,
        if (canSendPhotos != null) 'can_send_photos': canSendPhotos,
        if (canSendVideos != null) 'can_send_videos': canSendVideos,
        if (canSendVideoNotes != null) 'can_send_video_notes': canSendVideoNotes,
        if (canSendVoiceNotes != null) 'can_send_voice_notes': canSendVoiceNotes,
        if (canSendPolls != null) 'can_send_polls': canSendPolls,
        if (canSendOtherMessages != null) 'can_send_other_messages': canSendOtherMessages,
        if (canAddWebPagePreviews != null) 'can_add_web_page_previews': canAddWebPagePreviews,
        if (canChangeInfo != null) 'can_change_info': canChangeInfo,
        if (canInviteUsers != null) 'can_invite_users': canInviteUsers,
        if (canPinMessages != null) 'can_pin_messages': canPinMessages,
        if (canManageTopics != null) 'can_manage_topics': canManageTopics,
      };
}

/// The specific privileges granted to a chat administrator, used with
/// [Bot.promoteChatMember] and [Bot.setMyDefaultAdministratorRights].
///
/// The first eleven fields default to `false` since they represent an
/// explicit grant of power; the last four are left `null` (meaning:
/// unset/inherit) since they only apply to channels or forum-enabled chats.
class ChatAdministratorRights {
  /// Whether the admin's presence is hidden (shown as the chat itself rather than a named user).
  final bool isAnonymous;
  /// Whether the admin has general chat-management access (see the group's members list, etc).
  final bool canManageChat;

  /// Whether the admin can delete other users' messages.
  final bool canDeleteMessages;

  /// Whether the admin can manage voice/video chats.
  final bool canManageVideoChats;

  /// Whether the admin can restrict, ban, and unban other members.
  final bool canRestrictMembers;

  /// Whether the admin can promote other members to admin (with a subset of their own rights).
  final bool canPromoteMembers;

  /// Whether the admin can change the chat's title, photo, and other settings.
  final bool canChangeInfo;

  /// Whether the admin can invite new users to the chat.
  final bool canInviteUsers;

  /// Whether the admin can post stories on behalf of the chat.
  final bool canPostStories;

  /// Whether the admin can edit stories posted by others.
  final bool canEditStories;

  /// Whether the admin can delete stories posted by others.
  final bool canDeleteStories;

  /// Channels only: whether the admin can post messages.
  final bool? canPostMessages;

  /// Channels only: whether the admin can edit other users' messages.
  final bool? canEditMessages;

  /// Whether the admin can pin messages (groups/supergroups only).
  final bool? canPinMessages;

  /// Whether the admin can create, rename, close, and reopen forum topics (forum supergroups only).
  final bool? canManageTopics;

  /// Creates an admin rights set. The first eleven flags default to `false`;
  /// the channel/topic-specific flags are left unset unless provided.
  const ChatAdministratorRights({
    this.isAnonymous = false,
    this.canManageChat = false,
    this.canDeleteMessages = false,
    this.canManageVideoChats = false,
    this.canRestrictMembers = false,
    this.canPromoteMembers = false,
    this.canChangeInfo = false,
    this.canInviteUsers = false,
    this.canPostStories = false,
    this.canEditStories = false,
    this.canDeleteStories = false,
    this.canPostMessages,
    this.canEditMessages,
    this.canPinMessages,
    this.canManageTopics,
  });

  /// Converts these rights to the JSON shape Telegram's API expects.
  Json toJson() => {
        'is_anonymous': isAnonymous,
        'can_manage_chat': canManageChat,
        'can_delete_messages': canDeleteMessages,
        'can_manage_video_chats': canManageVideoChats,
        'can_restrict_members': canRestrictMembers,
        'can_promote_members': canPromoteMembers,
        'can_change_info': canChangeInfo,
        'can_invite_users': canInviteUsers,
        'can_post_stories': canPostStories,
        'can_edit_stories': canEditStories,
        'can_delete_stories': canDeleteStories,
        if (canPostMessages != null) 'can_post_messages': canPostMessages,
        if (canEditMessages != null) 'can_edit_messages': canEditMessages,
        if (canPinMessages != null) 'can_pin_messages': canPinMessages,
        if (canManageTopics != null) 'can_manage_topics': canManageTopics,
      };
}

/// A reaction the bot can set on a message via [Bot.setMessageReaction].
abstract class ReactionType {
  /// Converts this reaction to the JSON shape Telegram's API expects.
  Json toJson();

  /// A standard emoji reaction, e.g. `ReactionType.emoji('👍')`.
  factory ReactionType.emoji(String emoji) => _EmojiReaction(emoji);

  /// A reaction using a custom emoji sticker, identified by [customEmojiId].
  factory ReactionType.customEmoji(String customEmojiId) => _CustomEmojiReaction(customEmojiId);

  /// A paid-star reaction (Telegram Stars).
  factory ReactionType.paid() => _PaidReaction();
}

class _EmojiReaction implements ReactionType {
  final String emoji;
  const _EmojiReaction(this.emoji);
  @override
  Json toJson() => {'type': 'emoji', 'emoji': emoji};
}

class _CustomEmojiReaction implements ReactionType {
  final String customEmojiId;
  const _CustomEmojiReaction(this.customEmojiId);
  @override
  Json toJson() => {'type': 'custom_emoji', 'custom_emoji_id': customEmojiId};
}

class _PaidReaction implements ReactionType {
  const _PaidReaction();
  @override
  Json toJson() => {'type': 'paid'};
}

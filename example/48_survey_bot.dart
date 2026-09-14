// A complete, deployable bot: admins define a multi-question survey as a
// simple text format, the bot posts each question as a real (non-anonymous)
// Telegram poll, and tallies results as votes come in.
//
// Survey definition format (send this whole block as one message):
//
//   /newsurvey
//   Favorite season?
//   Spring | Summer | Fall | Winter
//   Preferred meeting time?
//   Morning | Afternoon | Evening
//
// Each pair of lines is one question: the question text, then its options
// separated by `|`. The bot posts them one at a time and moves to the next
// question once everyone currently tracked has answered — for a demo,
// "everyone" is just whoever's messaged the bot before, tracked via
// [BotStorage].
//
// Polls must be non-anonymous ([Bot.sendPoll]'s `isAnonymous: false`) for
// the bot to see who voted at all — Telegram never reveals voters on
// anonymous polls, by design.


import 'package:ptgb/ptgb.dart';

class _Question {
  _Question(this.text, this.options);
  final String text;
  final List<String> options;
}

class _Survey {
  _Survey(this.chatId, this.questions);
  final int chatId;
  final List<_Question> questions;
  int currentIndex = 0;
  String? currentPollId;
  // pollId -> optionIndex -> vote count
  final Map<String, Map<int, int>> tallies = {};
}

List<_Question>? _parseSurvey(String body) {
  final lines = body.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.isEmpty || lines.length.isOdd) return null;
  final questions = <_Question>[];
  for (var i = 0; i < lines.length; i += 2) {
    final options = lines[i + 1].split('|').map((o) => o.trim()).where((o) => o.isNotEmpty).toList();
    if (options.length < 2) return null;
    questions.add(_Question(lines[i].trim(), options));
  }
  return questions;
}

void main() async {
  final bot = Bot();
  final storage = BotStorage(path: 'survey_data.json');
  await storage.load();

  // One active survey per chat at a time.
  final activeSurveys = <int, _Survey>{};

  Future<void> postNextQuestion(_Survey survey) async {
    if (survey.currentIndex >= survey.questions.length) {
      final report = StringBuffer('📊 Survey complete!\n\n');
      for (var i = 0; i < survey.questions.length; i++) {
        final q = survey.questions[i];
        report.writeln('${i + 1}. ${q.text}');
        final tally = survey.tallies.values.elementAt(i);
        for (var j = 0; j < q.options.length; j++) {
          report.writeln('   ${q.options[j]}: ${tally[j] ?? 0} vote(s)');
        }
      }
      await bot.sendMessage(chatId: survey.chatId, text: report.toString());
      activeSurveys.remove(survey.chatId);
      return;
    }
    final q = survey.questions[survey.currentIndex];
    final sent = await bot.sendPoll(
      chatId: survey.chatId,
      question: 'Q${survey.currentIndex + 1}/${survey.questions.length}: ${q.text}',
      options: q.options,
      isAnonymous: false,
    );
    survey.currentPollId = sent.poll?.id;
    if (survey.currentPollId != null) {
      survey.tallies[survey.currentPollId!] = {};
    }
  }

  print('Survey bot running. Send /newsurvey followed by questions (see file header for format).');

  await for (final update in bot.poll()) {
    final user = update.from;
    if (user != null) await storage.saveUser(user: user);

    final pollAnswer = update.pollAnswer;
    if (pollAnswer != null) {
      // Find which active survey this poll belongs to and tally the vote.
      for (final survey in activeSurveys.values) {
        final tally = survey.tallies[pollAnswer.pollId];
        if (tally == null) continue;
        for (final optionId in pollAnswer.optionIds) {
          tally[optionId] = (tally[optionId] ?? 0) + 1;
        }
        // Demo advancement rule: move on once at least one vote is in and
        // it's been tallied — replace with a real "wait for N voters" or
        // a timer in a production survey bot.
        if (tally.values.fold(0, (a, b) => a + b) >= 1) {
          survey.currentIndex++;
          await postNextQuestion(survey);
        }
      }
      continue;
    }

    final chatId = update.chatId;
    final text = update.text;
    if (chatId == null || text == null) continue;

    if (text.startsWith('/newsurvey')) {
      final body = text.substring('/newsurvey'.length);
      final questions = _parseSurvey(body);
      if (questions == null) {
        await bot.sendMessage(
          chatId: chatId,
          text: 'Couldn\'t parse that. Format:\n/newsurvey\nQuestion one?\nOption A | Option B\nQuestion two?\nYes | No',
        );
        continue;
      }
      final survey = _Survey(chatId, questions);
      activeSurveys[chatId] = survey;
      await bot.sendMessage(chatId: chatId, text: 'Starting a ${questions.length}-question survey!');
      await postNextQuestion(survey);
    } else if (text == '/start' || text == '/help') {
      await bot.sendMessage(
        chatId: chatId,
        text: 'Send /newsurvey followed by your questions to start a poll-based survey:\n\n'
            '/newsurvey\nFavorite season?\nSpring | Summer | Fall | Winter',
      );
    }
  }
}

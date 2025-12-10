import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ActivityType {
  cricket,
  football,
  badminton,
  tabletennis,
  bikeRideMusic,
  walkChat,
  cookingChallenge,
  danceParty,
  photoHunt,
  gameNight,
  artChallenge,
  musicJam,
  storytime,
  workoutBattle,
  cleaningRace,
  gardenProject,
  movieNight,
  bookClub,
  phoneDetoxChallenge,
  meditationCircle,
}

enum ActivityMode {
  individual, 
  together, 
  flexible, 
}

enum ActivityStatus {
  pending, 
  accepted, 
  active, 
  completed, 
  cancelled, 
  missed, 
}

class ActivityTemplate {
  final ActivityType type;
  final String name;
  final String description;
  final String icon;
  final List<int> suggestedDurations; // in minutes
  final ActivityMode defaultMode;
  final List<String> benefits;
  final int difficultyLevel; // 1-5
  final bool requiresLocation;

  ActivityTemplate({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.suggestedDurations,
    required this.defaultMode,
    required this.benefits,
    this.difficultyLevel = 3,
    this.requiresLocation = false,
  });
}

class DetoxBuddyActivity {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final int durationMinutes;
  final ActivityMode mode;
  final ActivityStatus status;
  final String createdBy;
  final List<String> participants;
  final DateTime scheduledTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final Map<String, dynamic> progress;
  final Map<String, bool> completionStatus;
  final String? locationNote;
  final List<String> motivationalMessages;

  DetoxBuddyActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.mode,
    required this.status,
    required this.createdBy,
    required this.participants,
    required this.scheduledTime,
    this.startTime,
    this.endTime,
    this.progress = const {},
    this.completionStatus = const {},
    this.locationNote,
    this.motivationalMessages = const [],
  });

  factory DetoxBuddyActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DetoxBuddyActivity(
      id: doc.id,
      type: ActivityType.values[data['type'] ?? 0],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 15,
      mode: ActivityMode.values[data['mode'] ?? 0],
      status: ActivityStatus.values[data['status'] ?? 0],
      createdBy: data['createdBy'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : null,
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      progress: Map<String, dynamic>.from(data['progress'] ?? {}),
      completionStatus: Map<String, bool>.from(data['completionStatus'] ?? {}),
      locationNote: data['locationNote'],
      motivationalMessages: List<String>.from(
        data['motivationalMessages'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.index,
      'title': title,
      'description': description,
      'durationMinutes': durationMinutes,
      'mode': mode.index,
      'status': status.index,
      'createdBy': createdBy,
      'participants': participants,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'progress': progress,
      'completionStatus': completionStatus,
      'locationNote': locationNote,
      'motivationalMessages': motivationalMessages,
      'createdAt': Timestamp.now(),
    };
  }
}

class DetoxBuddyActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fun & Engaging Buddy Activity Templates
  static final List<ActivityTemplate> activityTemplates = [
    ActivityTemplate(
      type: ActivityType.cricket,
      name: "Cricket Battle! 🏏",
      description:
          "Play cricket together - compete or team up! Bat, bowl, and have a blast",
      icon: "🏏",
      suggestedDurations: [30, 45, 60, 90, 120],
      defaultMode: ActivityMode.together,
      benefits: [
        "Teamwork",
        "Physical fitness",
        "Fun competition",
        "Outdoor time",
      ],
      difficultyLevel: 3,
      requiresLocation: true,
    ),
    ActivityTemplate(
      type: ActivityType.football,
      name: "Football Fun! ⚽",
      description:
          "Kick the ball around! Play 1v1, practice together, or just have fun",
      icon: "⚽",
      suggestedDurations: [20, 30, 45, 60, 90],
      defaultMode: ActivityMode.together,
      benefits: [
        "Cardio workout",
        "Coordination",
        "Competitive spirit",
        "Teamwork",
      ],
      difficultyLevel: 3,
      requiresLocation: true,
    ),
    ActivityTemplate(
      type: ActivityType.badminton,
      name: "Badminton Smash! 🏸",
      description:
          "Fast-paced racket fun! Challenge each other to exciting rallies",
      icon: "🏸",
      suggestedDurations: [20, 30, 45, 60],
      defaultMode: ActivityMode.together,
      benefits: [
        "Quick reflexes",
        "Hand-eye coordination",
        "Fun competition",
        "Cardio",
      ],
      difficultyLevel: 2,
      requiresLocation: true,
    ),
    ActivityTemplate(
      type: ActivityType.tabletennis,
      name: "Table Tennis Rally! 🏓",
      description:
          "Indoor ping pong action! Quick games, intense rallies, lots of laughs",
      icon: "🏓",
      suggestedDurations: [15, 20, 30, 45],
      defaultMode: ActivityMode.together,
      benefits: [
        "Quick thinking",
        "Reflexes",
        "Indoor fun",
        "Competitive play",
      ],
      difficultyLevel: 2,
    ),
    ActivityTemplate(
      type: ActivityType.bikeRideMusic,
      name: "Music Bike Ride! 🚴‍♂️🎵",
      description:
          "Cycle together while jamming to your favorite tunes! Sing along and enjoy",
      icon: "�‍♂️",
      suggestedDurations: [30, 45, 60, 90, 120],
      defaultMode: ActivityMode.together,
      benefits: [
        "Music therapy",
        "Exercise",
        "Shared experience",
        "Joy and laughter",
      ],
      difficultyLevel: 2,
      requiresLocation: true,
    ),
    ActivityTemplate(
      type: ActivityType.walkChat,
      name: "Walk & Talk Adventure! 🚶‍♂️💬",
      description:
          "Take a stroll and have deep conversations! Share stories, dreams, and laughs",
      icon: "�‍♂️",
      suggestedDurations: [20, 30, 45, 60],
      defaultMode: ActivityMode.together,
      benefits: ["Bonding", "Fresh air", "Deep conversations", "Stress relief"],
      difficultyLevel: 1,
      requiresLocation: true,
    ),
    ActivityTemplate(
      type: ActivityType.cookingChallenge,
      name: "Cooking Challenge! 👨‍🍳🔥",
      description:
          "Cook the same recipe separately or together! Compare results and have fun",
      icon: "�‍🍳",
      suggestedDurations: [30, 45, 60, 90],
      defaultMode: ActivityMode.flexible,
      benefits: ["Creativity", "Life skills", "Teamwork", "Delicious food"],
      difficultyLevel: 3,
    ),
    ActivityTemplate(
      type: ActivityType.danceParty,
      name: "Dance Party! 💃🕺",
      description:
          "Put on music and dance together! Learn moves, freestyle, or compete",
      icon: "�",
      suggestedDurations: [15, 20, 30, 45],
      defaultMode: ActivityMode.together,
      benefits: ["Cardio fun", "Mood boost", "Creativity", "Laughter"],
      difficultyLevel: 2,
    ),
    ActivityTemplate(
      type: ActivityType.photoHunt,
      name: "Photo Hunt Adventure! 📸🔍",
      description:
          "Create a list and hunt for cool photos! Compare your creativity",
      icon: "📸",
      suggestedDurations: [30, 45, 60, 90],
      defaultMode: ActivityMode.flexible,
      benefits: [
        "Creativity",
        "Exploration",
        "Memory making",
        "Fun competition",
      ],
      difficultyLevel: 2,
      requiresLocation: true,
    ),
    ActivityTemplate(
      type: ActivityType.gameNight,
      name: "Game Night Battle! 🎲🎮",
      description:
          "Board games, card games, or party games! Compete and have epic fun",
      icon: "🎲",
      suggestedDurations: [30, 45, 60, 90, 120],
      defaultMode: ActivityMode.together,
      benefits: [
        "Strategy thinking",
        "Social bonding",
        "Laughter",
        "Healthy competition",
      ],
      difficultyLevel: 2,
    ),
    ActivityTemplate(
      type: ActivityType.artChallenge,
      name: "Art Challenge! 🎨✨",
      description:
          "Create art together! Same topic, different styles, or collaborative pieces",
      icon: "🎨",
      suggestedDurations: [30, 45, 60, 90],
      defaultMode: ActivityMode.flexible,
      benefits: [
        "Creativity",
        "Relaxation",
        "Self-expression",
        "Artistic skills",
      ],
      difficultyLevel: 2,
    ),
    ActivityTemplate(
      type: ActivityType.musicJam,
      name: "Music Jam Session! 🎵🎸",
      description:
          "Make music together! Sing, play instruments, or create beats",
      icon: "�",
      suggestedDurations: [20, 30, 45, 60],
      defaultMode: ActivityMode.together,
      benefits: ["Musical skills", "Creativity", "Bonding", "Stress relief"],
      difficultyLevel: 2,
    ),
    ActivityTemplate(
      type: ActivityType.workoutBattle,
      name: "Workout Battle! 💪🔥",
      description:
          "Challenge each other with exercises! Push-ups, squats, planks - who's stronger?",
      icon: "💪",
      suggestedDurations: [15, 20, 30, 45],
      defaultMode: ActivityMode.together,
      benefits: ["Fitness", "Motivation", "Healthy competition", "Endorphins"],
      difficultyLevel: 3,
    ),
    ActivityTemplate(
      type: ActivityType.storytime,
      name: "Story Time! 📚✨",
      description:
          "Share stories, read together, or create tales! Let imagination run wild",
      icon: "📚",
      suggestedDurations: [20, 30, 45, 60],
      defaultMode: ActivityMode.together,
      benefits: ["Imagination", "Bonding", "Language skills", "Relaxation"],
      difficultyLevel: 1,
    ),
    ActivityTemplate(
      type: ActivityType.phoneDetoxChallenge,
      name: "Phone Detox Challenge! 📱❌",
      description:
          "Put phones away and do real-world activities! Who can last longest?",
      icon: "📱",
      suggestedDurations: [30, 45, 60, 90, 120],
      defaultMode: ActivityMode.together,
      benefits: [
        "Digital wellness",
        "Real connections",
        "Mindfulness",
        "Present moment",
      ],
      difficultyLevel: 4,
    ),
    ActivityTemplate(
      type: ActivityType.meditationCircle,
      name: "Meditation Circle! 🧘‍♀️🕯️",
      description:
          "Meditate together in peaceful harmony! Share the calming energy",
      icon: "🧘‍♀️",
      suggestedDurations: [10, 15, 20, 30],
      defaultMode: ActivityMode.together,
      benefits: [
        "Inner peace",
        "Stress relief",
        "Mindfulness",
        "Spiritual bonding",
      ],
      difficultyLevel: 2,
    ),
  ];

  // Get activity template by type
  static ActivityTemplate? getTemplate(ActivityType type) {
    try {
      return activityTemplates.firstWhere((template) => template.type == type);
    } catch (e) {
      return null;
    }
  }

  // Create a new activity
  static Future<String?> createActivity({
    required ActivityType type,
    required String title,
    required String description,
    required int durationMinutes,
    required ActivityMode mode,
    required DateTime scheduledTime,
    required List<String> buddyIds,
    String? locationNote,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

      final activity = DetoxBuddyActivity(
        id: '', // Will be set by Firestore
        type: type,
        title: title,
        description: description,
        durationMinutes: durationMinutes,
        mode: mode,
        status: ActivityStatus.pending,
        createdBy: currentUserId,
        participants: [currentUserId, ...buddyIds],
        scheduledTime: scheduledTime,
        locationNote: locationNote,
        motivationalMessages: _generateMotivationalMessages(
          type,
          durationMinutes,
        ),
      );

      final docRef = await _firestore
          .collection('detox_activities')
          .add(activity.toFirestore());

      // Send notifications to buddies
      await _notifyBuddies(docRef.id, buddyIds, activity);

      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  // Get activities for current user
  static Stream<List<DetoxBuddyActivity>> getUserActivities([String? userId]) {
    final currentUserId = userId ?? _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    // For local users, return empty stream
    if (currentUserId.startsWith('local_')) {
      return Stream.value([]);
    }

    return _firestore
        .collection('detox_activities')
        .where('participants', arrayContains: currentUserId)
        .orderBy('scheduledTime', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DetoxBuddyActivity.fromFirestore(doc))
              .toList(),
        );
  }

  // Start an activity
  static Future<bool> startActivity(String activityId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('detox_activities').doc(activityId).update({
        'status': ActivityStatus.active.index,
        'startTime': Timestamp.now(),
        'progress.$currentUserId.started': true,
        'progress.$currentUserId.startTime': Timestamp.now(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Complete an activity
  static Future<bool> completeActivity(
    String activityId, {
    String? note,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final updates = {
        'completionStatus.$currentUserId': true,
        'progress.$currentUserId.completed': true,
        'progress.$currentUserId.completedTime': Timestamp.now(),
      };

      if (note != null) {
        updates['progress.$currentUserId.note'] = note;
      }

      await _firestore
          .collection('detox_activities')
          .doc(activityId)
          .update(updates);

      // Check if all participants completed
      final doc = await _firestore
          .collection('detox_activities')
          .doc(activityId)
          .get();
      final activity = DetoxBuddyActivity.fromFirestore(doc);

      final allCompleted = activity.participants.every(
        (participantId) => activity.completionStatus[participantId] == true,
      );

      if (allCompleted) {
        await _firestore.collection('detox_activities').doc(activityId).update({
          'status': ActivityStatus.completed.index,
          'endTime': Timestamp.now(),
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Generate motivational messages based on activity type
  static List<String> _generateMotivationalMessages(
    ActivityType type,
    int duration,
  ) {
    final messages = <String>[];

    switch (type) {
      case ActivityType.cricket:
        messages.addAll([
          "� Time to hit some boundaries together!",
          "🔥 Cricket champions in the making!",
          "⚡ Show your batting and bowling skills!",
          "🌟 Team spirit and fun - that's cricket!",
        ]);
        break;
      case ActivityType.football:
        messages.addAll([
          "⚽ Goal! Let's kick some soccer balls!",
          "� Football fever - here we go!",
          "💨 Run, dribble, and score together!",
          "🌟 The beautiful game awaits you!",
        ]);
        break;
      case ActivityType.badminton:
        messages.addAll([
          "🏸 Smash time! Get ready for some rallies!",
          "⚡ Lightning-fast badminton action!",
          "� Shuttle wars - may the best player win!",
          "🌟 Quick reflexes and fun guaranteed!",
        ]);
        break;
      case ActivityType.tabletennis:
        messages.addAll([
          "🏓 Ping pong battles commence!",
          "⚡ Fast-paced table tennis fun!",
          "🔥 Paddle power - let's rally!",
          "🌟 Indoor sports at its finest!",
        ]);
        break;
      case ActivityType.bikeRideMusic:
        messages.addAll([
          "🚴‍♂️🎵 Pedal to the beat!",
          "🎶 Music and movement - perfect combo!",
          "🌟 Sing along while you cycle!",
          "🔥 Rhythm and wheels in harmony!",
        ]);
        break;
      case ActivityType.walkChat:
        messages.addAll([
          "🚶‍♂️💬 Walk and talk - best therapy!",
          "� Great conversations ahead!",
          "💫 Steps and stories together!",
          "🗣️ Fresh air and friendly chats!",
        ]);
        break;
      case ActivityType.cookingChallenge:
        messages.addAll([
          "👨‍🍳🔥 Chef mode activated!",
          "🍳 Cooking up some fun together!",
          "🌟 Delicious adventures await!",
          "👩‍🍳 Kitchen creativity unleashed!",
        ]);
        break;
      case ActivityType.danceParty:
        messages.addAll([
          "💃🕺 Let's dance the day away!",
          "🎵 Move to the rhythm!",
          "🔥 Dance floor domination time!",
          "✨ Express yourself through dance!",
        ]);
        break;
      case ActivityType.photoHunt:
        messages.addAll([
          "�🔍 Camera ready for adventure!",
          "🌟 Capture the perfect moments!",
          "📷 Photo hunt expedition begins!",
          "✨ Creative eyes, creative shots!",
        ]);
        break;
      case ActivityType.gameNight:
        messages.addAll([
          "�🎮 Game on! Let the battles begin!",
          "🔥 Victory awaits the clever!",
          "🌟 Fun and games galore!",
          "🎯 Strategy, luck, and laughter!",
        ]);
        break;
      case ActivityType.artChallenge:
        messages.addAll([
          "🎨✨ Unleash your inner artist!",
          "🖌️ Colors, creativity, and fun!",
          "🌟 Art magic happens here!",
          "💫 Express yourself beautifully!",
        ]);
        break;
      case ActivityType.musicJam:
        messages.addAll([
          "🎵🎸 Rock out together!",
          "🎶 Harmony and melody time!",
          "🔥 Musical magic in the making!",
          "🌟 Sing, play, create together!",
        ]);
        break;
      case ActivityType.workoutBattle:
        messages.addAll([
          "💪� Fitness challenge accepted!",
          "⚡ Stronger together!",
          "🏋️ Push your limits!",
          "🌟 Sweat, strength, and success!",
        ]);
        break;
      case ActivityType.storytime:
        messages.addAll([
          "📚✨ Story magic awaits!",
          "🌟 Tales and imagination!",
          "📖 Words that inspire!",
          "💫 Stories that connect hearts!",
        ]);
        break;
      case ActivityType.phoneDetoxChallenge:
        messages.addAll([
          "📱❌ Digital detox heroes!",
          "🌍 Real world adventures!",
          "👥 Genuine connections ahead!",
          "🧠 Mind freedom challenge!",
        ]);
        break;
      case ActivityType.meditationCircle:
        messages.addAll([
          "🧘‍♀️🕯️ Peace and harmony together!",
          "✨ Inner calm multiplied!",
          "🌊 Shared serenity flows!",
          "💫 Mindful moments together!",
        ]);
        break;
      default:
        messages.addAll([
          "🌟 Amazing activity ahead!",
          "💪 Fun and friendship guaranteed!",
          "🎯 Let's make memories together!",
          "✨ This will be awesome!",
        ]);
    }

    // Add duration-specific messages
    if (duration >= 30) {
      messages.add("⏰ $duration minutes of self-care - you've got this!");
    } else {
      messages.add("⚡ Quick $duration-minute boost coming up!");
    }

    return messages..shuffle();
  }

  // Notify buddies about new activity
  static Future<void> _notifyBuddies(
    String activityId,
    List<String> buddyIds,
    DetoxBuddyActivity activity,
  ) async {
    // This would integrate with your notification system
    // For now, we'll create notification documents
    for (final buddyId in buddyIds) {
      await _firestore.collection('notifications').add({
        'userId': buddyId,
        'type': 'activity_invitation',
        'title': 'New Activity Invitation!',
        'message': '${activity.createdBy} invited you to: ${activity.title}',
        'activityId': activityId,
        'createdAt': Timestamp.now(),
        'read': false,
      });
    }
  }

  // Accept activity invitation
  static Future<bool> acceptActivityInvitation(String activityId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('detox_activities').doc(activityId).update({
        'status': ActivityStatus.accepted.index,
        'progress.$currentUserId.accepted': true,
        'progress.$currentUserId.acceptedTime': Timestamp.now(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Decline activity invitation
  static Future<bool> declineActivityInvitation(String activityId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('detox_activities').doc(activityId).update({
        'status': ActivityStatus.cancelled.index,
        'progress.$currentUserId.declined': true,
        'progress.$currentUserId.declinedTime': Timestamp.now(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Which kind of provider an appointment is with.
enum ProviderKind { coach, doctor }

/// How the consultation happens. Both calls run inside the app via a private
/// video room; a voice call simply starts audio-only.
enum ConsultMode { videoCall, audioCall }

extension ConsultModeX on ConsultMode {
  String get label => switch (this) {
        ConsultMode.videoCall => 'Video call',
        ConsultMode.audioCall => 'Voice call',
      };
}

enum AppointmentStatus {
  requested,
  confirmed,
  rescheduled,
  completed,
  cancelled,
  noShow,
}

extension AppointmentStatusX on AppointmentStatus {
  String get label => switch (this) {
        AppointmentStatus.requested => 'Requested',
        AppointmentStatus.confirmed => 'Confirmed',
        AppointmentStatus.rescheduled => 'Rescheduled',
        AppointmentStatus.completed => 'Completed',
        AppointmentStatus.cancelled => 'Cancelled',
        AppointmentStatus.noShow => 'No-show',
      };
}

/// A coach or doctor appointment. Mirrors the Firestore `appointments/{id}`
/// document.
class Appointment {
  const Appointment({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.providerRole,
    required this.type,
    required this.requestedAt,
    this.scheduledAt,
    this.status = AppointmentStatus.requested,
    this.notes,
    this.participantCity,
    this.mode = ConsultMode.videoCall,
    this.meetingRoom,
    this.confirmedAt,
    this.providerNote,
    this.noteAt,
    this.followUpAt,
  });

  final String id;
  final String participantId;
  final String participantName;
  final ProviderKind providerRole;
  final String type; // e.g. "Yoga", "Diet Plan"
  final DateTime requestedAt;
  final DateTime? scheduledAt;
  final AppointmentStatus status;
  final String? notes;
  final String? participantCity;

  /// Voice vs. video call.
  final ConsultMode mode;

  /// Private room id for the in-app call. Built at booking time; the same id
  /// is shared by the participant and the provider so both join the same room.
  final String? meetingRoom;

  /// When the provider confirmed the booking (drives the "confirmed"
  /// notification). Null until confirmed.
  final DateTime? confirmedAt;

  /// The doctor's/trainer's post-call note or prescription, visible to the
  /// participant. Null until the provider adds one.
  final String? providerNote;

  /// When the provider note was last saved (drives the "notes shared" alert).
  final DateTime? noteAt;

  /// An optional follow-up date the doctor/trainer recommends. Shown to the
  /// participant so they can book their next consultation on time.
  final DateTime? followUpAt;

  /// The in-app call URL (a private Jitsi room). Voice calls start audio-only.
  /// Returns null until a room has been assigned.
  String? get meetingUrl {
    final room = meetingRoom;
    if (room == null || room.isEmpty) return null;
    final base = 'https://meet.jit.si/$room';
    return mode == ConsultMode.audioCall
        ? '$base#config.startAudioOnly=true'
        : base;
  }

  Appointment copyWith({
    AppointmentStatus? status,
    DateTime? scheduledAt,
    String? notes,
    DateTime? confirmedAt,
    String? providerNote,
    DateTime? noteAt,
    DateTime? followUpAt,
  }) =>
      Appointment(
        id: id,
        participantId: participantId,
        participantName: participantName,
        providerRole: providerRole,
        type: type,
        requestedAt: requestedAt,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        participantCity: participantCity,
        mode: mode,
        meetingRoom: meetingRoom,
        confirmedAt: confirmedAt ?? this.confirmedAt,
        providerNote: providerNote ?? this.providerNote,
        noteAt: noteAt ?? this.noteAt,
        followUpAt: followUpAt ?? this.followUpAt,
      );
}

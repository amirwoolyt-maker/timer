/// Wall-clock based timing. Rendering frequency never determines study duration.
class StudyClock {
  const StudyClock({this.elapsedSeconds = 0, this.runningSince});

  final int elapsedSeconds;
  final DateTime? runningSince;

  bool get running => runningSince != null;

  int elapsedAt(DateTime now) {
    final extra = runningSince == null
        ? 0
        : now.difference(runningSince!).inSeconds;
    return elapsedSeconds + (extra < 0 ? 0 : extra);
  }

  StudyClock start(DateTime now) => running
      ? this
      : StudyClock(elapsedSeconds: elapsedSeconds, runningSince: now);

  StudyClock pause(DateTime now) => StudyClock(elapsedSeconds: elapsedAt(now));

  int remainingAt(DateTime now, int durationSeconds) =>
      (durationSeconds - elapsedAt(now)).clamp(0, durationSeconds);
}

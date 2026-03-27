/// UTC-safe countdown for persisted phase deadlines (aligns wall clock on resume).
int secondsRemainingUntilUtc(DateTime nowUtc, DateTime phaseEndUtc) {
  final d = phaseEndUtc.difference(nowUtc).inSeconds;
  return d < 0 ? 0 : d;
}

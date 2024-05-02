enum ScooterKeylessDistance {
  hard(-55, "auto_unlock_threshold_hard"),
  regular(-65, "auto_unlock_threshold_regular"),
  easy(-75, "auto_unlock_threshold_easy");

  const ScooterKeylessDistance(this.threshold, this.translationKey);

  final int threshold;
  final String translationKey;

  static fromThreshold(int threshold) {
    return ScooterKeylessDistance.values
        .firstWhere((distance) => distance.threshold == threshold);
  }

  static getMinDistance() {
    return ScooterKeylessDistance.easy;
  }

  static getMaxDistance() {
    return ScooterKeylessDistance.hard;
  }

  String getFormattedThreshold() {
    return "$threshold dBm";
  }
}
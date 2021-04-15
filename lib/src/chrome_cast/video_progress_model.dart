class VideoProgress {
  Duration currentProgress;
  Duration videoDuration;

  VideoProgress({this.currentProgress, this.videoDuration});

  VideoProgress.fromJson(Map<String, String> map) {
    currentProgress =
        Duration(milliseconds: double.parse(map['progress']).toInt());
    videoDuration =
        Duration(milliseconds: double.parse(map['duration']).toInt());
  }
}

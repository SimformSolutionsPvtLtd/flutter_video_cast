# Copilot Instructions for flutter_video_cast

## Project Overview
`flutter_video_cast` is a Flutter plugin that enables video casting to **Chromecast (Google Cast)** and **AirPlay (Apple TV)** from Flutter apps. It provides platform-specific cast buttons and playback control for streaming video content to external displays.

## Architecture

### Plugin Structure
```
flutter_video_cast/
├── lib/
│   ├── flutter_video_cast.dart        # Main export
│   └── src/
│       ├── chrome_cast/               # Chromecast (Android/iOS)
│       │   ├── chrome_cast_platform.dart
│       │   ├── chrome_cast_controller.dart
│       │   ├── chrome_cast_button.dart
│       │   └── video_progress_model.dart
│       └── air_play/                  # AirPlay (iOS only)
│           ├── air_play_platform.dart
│           └── air_play_button.dart
├── android/                           # Android implementation (Google Cast SDK)
├── ios/                               # iOS implementation (both Cast & AirPlay)
└── example/                           # Example app
```

### Platform Support

| Feature | iOS | Android |
|---------|-----|---------|
| Chromecast (Google Cast) | ✅ | ✅ |
| AirPlay | ✅ | ❌ |
| Local network discovery | ✅ | ✅ |
| Playback controls | ✅ | ✅ |

### Communication Flow
```
Dart (Cast API)
  ↕ MethodChannel
Android (Cast SDK) / iOS (Cast Framework + AirPlay)
  ↕
Chromecast Device / Apple TV
```

## Core API

### Chromecast Integration

#### 1. Initialize Context (Required)
```dart
import 'package:flutter_video_cast/flutter_video_cast.dart';

// Initialize Google Cast context (iOS only, Android auto-inits)
// Must be called before using ChromeCast features
await ChromeCastController.initialize();
```

#### 2. Add Cast Button to UI
```dart
// Cast button with automatic device discovery
class VideoPlayerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
        actions: [
          ChromeCastButton(
            size: 30.0,
            color: Colors.white,
            // Optional: callbacks
            onButtonCreated: (controller) {
              _chromeCastController = controller;
            },
            onSessionStarted: () {
              print('Cast session started');
            },
            onSessionEnded: () {
              print('Cast session ended');
            },
          ),
        ],
      ),
      body: VideoPlayerWidget(),
    );
  }
}
```

#### 3. Load Video to Cast Device
```dart
class _VideoPlayerState extends State<VideoPlayerScreen> {
  ChromeCastController? _castController;

  Future<void> _castVideo(String videoUrl) async {
    if (_castController == null) return;
    
    // Load video with metadata
    await _castController!.loadMedia(
      videoUrl,
      title: 'Episode 1',
      subtitle: 'Season 1',
      imageUrl: 'https://example.com/thumbnail.jpg',
      autoPlay: true,
      startTime: 0.0, // Start from beginning
    );
  }

  // Get cast button controller
  void _onCastButtonCreated(ChromeCastController controller) {
    setState(() {
      _castController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChromeCastButton(
          onButtonCreated: _onCastButtonCreated,
        ),
        ElevatedButton(
          onPressed: () => _castVideo('https://example.com/video.mp4'),
          child: Text('Cast Video'),
        ),
      ],
    );
  }
}
```

#### 4. Playback Controls
```dart
class ChromecastControls {
  final ChromeCastController controller;

  ChromecastControls(this.controller);

  // Play/Pause
  Future<void> play() => controller.play();
  Future<void> pause() => controller.pause();

  // Seek
  Future<void> seek(double position) => controller.seek(position);

  // Stop casting
  Future<void> stop() => controller.stop();

  // Check connection status
  Future<bool> isConnected() => controller.isConnected();

  // Get playback position
  Future<VideoProgressModel?> getProgress() async {
    final progress = await controller.position();
    return progress;
  }
}
```

#### 5. Listen to Cast State
```dart
class _VideoPlayerState extends State<VideoPlayerScreen> {
  bool _isCasting = false;

  void _setupCastListeners(ChromeCastController controller) {
    controller.onSessionStarted?.call(() {
      setState(() => _isCasting = true);
      _pauseLocalPlayer(); // Pause local video player
    });

    controller.onSessionEnded?.call(() {
      setState(() => _isCasting = false);
      _resumeLocalPlayer(); // Resume local playback
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LocalVideoPlayer(isVisible: !_isCasting),
        if (_isCasting)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cast_connected, size: 100),
                Text('Casting to TV...'),
              ],
            ),
          ),
      ],
    );
  }
}
```

### AirPlay Integration (iOS Only)

#### Add AirPlay Button
```dart
// Simple AirPlay button for iOS
class VideoPlayerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (Platform.isIOS)
            AirPlayButton(
              size: 30.0,
              color: Colors.white,
              activeColor: Colors.blue,
            ),
        ],
      ),
      body: VideoPlayerWidget(),
    );
  }
}
```

**Note**: AirPlay button triggers native iOS AirPlay picker. Video routing is handled by AVPlayer automatically - no manual playback control needed from Dart.

## VideoProgressModel

```dart
class VideoProgressModel {
  final double position;      // Current playback position (seconds)
  final double duration;      // Total video duration (seconds)
  final bool isPlaying;       // Playback state
  
  double get progress => duration > 0 ? position / duration : 0.0;
}
```

## Platform-Specific Setup

### iOS Configuration

#### 1. Update AppDelegate
Initialize Google Cast context in your AppDelegate.

**Swift** (`ios/Runner/AppDelegate.swift`):
```swift
import UIKit
import Flutter
import GoogleCast

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Initialize Google Cast
    let receiverAppID = "YOUR_RECEIVER_APP_ID" // Or use kGCKDefaultMediaReceiverApplicationID
    let criteria = GCKDiscoveryCriteria(applicationID: receiverAppID)
    let options = GCKCastOptions(discoveryCriteria: criteria)
    
    // Enable local network discovery
    options.physicalVolumeButtonsWillControlDeviceVolume = true
    
    GCKCastContext.setSharedInstanceWith(options)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**Objective-C** (`ios/Runner/AppDelegate.m`):
```objc
#import "AppDelegate.h"
#import <GoogleCast/GoogleCast.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
  // Initialize Google Cast
  NSString *receiverAppID = @"YOUR_RECEIVER_APP_ID";
  GCKDiscoveryCriteria *criteria = [[GCKDiscoveryCriteria alloc] initWithApplicationID:receiverAppID];
  GCKCastOptions *options = [[GCKCastOptions alloc] initWithDiscoveryCriteria:criteria];
  [GCKCastContext setSharedInstanceWithOptions:options];
  
  [GeneratedPluginRegistrant registerWithRegistry:self];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
```

#### 2. Enable Local Network Permission
Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Required to discover and connect to casting devices on your local network</string>

<key>NSBonjourServices</key>
<array>
  <string>_googlecast._tcp</string>
  <string>_airplay._tcp</string>
</array>
```

#### 3. Minimum iOS Version
Set minimum deployment target to **iOS 11.0** or higher in `ios/Podfile`:
```ruby
platform :ios, '11.0'
```

### Android Configuration

#### 1. Add Google Cast Dependency
Update `android/app/build.gradle`:
```gradle
dependencies {
    implementation 'com.google.android.gms:play-services-cast-framework:21.1.0'
    // ... other dependencies
}
```

#### 2. Add Cast Options Provider
Create `android/app/src/main/java/com/example/app/CastOptionsProvider.java`:
```java
package com.example.app;

import android.content.Context;
import com.google.android.gms.cast.framework.CastOptions;
import com.google.android.gms.cast.framework.OptionsProvider;
import com.google.android.gms.cast.framework.SessionProvider;
import com.google.android.gms.cast.framework.media.CastMediaOptions;
import java.util.List;

public class CastOptionsProvider implements OptionsProvider {
    @Override
    public CastOptions getCastOptions(Context context) {
        return new CastOptions.Builder()
            .setReceiverApplicationId("YOUR_RECEIVER_APP_ID")
            .build();
    }

    @Override
    public List<SessionProvider> getAdditionalSessionProviders(Context context) {
        return null;
    }
}
```

#### 3. Register in AndroidManifest.xml
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<application>
    <!-- ... -->
    
    <meta-data
        android:name="com.google.android.gms.cast.framework.OPTIONS_PROVIDER_CLASS_NAME"
        android:value="com.example.app.CastOptionsProvider" />
        
</application>
```

## Integration Patterns

### Seamless Local-to-Cast Transition
```dart
class VideoPlayerManager {
  VideoPlayerController? localPlayer;
  ChromeCastController? castController;
  
  String currentVideoUrl = '';
  double lastPosition = 0.0;
  
  Future<void> switchToCast() async {
    if (localPlayer != null) {
      lastPosition = await localPlayer!.position();
      await localPlayer!.pause();
    }
    
    await castController?.loadMedia(
      currentVideoUrl,
      startTime: lastPosition,
      autoPlay: true,
    );
  }
  
  Future<void> switchToLocal() async {
    if (castController != null) {
      final progress = await castController!.position();
      lastPosition = progress?.position ?? 0.0;
      await castController!.stop();
    }
    
    await localPlayer?.seekTo(Duration(seconds: lastPosition.toInt()));
    await localPlayer?.play();
  }
}
```

### Cast with Custom UI
```dart
class CastControlScreen extends StatefulWidget {
  @override
  _CastControlScreenState createState() => _CastControlScreenState();
}

class _CastControlScreenState extends State<CastControlScreen> {
  ChromeCastController? _controller;
  VideoProgressModel? _progress;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _startProgressUpdates();
  }

  void _startProgressUpdates() {
    _progressTimer = Timer.periodic(Duration(seconds: 1), (_) async {
      if (_controller != null) {
        final progress = await _controller!.position();
        setState(() => _progress = progress);
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress bar
        if (_progress != null)
          Slider(
            value: _progress!.position,
            max: _progress!.duration,
            onChanged: (value) => _controller?.seek(value),
          ),
        
        // Play/Pause
        IconButton(
          icon: Icon(_progress?.isPlaying ?? false ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            if (_progress?.isPlaying ?? false) {
              _controller?.pause();
            } else {
              _controller?.play();
            }
          },
        ),
        
        // Stop casting
        ElevatedButton(
          onPressed: () => _controller?.stop(),
          child: Text('Stop Casting'),
        ),
      ],
    );
  }
}
```

## Best Practices

### 1. Handle Connection State
```dart
class CastManager {
  ChromeCastController? controller;
  ValueNotifier<bool> isCasting = ValueNotifier(false);
  
  void setupController(ChromeCastController controller) {
    this.controller = controller;
    
    controller.onSessionStarted?.call(() {
      isCasting.value = true;
    });
    
    controller.onSessionEnded?.call(() {
      isCasting.value = false;
    });
  }
  
  void dispose() {
    isCasting.dispose();
  }
}
```

### 2. Error Handling
```dart
Future<void> safeCastVideo(String url) async {
  try {
    final isConnected = await _castController?.isConnected() ?? false;
    
    if (!isConnected) {
      showError('No cast device connected');
      return;
    }
    
    await _castController?.loadMedia(url);
  } catch (e) {
    showError('Failed to cast video: $e');
  }
}
```

### 3. Persist Playback State
```dart
class CastStateManager {
  static const _key = 'cast_playback_state';
  
  static Future<void> saveState(VideoProgressModel progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, progress.position);
  }
  
  static Future<double?> restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key);
  }
}
```

## Common Issues & Solutions

### 1. Cast Button Not Showing
- **iOS**: Check `GCKCastContext` is initialized in AppDelegate
- **Android**: Verify `CastOptionsProvider` is registered in manifest
- **Both**: Ensure device is on same network as Chromecast

### 2. Receiver App ID
- Use `kGCKDefaultMediaReceiverApplicationID` for standard media playback
- Or create custom receiver app ID in Google Cast Console

### 3. Local Network Permission (iOS)
- Ensure `NSBonjourServices` includes `_googlecast._tcp`
- Check user granted local network permission in iOS settings

### 4. Video Won't Load on Cast Device
- Verify video URL is publicly accessible (not localhost)
- Check video format is supported (MP4, HLS recommended)
- Ensure CORS headers allow casting from Cast SDK

## Supported Video Formats

| Format | Chromecast | AirPlay |
|--------|-----------|---------|
| MP4 (H.264) | ✅ | ✅ |
| HLS (.m3u8) | ✅ | ✅ |
| DASH | ✅ | ❌ |
| WebM | ✅ | ❌ |

## Documentation Requirements
- Document supported video formats and codecs
- Include setup steps for both platforms
- Provide examples for common use cases
- Note platform-specific limitations

Example:
```dart
/// Loads a video to the connected cast device.
///
/// [url] The publicly accessible URL of the video to cast.
/// [title] Optional title shown in cast UI.
/// [subtitle] Optional subtitle shown in cast UI.
/// [imageUrl] Optional thumbnail image URL.
/// [autoPlay] Whether to start playback immediately (default: true).
/// [startTime] Playback start position in seconds (default: 0.0).
///
/// Throws [PlatformException] if:
/// - No cast device is connected
/// - Video URL is not accessible
/// - Video format is not supported
///
/// Supported formats: MP4 (H.264), HLS (.m3u8)
///
/// Example:
/// ```dart
/// await controller.loadMedia(
///   'https://example.com/video.mp4',
///   title: 'My Video',
///   imageUrl: 'https://example.com/thumb.jpg',
/// );
/// ```
Future<void> loadMedia(
  String url, {
  String? title,
  String? subtitle,
  String? imageUrl,
  bool autoPlay = true,
  double startTime = 0.0,
});
```

## Reference

### Key Files
- `lib/flutter_video_cast.dart`: Main export
- `lib/src/chrome_cast/chrome_cast_controller.dart`: Chromecast controls
- `lib/src/chrome_cast/chrome_cast_button.dart`: Cast button widget
- `lib/src/air_play/air_play_button.dart`: AirPlay button widget

### Dependencies
- Google Cast SDK (iOS & Android)
- AVFoundation (iOS, for AirPlay)

### Related Documentation
- Google Cast SDK: https://developers.google.com/cast
- Apple AirPlay: https://developer.apple.com/airplay/
- Cast Developer Console: https://cast.google.com/publish

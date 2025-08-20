import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Broad extends StatefulWidget {
  final String channelName;
  final bool isStreamer;

  const Broad({
    super.key,
    required this.channelName,
    required this.isStreamer,
  });

  @override
  State<Broad> createState() => _BroadState();
}

class _BroadState extends State<Broad> {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _mutedLocalAudio = false;
  bool _mutedLocalVideo = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: dotenv.env['APP_ID'] ?? '',
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Local user joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Remote user joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("Remote user left");
          setState(() {
            _remoteUid = null;
          });
        },
        onError: (ErrorCodeType errorCode, String msg) {
          debugPrint("Error: $errorCode - $msg");
        },
      ),
    );

    await _engine.setClientRole(
      role: widget.isStreamer
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );
    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.setDefaultAudioRouteToSpeakerphone(true);

    VideoEncoderConfiguration videoEncoderConfiguration =
        const VideoEncoderConfiguration(
      dimensions: VideoDimensions(width: 640, height: 360),
      frameRate: 15,
      bitrate: 0,
    );
    await _engine.setVideoEncoderConfiguration(videoEncoderConfiguration);

    await _engine.joinChannel(
      token: dotenv.env['TOKEN'] ?? '',
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void _onToggleMute() {
    setState(() {
      _mutedLocalAudio = !_mutedLocalAudio;
    });
    _engine.muteLocalAudioStream(_mutedLocalAudio);
  }

  void _onToggleCamera() {
    setState(() {
      _mutedLocalVideo = !_mutedLocalVideo;
    });
    _engine.muteLocalVideoStream(_mutedLocalVideo);
  }

  void _onCallEnd() {
    _engine.leaveChannel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video views
            _buildVideoViews(),
            
            // Control buttons
            if (widget.isStreamer)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: _mutedLocalAudio ? Icons.mic_off : Icons.mic,
                        onPressed: _onToggleMute,
                        color: _mutedLocalAudio ? Colors.red : Colors.white,
                      ),
                      _buildControlButton(
                        icon: _mutedLocalVideo ? Icons.videocam_off : Icons.videocam,
                        onPressed: _onToggleCamera,
                        color: _mutedLocalVideo ? Colors.red : Colors.white,
                      ),
                      _buildControlButton(
                        icon: Icons.call_end,
                        onPressed: _onCallEnd,
                        color: Colors.red,
                        isLarge: true,
                      ),
                    ],
                  ),
                ),
              ),
            
            // Channel info overlay
            Positioned(
              top: 20.h,
              left: 20.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isStreamer ? Icons.live_tv : Icons.remove_red_eye,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      widget.channelName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoViews() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Remote video
          if (_remoteUid != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: const RtcConnection(channelId: ""),
              ),
            ),
          
          // Local video (small overlay for streamer)
          if (_localUserJoined && widget.isStreamer)
            Positioned(
              top: 100.h,
              right: 20.w,
              child: Container(
                width: 120.w,
                height: 160.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isLarge ? 60.w : 50.w,
        height: isLarge ? 60.h : 50.h,
        decoration: BoxDecoration(
          color: isLarge ? color : Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: isLarge ? 3 : 2,
          ),
        ),
        child: Icon(
          icon,
          color: isLarge ? Colors.white : color,
          size: isLarge ? 24.sp : 20.sp,
        ),
      ),
    );
  }
}

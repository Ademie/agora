import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'broad.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _channelNameController = TextEditingController();

  @override
  void dispose() {
    _channelNameController.dispose();
    super.dispose();
  }

  Future<void> _showChannelDialog({
    required bool isStreamer,
    required String title,
    required String buttonText,
  }) async {
    debugPrint("💬 === SHOWING CHANNEL DIALOG ===");
    debugPrint("👤 User Role: ${isStreamer ? 'STREAMER' : 'VIEWER'}");
    debugPrint("📝 Dialog Title: $title");
    debugPrint("🔘 Button Text: $buttonText");
    debugPrint("💬 =============================");
    
    _channelNameController.clear();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isStreamer 
                    ? 'Enter a channel name to start streaming'
                    : 'Enter the channel name to join',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _channelNameController,
                decoration: InputDecoration(
                  hintText: 'Channel Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                onSubmitted: (value) => _joinChannel(isStreamer),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
            ElevatedButton(
              onPressed: () => _joinChannel(isStreamer),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                buttonText,
                style: TextStyle(fontSize: 16.sp),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinChannel(bool isStreamer) async {
    final channelName = _channelNameController.text.trim();
    
    if (channelName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a channel name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Close the dialog
    Navigator.of(context).pop();

    debugPrint("🎯 === USER INITIATING STREAMING ===");
    debugPrint("📺 Channel Name: $channelName");
    debugPrint("👤 User Role: ${isStreamer ? 'STREAMER' : 'VIEWER'}");
    debugPrint("📱 Platform: ${Theme.of(context).platform}");
    debugPrint("🎯 ================================");

    // Request permissions
    await [Permission.camera, Permission.microphone].request();

    // Navigate to broadcast screen
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Broad(
            channelName: channelName,
            isStreamer: isStreamer,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 100.h,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40.h),
                  
                  // App Logo/Title
                  Icon(
                    Icons.video_call,
                    size: 60.sp,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Agora Live Streaming',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Connect and share with the world',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 40.h),
                  
                  // Streamer Button
                  _buildActionButton(
                    title: 'Start Streaming',
                    subtitle: 'Go live and share your content',
                    icon: Icons.live_tv,
                    color: Colors.red,
                    onTap: () => _showChannelDialog(
                      isStreamer: true,
                      title: 'Start Streaming',
                      buttonText: 'Start Stream',
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // Viewer Button
                  _buildActionButton(
                    title: 'Join as Viewer',
                    subtitle: 'Watch live streams',
                    icon: Icons.remove_red_eye,
                    color: Colors.blue,
                    onTap: () => _showChannelDialog(
                      isStreamer: false,
                      title: 'Join Channel',
                      buttonText: 'Join',
                    ),
                  ),
                  
                  SizedBox(height: 30.h),
                  
                  // Footer text
                  Text(
                    'Make sure you have a stable internet connection',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
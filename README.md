# Agora Live Streaming App

A modern Flutter application for live streaming using Agora RTC Engine. This app allows users to either start streaming as a broadcaster or join existing streams as viewers.

## Features

### 🎥 Live Streaming
- **Start Streaming**: Create a new channel and go live
- **Join as Viewer**: Watch live streams by entering channel names
- **Real-time Video**: High-quality video streaming with low latency
- **Channel Sharing**: Streamers can easily share their channel names

### 🎨 Modern UI
- **Responsive Design**: Optimized for different screen sizes using flutter_screenutil
- **Material Design 3**: Modern UI components and animations
- **Dark Theme**: Professional streaming interface with dark colors
- **Intuitive Navigation**: Easy-to-use interface for both streamers and viewers

### 🔧 Technical Features
- **Agora RTC Engine**: Professional-grade video streaming
- **Permission Handling**: Automatic camera and microphone permissions
- **State Management**: Proper lifecycle management and cleanup
- **Error Handling**: Graceful error handling and user feedback

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Agora App ID and Token
- iOS/Android development environment

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd agora
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Agora credentials:
   - Update `lib/constants.dart` with your Agora App ID and Token

4. Run the app:
```bash
flutter run
```

## Usage

### For Streamers
1. Open the app and tap "Start Streaming"
2. Enter a channel name in the dialog
3. Grant camera and microphone permissions
4. Your stream will start and the channel name will be displayed
5. Share the channel name with viewers using the share button

### For Viewers
1. Open the app and tap "Join as Viewer"
2. Enter the channel name provided by the streamer
3. Grant camera and microphone permissions (for audio)
4. Watch the live stream

## Architecture

The app follows clean architecture principles with:

- **Presentation Layer**: UI components and state management
- **Business Logic Layer**: Agora engine setup and event handling
- **Data Layer**: Constants and configuration

### Key Components

- `HomePage`: Main entry point with streaming options
- `Broad`: Video streaming screen with Agora integration
- `constants.dart`: App configuration and Agora credentials

## Dependencies

- `agora_rtc_engine`: Video streaming engine
- `permission_handler`: Camera and microphone permissions
- `flutter_screenutil`: Responsive design utilities

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.
## Support

For issues and questions:
- Check the [Agora documentation](https://docs.agora.io/)
- Review Flutter documentation for UI components
- Open an issue in this repository


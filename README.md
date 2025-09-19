# Noetica - Smart Learning Companion

<div align="center">
  <h3>ML powered tool to assist learning</h3>
  <p>A comprehensive iOS learning platform that combines note-taking, flashcards, AR visualization, and intelligent study analytics.</p>
</div>

---

## Features

###  **Smart Note-Taking**
- **Rich Text Editor** with formatting tools and voice input
- **ML-Powered Subject Classification** - Automatically categorizes notes using machine learning
- **OCR Text Capture** - Extract text from images and documents
- **Voice-to-Text** - Convert speech to written notes seamlessly
- **Organized by Subject** - Automatic and manual subject organization

###  **Intelligent Flashcards**
- **Spaced Repetition System** - Optimized review scheduling based on performance
- **Custom Deck Creation** - Organize flashcards by topics and subjects
- **Difficulty Tracking** - Adaptive learning based on your mastery level
- **Review Analytics** - Track your learning progress and retention rates

###  **AR Flashcard Experience**
- **Augmented Reality Review** - Study flashcards in immersive 3D space
- **Interactive 3D Cards** - Tap to flip and navigate through cards
- **Spatial Learning** - Enhanced memory retention through spatial visualization
- **Real-time Text Rendering** - Dynamic content display in AR environment

###  **Pomodoro Timer Integration**
- **Focus Sessions** - Built-in Pomodoro timer for productive study sessions
- **Session Tracking** - Monitor study time and break patterns
- **Calendar Integration** - Schedule and track study sessions
- **Background Timer** - Continue timing while using other app features

###  **Advanced Analytics**
- **Study Statistics** - Comprehensive insights into your learning patterns
- **Progress Tracking** - Visual representation of your improvement over time
- **Subject Performance** - Detailed breakdown by subject and topic
- **Streak Tracking** - Maintain and visualize your study consistency

###  **Smart Calendar**
- **Study Session Planning** - Schedule and organize your learning time
- **Event Integration** - Link study sessions with calendar events
- **Progress Visualization** - See your study history at a glance
- **Reminder System** - Never miss a study session

##  Technology Stack

### **Core Technologies**
- **SwiftUI** - Modern declarative UI framework
- **Core Data** - Local data persistence and management
- **Firebase Authentication** - Secure user authentication and management
- **ARKit & RealityKit** - Augmented reality flashcard experience
- **Core ML** - Machine learning for text classification
- **AVFoundation** - Audio recording and playback
- **Vision Framework** - OCR text recognition from images

### **Architecture Patterns**
- **MVVM (Model-View-ViewModel)** - Clean separation of concerns
- **Dependency Injection** - Modular and testable code structure
- **Repository Pattern** - Abstracted data access layer
- **Observer Pattern** - Reactive UI updates with Combine framework

### **Key Frameworks**
SwiftUI
CoreData
Firebase
ARKit
RealityKit
CoreML
Vision
AVFoundation
Combine

---

## How to setup

1. **Clone the Repository**
   git clone https://github.com/MesQue1041/Noetica.git
   cd noetica

2. **Open in Xcode**

3. **Configure Firebase**
   - Create a new Firebase project at 'https://console.firebase.google.com'
   - Add your iOS app to the project
   - Download 'GoogleService-Info.plist'
   - Add the file to your Xcode project

5. **Build and Run**
   - Select your target device or simulator and run

### **Required Permissions**
Add these permissions to your 'Info.plist':
<key>NSCameraUsageDescription</key>
<string>Camera access is required for AR flashcard experience and OCR text capture.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for voice-to-text note taking.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is required for OCR text extraction from images.</string>

---

##  Key Features Deep Dive

### **Machine Learning Integration**
- **Text Classification Model** - Automatically categorizes notes by subject
- **Natural Language Processing** - Extracts key topics and themes
- **Confidence Scoring** - Provides reliability metrics for predictions
- **Continuous Learning** - Model improves with user feedback

### **Spaced Repetition Algorithm**

### **AR Implementation**
- **3D Text Rendering** - Dynamic text textures in AR space
- **Gesture Recognition** - Tap-to-flip and navigation controls
- **Spatial Anchoring** - Consistent card positioning in 3D space

---


### **Core ML Model**
The app includes a custom text classification model:
- **Input**: Raw text content
- **Output**: Subject category with confidence score
- **Training Data**: Educational content across multiple subjects
- **Accuracy**: ~85% on test dataset

---

##  Analytics & Tracking

### **Study Metrics**
- **Session Duration** - Time spent in focused study
- **Cards Reviewed** - Number of flashcards studied
- **Accuracy Rate** - Percentage of correct answers
- **Streak Tracking** - Consecutive days of study activity
- **Subject Distribution** - Time allocation across different topics

### **Performance Insights**
- **Learning Velocity** - Rate of knowledge acquisition
- **Retention Analysis** - Long-term memory performance
- **Difficulty Trends** - Areas requiring additional focus
- **Optimal Study Times** - Peak performance periods

---

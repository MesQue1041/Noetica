//
//  MainTabView.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-11.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var statsService: StatsService
    @StateObject private var timerService = PomodoroTimerService.shared
    @StateObject private var navigationService = NavigationService.shared
    @State private var showCreatePage = false
    @State private var showPomodoroView = false
    
    var body: some View {
           ZStack(alignment: .bottom) {
               TabView(selection: $navigationService.selectedTab) {
                   HomeDashboardView()
                       .tabItem { EmptyView() }
                       .tag(0)
                       .environment(\.managedObjectContext, CoreDataService.shared.context)
                       .environmentObject(statsService)
                       .environmentObject(authService)
                   
                   NotesExplorerView()
                       .tabItem { EmptyView() }
                       .tag(1)
                       .environment(\.managedObjectContext, CoreDataService.shared.context)
                       .environmentObject(statsService)
                       .environmentObject(authService)
                   
                   PomodoroTimerView(preloadedEvent: nil)
                       .tabItem { EmptyView() }
                       .tag(2)
                       .environment(\.managedObjectContext, CoreDataService.shared.context)
                       .environmentObject(authService)
                   
                   CalendarView()
                       .tabItem { EmptyView() }
                       .tag(3)
                       .environment(\.managedObjectContext, CoreDataService.shared.context)
                       .environmentObject(statsService)
                       .environmentObject(authService)
                   
                   StatsView()
                       .tabItem { EmptyView() }
                       .tag(4)
                       .environment(\.managedObjectContext, CoreDataService.shared.context)
                       .environmentObject(statsService)
                       .environmentObject(authService)
               }

               .tabViewStyle(.page(indexDisplayMode: .never))
               
               VStack(spacing: 0) {
                   if timerService.isRunning {
                       timerStatusBar
                   }
                   
                   CustomTabBar(selectedTab: $navigationService.selectedTab, showCreatePage: $showCreatePage)
               }
           }
           .sheet(isPresented: $showCreatePage) {
               CreatePageView()
                   .environment(\.managedObjectContext, CoreDataService.shared.context)
                   .environmentObject(statsService)
                   .environmentObject(authService)
           }
           .onChange(of: navigationService.shouldNavigateToTimer) { shouldNavigate in
               if shouldNavigate {
                   showPomodoroView = true
                   navigationService.clearNavigation()
               }
           }
           .fullScreenCover(isPresented: $showPomodoroView) {
               PomodoroTimerView(preloadedEvent: navigationService.pendingTimerEvent)
                   .environment(\.managedObjectContext, CoreDataService.shared.context)
                   .environmentObject(authService)
                   .onDisappear {
                       showPomodoroView = false
                       navigationService.clearNavigation()
                   }
           }

       }
    
    private var timerStatusBar: some View {
        HStack {
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: timerService.isRunning)
                    
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(timerService.currentEvent?.title ?? "Study Session")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let subject = timerService.currentEvent?.subject {
                        Text("Subject: \(subject)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    } else if let deckName = timerService.currentEvent?.deckName {
                        Text("Deck: \(deckName)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timerService.formattedTime)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    ProgressView(value: timerService.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 60)

                }
                
                HStack(spacing: 8) {
                    if timerService.isRunning {
                        Button(action: {
                            timerService.pauseSession()
                        }) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.orange))
                        }
                    } else {
                        Button(action: {
                            timerService.resumeSession()
                        }) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.green))
                        }
                    }
                    
                    Button(action: {
                        timerService.stopSession()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.red))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
            .onTapGesture {
                showPomodoroView = true 
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showCreatePage: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "house.fill", isSelected: selectedTab == 0) { selectedTab = 0 }
                .accessibilityLabel("Home")
                .accessibilityHint("Navigate to home dashboard")
                .accessibilityAddTraits(selectedTab == 0 ? [.isSelected] : [])
            
            Spacer()
            
            TabBarButton(icon: "folder.fill", isSelected: selectedTab == 1) { selectedTab = 1 }
                .accessibilityLabel("Explorer")
                .accessibilityHint("Browse notes and flashcard decks")
                .accessibilityAddTraits(selectedTab == 1 ? [.isSelected] : [])
            
            Spacer()
            
            FloatingPlusButton { showCreatePage = true }
                .accessibilityLabel("Create new content")
                .accessibilityHint("Add new note or flashcard")
                .accessibilityAddTraits([.isButton])
            
            Spacer()
            
            TabBarButton(icon: "calendar", isSelected: selectedTab == 2) { selectedTab = 2 }
                .accessibilityLabel("Calendar")
                .accessibilityHint("View and schedule study sessions")
                .accessibilityAddTraits(selectedTab == 2 ? [.isSelected] : [])
            
            Spacer()
            
            TabBarButton(icon: "chart.bar.fill", isSelected: selectedTab == 4) { selectedTab = 4 }
                .accessibilityLabel("Statistics")
                .accessibilityHint("View learning progress and analytics")
                .accessibilityAddTraits(selectedTab == 4 ? [.isSelected] : [])
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.regularMaterial)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Navigation bar")
    }
}


struct TabBarButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray.opacity(0.8))
                    .frame(width: 24, height: 24)
                
                Circle()
                    .fill(isSelected ? .white : .clear)
                    .frame(width: 3, height: 3)
            }
            .frame(width: 50, height: 44)
            .background(
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 36, height: 36)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FloatingPlusButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.9)]),
                            startPoint: .topLeading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
        .environmentObject(StatsService())
}

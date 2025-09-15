//
//  MainTabView.swift
//  Noetica
//
//  Created by abdul4 on 2025-09-11.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showCreatePage = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeDashboardView()
                    .tabItem { EmptyView() }
                    .tag(0)
                
                NotesExplorerView()
                    .tabItem { EmptyView() }
                    .tag(1)
                
                Color.clear
                    .tabItem { EmptyView() }
                    .tag(2)
                
                CalendarView()
                    .tabItem { EmptyView() }
                    .tag(3)
                
                StatsView()
                    .tabItem { EmptyView() }
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            CustomTabBar(selectedTab: $selectedTab, showCreatePage: $showCreatePage)
        }
        .sheet(isPresented: $showCreatePage) {
            CreatePageView()
        }
        .navigationBarHidden(true) 
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showCreatePage: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "house.fill",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            Spacer()
            
            TabBarButton(
                icon: "folder.fill",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            Spacer()
            
            FloatingPlusButton {
                showCreatePage = true
            }
            
            Spacer()
            
            TabBarButton(
                icon: "calendar",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
            
            Spacer()
            
            TabBarButton(
                icon: "chart.bar.fill",
                isSelected: selectedTab == 4,
                action: { selectedTab = 4 }
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
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
                            endPoint: .bottomTrailing
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
}

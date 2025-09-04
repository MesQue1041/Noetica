//
//  HomeDashboard.swift
//  Noetica
//
//  Created by Abdul 017 on 2025-09-04.
//

import SwiftUI

struct HomeDashboardView: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Welcome, Abdul!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color("AccentBlue"))
                .padding(.top, 30)
            
            Text("Your Study Overview")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.bottom, 18)
            
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("HeatmapBG"))
                .frame(height: 170)
                .overlay(
                    Text("Heatmap Calendar")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                )
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                DashboardActionButton(icon: "doc.text", label: "Add Note", color: Color("AccentBlue"))
                DashboardActionButton(icon: "timer", label: "Pomodoro", color: Color("AccentPurple"))
                DashboardActionButton(icon: "rectangle.stack", label: "Flashcards", color: Color("AccentGreen"))
                DashboardActionButton(icon: "arkit", label: "AR Cards", color: Color("AccentPink"))
            }
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color("AccentPurple"), Color("AccentBlue")]), startPoint: .leading, endPoint: .trailing))
                    .frame(height: 95)
                HStack {
                    Image(systemName: "sparkles").font(.system(size: 40)).foregroundColor(.white)
                    VStack(alignment: .leading) {
                        Text("Keep up the streak!").font(.title3).bold().foregroundColor(.white)
                        Text("You've studied 5 days in a row.").font(.subheadline).foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                }.padding()
            }
            .padding(.horizontal)
            .padding(.bottom, 18)
            
            Spacer()
        }
        .background(Color("ScreenBG").ignoresSafeArea())
    }
}

struct DashboardActionButton: View {
    var icon: String
    var label: String
    var color: Color

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .bold))
            }
            Text(label)
                .font(.caption).bold()
                .foregroundColor(color)
                .padding(.top, 4)
        }
    }
}

struct HomeDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        HomeDashboardView()
            .preferredColorScheme(.light)
    }
}


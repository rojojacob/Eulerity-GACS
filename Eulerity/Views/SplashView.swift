//
//  SplashView.swift
//  Eulerity
//

import SwiftUI

/// The app's splash screen: the app logo centered on the launch background, shown
/// briefly with a subtle fade/scale-in, then it hands off to ``FormScreen``. The
/// background matches the native launch screen (`LaunchBackground`) so the launch
/// → splash transition is seamless.
struct SplashView: View {
    @State private var showForm = false
    @State private var logoScale = 0.85
    @State private var logoOpacity = 0.0

    var body: some View {
        if showForm {
            FormScreen()
                .transition(.opacity)
        } else {
            ZStack {
                Color("LaunchBackground").ignoresSafeArea()
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
            }
            .task {
                withAnimation(.easeOut(duration: 0.5)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation(.easeInOut(duration: 0.35)) { showForm = true }
            }
        }
    }
}

#Preview {
    SplashView()
}

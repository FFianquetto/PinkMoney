import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var auth: AuthService
    @State private var phase: Phase = .splash
    @State private var appeared = false
    @State private var floating = false

    private enum Phase {
        case splash
        case ready
    }

    var body: some View {
        ZStack {
            switch phase {
            case .splash:
                splash
                    .transition(.opacity)
            case .ready:
                if auth.isSessionActive {
                    MainTabView()
                        .transition(.opacity)
                } else {
                    AuthView()
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: phase)
        .animation(.easeInOut(duration: 0.4), value: auth.isSessionActive)
        .task {
            async let restoration: Void = auth.restoreSession()
            try? await Task.sleep(for: .milliseconds(1600))
            _ = await restoration
            // Flujo: ¿Sesión local activa? Con el backend pendiente se abre una sesión local
            // para que el usuario navegue libremente por toda la app.
            if !auth.isSessionActive && !PinkTheme.requiresLogin {
                auth.startLocalSession()
            }
            phase = .ready
        }
    }

    private var splash: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x3A1424), Color(hex: 0x0B0608)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [PinkPalette.rose.opacity(0.38), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 220
                    )
                )
                .frame(width: 440, height: 440)
                .offset(y: -70)
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)

            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(PinkPalette.rose.opacity(0.18 - Double(index) * 0.04), lineWidth: 1.5)
                    .frame(width: 250 + CGFloat(index) * 90, height: 250 + CGFloat(index) * 90)
                    .offset(y: -70)
                    .scaleEffect(appeared ? 1 : 0.8)
                    .opacity(appeared ? 1 : 0)
            }

            VStack(spacing: 0) {
                Spacer()
                CerdoMascot(size: 200)
                    .offset(y: floating ? -6 : 6)
                    .scaleEffect(appeared ? 1 : 0.8)
                    .padding(.bottom, 20)

                Text("PINK MONEY")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(PinkPalette.rose)
                    .padding(.bottom, 8)

                Text("Control total.")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0xFAF8F5))

                Text("Tu presupuesto, sin que se evapore.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(PinkPalette.sage)
                    .padding(.top, 6)

                Spacer()

                VStack(spacing: 14) {
                    ProgressView()
                        .tint(PinkPalette.rose)
                    Text("HECHO PARA ESTUDIANTES EN NUEVO LEÓN")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(PinkPalette.sageDeep)
                }
                .padding(.bottom, 36)
            }
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.78)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                floating = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pink Money. Cargando.")
    }
}

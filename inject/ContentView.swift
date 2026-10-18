import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var remoteBase = "https://"
    @State private var status = "Cole a URL base do site (HTTPS) e toque em INJETAR"
    @State private var busy = false
    @State private var logLines: [String] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("OGIOS INJECT")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(exploitLabel)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(exploitColor)

                TextField("https://seu-site.com/pasta", text: $remoteBase)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .padding(12)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                    .padding(.horizontal)

                Button(action: runInject) {
                    Text(busy ? "INJETANDO…" : "INJETAR DO SITE")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(busy)
                .padding(.horizontal)

                Button(action: runExploitOnly) {
                    Text("SÓ EXPLOIT")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(busy)
                .padding(.horizontal)

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(status)
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.85))
                        ForEach(Array(logLines.enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Text("Site deve servir:\n/Assembly-CSharp-patch.bytes\n/localconfig.json")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 24)
        }
        .onAppear {
            appState.detectSupport()
        }
    }

    private var exploitLabel: String {
        if appState.kernelExploitRunning { return "EXPLOIT: RODANDO… (até 5 tentativas)" }
        switch appState.exploitStatus {
        case .success: return "EXPLOIT: ATIVO"
        case .failed(let m, let c): return "EXPLOIT: FALHOU — \(m) (\(c)) — toque SÓ EXPLOIT de novo"
        case .unsupported(let m): return "EXPLOIT: iOS NÃO SUPORTADO — \(m)"
        case .notStarted: return "EXPLOIT: AGUARDANDO"
        }
    }

    private var exploitColor: Color {
        if appState.kernelExploitRunning { return .yellow }
        switch appState.exploitStatus {
        case .success: return .green
        case .failed, .unsupported: return .red
        case .notStarted: return .gray
        }
    }

    private func runExploitOnly() {
        busy = true
        status = "Rodando exploit (até 5x)…"
        appState.runKernelExploitIfNeeded(force: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.pollExploit()
        }
    }

    private func pollExploit() {
        if appState.kernelExploitRunning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: pollExploit)
            return
        }
        if appState.exploitStatus.isSuccess {
            status = "EXPLOIT OK"
        } else {
            status = appState.lastExploitDetail.isEmpty ? "EXPLOIT FALHOU — reinicie o iPhone e tente de novo" : appState.lastExploitDetail
        }
        busy = false
    }

    private func runInject() {
        busy = true
        status = "Baixando do site…"
        logLines = []
        let base = remoteBase
        Task {
            do {
                let (bytes, config) = try await FFInjectService.download(from: base)
                await MainActor.run { status = "Download OK — injetando…" }
                let result = await Task.detached(priority: .userInitiated) {
                    FFInjectService.inject(bytes: bytes, config: config)
                }.value
                await MainActor.run {
                    logLines = result.messages
                    status = result.successCount > 0
                        ? "PRONTO — \(result.successCount) escrita(s), \(result.failCount) falha(s)"
                        : "FALHOU — veja o log"
                    busy = false
                }
            } catch {
                await MainActor.run {
                    status = error.localizedDescription
                    busy = false
                }
            }
        }
    }
}

struct AnimatedHyperBackdrop: View {
    @State private var animate = false
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppTheme.pageBackground
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .offset(x: animate ? 120 : -120, y: -proxy.size.height * 0.23)
                Circle()
                    .fill(AppTheme.secondaryAccent.opacity(0.08))
                    .frame(width: 260, height: 260)
                    .blur(radius: 80)
                    .offset(x: animate ? -100 : 100, y: proxy.size.height * 0.22)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) { animate = true }
            }
        }
    }
}

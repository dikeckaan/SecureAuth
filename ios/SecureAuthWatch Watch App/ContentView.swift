import SwiftUI

// MARK: – Root view

struct ContentView: View {
    @ObservedObject private var manager = WatchConnectivityManager.shared

    var body: some View {
        if manager.isAuthenticated && !manager.accounts.isEmpty {
            AccountListView(accounts: manager.accounts)
        } else {
            LockedView(isAuthenticated: manager.isAuthenticated)
        }
    }
}

// MARK: – Locked / empty state

struct LockedView: View {
    let isAuthenticated: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: isAuthenticated ? "tray" : "iphone.and.arrow.forward")
                .font(.largeTitle)
                .foregroundStyle(.blue)

            Text(isAuthenticated
                 ? "No accounts added yet"
                 : "Open SecureAuth\non your iPhone")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: – Account list

struct AccountListView: View {
    let accounts: [WatchAccount]

    var body: some View {
        List(accounts) { account in
            NavigationLink {
                AccountDetailView(account: account)
            } label: {
                AccountRowView(account: account)
            }
        }
        .navigationTitle("SecureAuth")
    }
}

// MARK: – List row

struct AccountRowView: View {
    let account: WatchAccount

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(account.issuer)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(account.code)
                .font(.system(.body, design: .monospaced).weight(.bold))
                .lineLimit(1)
        }
    }
}

// MARK: – Detail view (full-screen code + countdown)

struct AccountDetailView: View {
    let account: WatchAccount

    @State private var remaining: Int
    @State private var progress: Double

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(account: WatchAccount) {
        self.account = account
        _remaining = State(initialValue: account.remainingSeconds)
        _progress  = State(initialValue: account.progress)
    }

    private var timerColor: Color {
        remaining <= 5 ? .red : remaining <= 10 ? .orange : .blue
    }

    var body: some View {
        VStack(spacing: 8) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 40, height: 40)
                Text(account.initials)
                    .font(.headline)
                    .foregroundStyle(.white)
            }

            // Issuer + account name
            VStack(spacing: 1) {
                Text(account.issuer)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                Text(account.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // OTP code
            Text(account.code)
                .font(.system(.title2, design: .monospaced).weight(.bold))
                .tracking(account.isSteam ? 3 : 4)
                .minimumScaleFactor(0.6)

            // Countdown ring (TOTP / Steam only)
            if !account.isHotp {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            timerColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                    Text("\(remaining)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(timerColor)
                }
                .frame(width: 40, height: 40)
                .onReceive(ticker) { _ in
                    if remaining > 0 {
                        remaining -= 1
                        progress = Double(remaining) / Double(account.period)
                    }
                }
            }
        }
        .navigationTitle("Code")
        .navigationBarTitleDisplayMode(.inline)
    }
}

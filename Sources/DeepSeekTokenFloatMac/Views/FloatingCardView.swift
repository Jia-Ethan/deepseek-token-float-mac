import SwiftUI

struct FloatingCardView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            spanPicker
            usageBody
            Spacer(minLength: 0)
            balanceFooter
        }
        .padding(18)
        .frame(minWidth: 320, minHeight: 340)
        .background(cardBackground)
        .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onTapGesture {
            appState.fetchBalance()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("DeepSeek")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Token Monitor")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                SettingsWindowController.shared.show(appState: appState)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Open Settings")
        }
    }

    private var spanPicker: some View {
        Picker("Time Span", selection: $appState.selectedSpan) {
            ForEach(TimeSpan.allCases) { span in
                Text(span.label)
                    .tag(span)
                    .accessibilityLabel(span.accessibilityLabel)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .controlSize(.small)
    }

    @ViewBuilder
    private var usageBody: some View {
        if appState.usageSummary.recordCount == 0 {
            EmptyUsageView(span: appState.selectedSpan)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text(DisplayFormatters.tokens(appState.usageSummary.totalTokens))
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("total tokens")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    MetricRow(
                        title: "Input",
                        value: DisplayFormatters.tokens(appState.usageSummary.inputTokens)
                    )
                    MetricRow(
                        title: "Output",
                        value: DisplayFormatters.tokens(appState.usageSummary.outputTokens)
                    )
                    MetricRow(
                        title: "Estimated cost",
                        value: DisplayFormatters.cost(appState.usageSummary.estimatedCost)
                    )
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.52))
                )
            }
        }
    }

    private var balanceFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                appState.fetchBalance()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "creditcard")
                    Text(balanceTitle)
                    Spacer()
                    if case .loading = appState.balanceStatus {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(red: 0.0, green: 0.39, blue: 0.8))

            balanceDetails
        }
    }

    @ViewBuilder
    private var balanceDetails: some View {
        switch appState.balanceStatus {
        case .idle:
            Text("Click to refresh official balance.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        case .loading:
            Text("Refreshing official balance...")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        case .failed(let message):
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        case .loaded(let snapshot):
            BalanceDetailsView(snapshot: snapshot)
        }
    }

    private var balanceTitle: String {
        switch appState.balanceStatus {
        case .loaded(let snapshot):
            guard let first = snapshot.response.balanceInfos.first else {
                return "Balance unavailable"
            }
            return "\(first.currency) \(first.totalBalance)"
        case .loading:
            return "Checking balance"
        case .failed:
            return "Balance error"
        case .idle:
            return appState.apiKeySaved ? "Check balance" : "Add API Key"
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.72),
                                Color(red: 0.95, green: 0.95, blue: 0.97).opacity(0.55)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 28, x: 0, y: 18)
    }
}

private struct MetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .font(.system(size: 12, weight: .medium))
    }
}

private struct EmptyUsageView: View {
    let span: TimeSpan

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No local usage data")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.primary)

            Text("Token usage for \(span.accessibilityLabel.lowercased()) is empty because DeepSeek does not expose an official historical usage API in the public docs. Import local usage CSV records in Settings to populate this card.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 12)
    }
}

private struct BalanceDetailsView: View {
    let snapshot: BalanceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(snapshot.response.balanceInfos) { info in
                HStack {
                    Text("\(info.currency) total")
                    Spacer()
                    Text(info.totalBalance)
                        .monospacedDigit()
                }
            }

            if let first = snapshot.response.balanceInfos.first {
                HStack {
                    Text("Granted")
                    Spacer()
                    Text(first.grantedBalance)
                        .monospacedDigit()
                }
                HStack {
                    Text("Topped up")
                    Spacer()
                    Text(first.toppedUpBalance)
                        .monospacedDigit()
                }
            }

            HStack {
                Text(snapshot.response.isAvailable ? "Account available" : "Account unavailable")
                Spacer()
                Text(DisplayFormatters.timestamp(snapshot.updatedAt))
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.secondary)
    }
}

import SwiftUI

/// Preview of dictation profiles that shape tone and formatting per context.
/// UI-only in this release — the cards show sample profiles and aren't yet
/// applied to transcription.
struct AIProfilesView: View {
    private let profiles = AIProfile.samples

    private let columns = [GridItem(.adaptive(minimum: 240), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(profiles) { profile in
                        ProfileCard(profile: profile)
                    }
                    NewProfileCard()
                }
            }
            .padding(28)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("AI Profiles")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text("AI Profiles")
                    .font(.largeTitle.weight(.bold))
                PreviewBadge()
            }
            Text("Tailor tone, formatting, and vocabulary for different apps and contexts.")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ProfileCard: View {
    let profile: AIProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: profile.icon)
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                Spacer()
                if profile.isDefault {
                    Text("Default")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                Text(profile.summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Label(profile.tone, systemImage: "waveform")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 172, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.separator.opacity(0.4), lineWidth: 1)
        }
    }
}

private struct NewProfileCard: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("New Profile")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Coming soon")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 172)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.quinary)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                .foregroundStyle(.separator)
        }
    }
}

/// Small pill marking a screen as a non-functional design preview.
struct PreviewBadge: View {
    var body: some View {
        Text("Preview")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(.tint.opacity(0.14), in: Capsule())
    }
}

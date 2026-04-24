import SwiftUI
import SwiftData

struct EditGoalsView: View {
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    private var profile: UserProfile? { profiles.first }

    // Body stats
    @State private var height: Double = 175
    @State private var weight: Double = 75
    @State private var targetWeight: Double = 75

    // Fitness goal
    @State private var fitnessGoal: String = "general_health"

    // Training details
    @State private var experienceLevel: String = "intermediate"
    @State private var trainingDaysPerWeek: Double = 4
    @State private var sport: String = ""

    // Upcoming event
    @State private var hasUpcomingEvent: Bool = false
    @State private var upcomingEventDate: Date = Date().addingTimeInterval(60 * 60 * 24 * 30)

    // Design tokens
    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let labelGray  = Color.white.opacity(0.38)

    private let goals: [(key: String, icon: String, label: String)] = [
        ("fat_loss",       "flame.fill",    "Fat Loss"),
        ("muscle_gain",    "dumbbell.fill", "Muscle Gain"),
        ("performance",    "bolt.fill",     "Performance"),
        ("general_health", "heart.fill",    "General Health"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // MARK: Body stats
                cardSection(label: "BODY STATS") {
                    statSlider(label: "Height", value: $height, range: 140...220, format: { "\(Int($0)) cm" })
                    Divider().background(Color.white.opacity(0.06))
                    statSlider(label: "Current Weight", value: $weight, range: 40...200, format: { String(format: "%.1f kg", $0) })
                    Divider().background(Color.white.opacity(0.06))
                    statSlider(label: "Target Weight", value: $targetWeight, range: 40...200, format: { String(format: "%.1f kg", $0) })
                }

                // MARK: Goal picker
                cardSection(label: "PRIMARY GOAL") {
                    VStack(spacing: 0) {
                        ForEach(Array(goals.enumerated()), id: \.element.key) { idx, goal in
                            if idx > 0 { Divider().background(Color.white.opacity(0.06)) }
                            Button(action: { withAnimation(.easeInOut(duration: 0.15)) { fitnessGoal = goal.key } }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill((fitnessGoal == goal.key ? accentBlue : Color.white).opacity(0.1))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: goal.icon)
                                            .font(.system(size: 14))
                                            .foregroundColor(fitnessGoal == goal.key ? accentBlue : .white.opacity(0.5))
                                    }
                                    Text(goal.label)
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    if fitnessGoal == goal.key {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(accentBlue)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // MARK: Training profile
                cardSection(label: "TRAINING PROFILE") {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("EXPERIENCE LEVEL")
                        Picker("Experience", selection: $experienceLevel) {
                            Text("Beginner").tag("beginner")
                            Text("Intermediate").tag("intermediate")
                            Text("Advanced").tag("advanced")
                        }
                        .pickerStyle(.segmented)
                        .tint(accentBlue)
                    }
                    Divider().background(Color.white.opacity(0.06))
                    statSlider(label: "Training Days / Week", value: $trainingDaysPerWeek, range: 1...7, format: { "\(Int($0)) days" })
                    Divider().background(Color.white.opacity(0.06))
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("SPORT / ACTIVITY")
                        TextField("e.g. Powerlifting, Running, CrossFit", text: $sport)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }

                // MARK: Upcoming event
                cardSection(label: "UPCOMING EVENT") {
                    HStack {
                        Text("Competition or event")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $hasUpcomingEvent)
                            .labelsHidden()
                            .tint(accentBlue)
                    }
                    if hasUpcomingEvent {
                        Divider().background(Color.white.opacity(0.06))
                        DatePicker("Event Date", selection: $upcomingEventDate, in: Date()..., displayedComponents: .date)
                            .foregroundColor(.white)
                            .tint(accentBlue)
                    }
                }

                // MARK: Save
                Button(action: saveAndClose) {
                    Text("Save Changes")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(bgPrimary.ignoresSafeArea())
        .navigationTitle("Edit Goals")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { prefill() }
        .animation(.easeInOut(duration: 0.2), value: hasUpcomingEvent)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .kerning(1.2)
            .foregroundColor(labelGray)
    }

    @ViewBuilder
    private func cardSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .kerning(1.5)
                .foregroundColor(labelGray)
                .padding(.leading, 4)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(14)
            .background(bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
        }
    }

    private func statSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, format: (Double) -> String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(accentBlue)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: 0.5)
                .tint(accentBlue)
        }
    }

    // MARK: - Persistence

    private func prefill() {
        guard let p = profile else { return }
        height              = p.height > 0 ? p.height : 175
        weight              = p.weight > 0 ? p.weight : 75
        targetWeight        = p.targetWeight > 0 ? p.targetWeight : p.weight
        fitnessGoal         = p.fitnessGoal.isEmpty ? "general_health" : p.fitnessGoal
        experienceLevel     = p.experienceLevel.isEmpty ? "intermediate" : p.experienceLevel
        trainingDaysPerWeek = Double(p.trainingDaysPerWeek > 0 ? p.trainingDaysPerWeek : 4)
        sport               = p.sport
        hasUpcomingEvent    = p.hasUpcomingEvent
        if let d = p.upcomingEventDate { upcomingEventDate = d }
    }

    private func saveAndClose() {
        guard let p = profile else { dismiss(); return }
        p.height              = height
        p.weight              = weight
        p.targetWeight        = targetWeight
        p.fitnessGoal         = fitnessGoal
        p.experienceLevel     = experienceLevel
        p.trainingDaysPerWeek = Int(trainingDaysPerWeek)
        p.sport               = sport
        p.hasUpcomingEvent    = hasUpcomingEvent
        p.upcomingEventDate   = hasUpcomingEvent ? upcomingEventDate : nil
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack { EditGoalsView() }
        .modelContainer(for: UserProfile.self, inMemory: true)
}

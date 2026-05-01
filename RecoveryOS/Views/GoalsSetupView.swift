import SwiftUI
import SwiftData

struct GoalsSetupView: View {
    var onFinished: () -> Void

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
    private let bgPrimary    = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard       = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue   = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal   = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let accentPurple = Color(red: 0.55, green: 0.35, blue: 0.98)
    private let labelGray    = Color.white.opacity(0.4)

    private let goals: [(key: String, icon: String, label: String, sub: String)] = [
        ("fat_loss",       "flame.fill",          "Fat Loss",          "Burn fat, improve body composition"),
        ("muscle_gain",    "dumbbell.fill",        "Muscle Gain",       "Build strength and muscle mass"),
        ("performance",    "bolt.fill",            "Performance",       "Maximise athletic output"),
        ("general_health", "heart.fill",           "General Health",    "Stay fit and feel great"),
    ]

    var body: some View {
        ZStack {
            bgPrimary.ignoresSafeArea()

            HStack(spacing: 0) {
                Rectangle()
                    .fill(LinearGradient(colors: [accentTeal.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(width: 2)
                    .ignoresSafeArea()
                Spacer()
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Top bar
                    HStack {
                        Text("READINESS")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(accentBlue)
                        Spacer()
                        Text("STEP 03/03")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Set Your")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("Goals.")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(LinearGradient(colors: [accentTeal, accentBlue], startPoint: .leading, endPoint: .trailing))
                        Text("This powers your personalised AI coaching. You can update everything later in Settings.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.45))
                            .lineSpacing(3)
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // MARK: Body stats
                    VStack(alignment: .leading, spacing: 16) {
                        sectionLabel("BODY STATS")

                        VStack(spacing: 14) {
                            statSlider(label: "Height", value: $height, range: 140...220, format: { "\(Int($0)) cm" })
                            Divider().background(Color.white.opacity(0.06))
                            statSlider(label: "Current Weight", value: $weight, range: 40...200, format: { String(format: "%.1f kg", $0) })
                            Divider().background(Color.white.opacity(0.06))
                            statSlider(label: "Target Weight", value: $targetWeight, range: 40...200, format: { String(format: "%.1f kg", $0) })
                        }
                        .padding(16)
                        .background(bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                    // MARK: Primary goal
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("PRIMARY GOAL")

                        VStack(spacing: 10) {
                            ForEach(goals, id: \.key) { goal in
                                goalCard(goal: goal)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // MARK: Experience & training frequency
                    VStack(alignment: .leading, spacing: 16) {
                        sectionLabel("TRAINING PROFILE")

                        VStack(spacing: 0) {
                            // Experience level
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Experience Level")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                Picker("Experience", selection: $experienceLevel) {
                                    Text("Beginner").tag("beginner")
                                    Text("Intermediate").tag("intermediate")
                                    Text("Advanced").tag("advanced")
                                }
                                .pickerStyle(.segmented)
                                .tint(accentBlue)
                            }
                            .padding(14)

                            Divider().background(Color.white.opacity(0.06))

                            // Training days
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Training Days / Week")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(Int(trainingDaysPerWeek)) days")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(accentTeal)
                                        .monospacedDigit()
                                }
                                Slider(value: $trainingDaysPerWeek, in: 1...7, step: 1)
                                    .tint(accentTeal)
                            }
                            .padding(14)

                            Divider().background(Color.white.opacity(0.06))

                            // Sport / activity
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sport / Activity")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                TextField("e.g. Powerlifting, Running, CrossFit", text: $sport)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
                            }
                            .padding(14)
                        }
                        .background(bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // MARK: Upcoming event
                    VStack(alignment: .leading, spacing: 12) {
                        sectionLabel("UPCOMING EVENT")

                        VStack(spacing: 0) {
                            HStack {
                                Text("I have a competition or event")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                                Toggle("", isOn: $hasUpcomingEvent)
                                    .labelsHidden()
                                    .tint(accentBlue)
                            }
                            .padding(14)

                            if hasUpcomingEvent {
                                Divider().background(Color.white.opacity(0.06))
                                DatePicker("Event Date", selection: $upcomingEventDate, in: Date()..., displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .foregroundColor(.white)
                                    .tint(accentBlue)
                                    .padding(14)
                            }
                        }
                        .background(bgCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1))
                        .animation(.easeInOut(duration: 0.2), value: hasUpcomingEvent)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // MARK: Continue button
                    Button(action: saveAndContinue) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(LinearGradient(colors: [accentBlue, accentTeal], startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: accentBlue.opacity(0.4), radius: 14, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { prefillFromProfile() }
    }

    // MARK: - Subviews

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .kerning(1.5)
            .foregroundColor(labelGray)
    }

    private func statSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, format: (Double) -> String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(format(value.wrappedValue))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(accentBlue)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: 0.5)
                .tint(accentBlue)
        }
    }

    private func goalCard(goal: (key: String, icon: String, label: String, sub: String)) -> some View {
        let selected = fitnessGoal == goal.key
        return Button(action: { withAnimation(.easeInOut(duration: 0.15)) { fitnessGoal = goal.key } }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(selected ? accentBlue.opacity(0.25) : Color.white.opacity(0.06))
                        .frame(width: 42, height: 42)
                    Image(systemName: goal.icon)
                        .font(.system(size: 18))
                        .foregroundColor(selected ? accentBlue : .white.opacity(0.4))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.label)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(selected ? .white : .white.opacity(0.7))
                    Text(goal.sub)
                        .font(.system(size: 12))
                        .foregroundColor(selected ? .white.opacity(0.6) : .white.opacity(0.3))
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(accentBlue)
                }
            }
            .padding(14)
            .background(selected ? accentBlue.opacity(0.08) : bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? accentBlue.opacity(0.5) : Color.white.opacity(0.06), lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Persist & continue

    private func prefillFromProfile() {
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

    private func saveAndContinue() {
        guard let p = profile else { onFinished(); return }
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
        onFinished()
    }
}

#Preview {
    GoalsSetupView(onFinished: {})
        .modelContainer(for: UserProfile.self, inMemory: true)
}

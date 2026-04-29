import Foundation
import Combine
import FoundationModels

// Generates personalised recovery advice using Apple's on-device Foundation Models framework.
// Because the model runs entirely on device, there are no API costs and no data leaves the phone.
// When Apple Intelligence is not available (older devices or unsupported regions) the service
// falls back to a rule-based response so the advice card is never empty.
@MainActor
class AICoachService: ObservableObject {
    static let shared = AICoachService()

    @Published var advice:       String = ""
    @Published var isGenerating: Bool   = false
    @Published var usedAI:       Bool   = false

    // Caches the last check-in ID so we do not regenerate advice every time
    // the view redraws. Advice only refreshes when a new check-in is submitted.
    private var lastCheckInID: UUID?

    // MARK: - Public entry point

    func generateIfNeeded(profile: UserProfile, checkIns: [DailyCheckIn]) async {
        guard let latest = checkIns.first else { return }
        // Skip if we already have advice for this check-in.
        guard latest.id != lastCheckInID else { return }
        await generate(profile: profile, checkIns: checkIns, latest: latest)
    }

    // MARK: - Generation

    private func generate(profile: UserProfile, checkIns: [DailyCheckIn], latest: DailyCheckIn) async {
        isGenerating = true

        // Check whether Apple Intelligence is available on this device before attempting
        // to use it. The availability check is an enum so we pattern-match it.
        let model = SystemLanguageModel.default
        if case .available = model.availability {
            await generateWithAI(profile: profile, checkIns: checkIns, latest: latest)
        } else {
            // Device does not support on-device AI, so produce rule-based advice instead.
            advice        = fallback(score: latest.readinessScore ?? 50, profile: profile)
            usedAI        = false
            lastCheckInID = latest.id
        }

        isGenerating = false
    }

    private func generateWithAI(profile: UserProfile, checkIns: [DailyCheckIn], latest: DailyCheckIn) async {
        let prompt = buildPrompt(profile: profile, checkIns: checkIns)

        // The instructions establish the persona for the entire session.
        // Keeping them concise reduces token usage and keeps responses focused.
        let instructions = """
            You are a professional recovery and performance coach. \
            Give concise, specific, actionable advice based only on the athlete data provided. \
            Never use filler phrases. Be direct and practical.
            """
        do {
            let session  = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            advice        = response.content
            usedAI        = true
            lastCheckInID = latest.id
        } catch {
            // If the model call fails for any reason (model loading, context length, etc.)
            // fall back gracefully rather than showing an error to the user.
            advice        = fallback(score: latest.readinessScore ?? 50, profile: profile)
            usedAI        = false
            lastCheckInID = latest.id
        }
    }

    // MARK: - Prompt builder

    // Constructs a structured prompt that gives the model enough context to produce
    // personalised advice without it making assumptions or generic recommendations.
    // The format uses plain text headings so the model can parse the structure without
    // needing a specific system to interpret it.
    private func buildPrompt(profile: UserProfile, checkIns: [DailyCheckIn]) -> String {
        let latest = checkIns[0]
        let last7  = Array(checkIns.prefix(7))

        // Convert the fitness goal key to a readable label for the prompt.
        let goalLabel: String
        switch profile.fitnessGoal {
        case "fat_loss":    goalLabel = "fat loss"
        case "muscle_gain": goalLabel = "muscle gain"
        case "performance": goalLabel = "athletic performance"
        default:            goalLabel = "general health"
        }

        // Express the weight goal as a direction rather than just two numbers
        // so the model understands the intent behind it.
        let weightDiff = profile.targetWeight - profile.weight
        let weightGoal: String
        if weightDiff > 1 {
            weightGoal = "wants to gain \(String(format: "%.0f", weightDiff)) kg"
        } else if weightDiff < -1 {
            weightGoal = "wants to lose \(String(format: "%.0f", abs(weightDiff))) kg"
        } else {
            weightGoal = "maintaining current weight"
        }

        // Summarise the 7-day score trend so the model can distinguish between
        // a one-off bad day and a sustained decline in recovery.
        let scores = last7.compactMap { $0.readinessScore }
        let avgScore = scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count
        let trendLabel: String
        if scores.count >= 3 {
            let delta = scores[0] - scores[min(scores.count - 1, 2)]
            trendLabel = delta > 8 ? "improving" : delta < -8 ? "declining" : "stable"
        } else {
            trendLabel = "early data"
        }

        // Only include the event line when relevant so the prompt stays concise.
        let eventLine = profile.hasUpcomingEvent
            ? "- Has an upcoming competition/event\(profile.upcomingEventDate.map { " on \(formatted($0))" } ?? "")"
            : ""

        return """
        ATHLETE PROFILE:
        - Age \(profile.age), \(profile.discipline) athlete, \(profile.experienceLevel) level
        - Sport: \(profile.sport.isEmpty ? "General Training" : profile.sport)
        - Goal: \(goalLabel) (\(weightGoal))
        - Trains \(profile.trainingDaysPerWeek) days/week, intensity: \(profile.intensity >= 0.5 ? "HIT" : "LIT")
        - Height \(String(format: "%.0f", profile.height)) cm, weight \(String(format: "%.1f", profile.weight)) kg, target \(String(format: "%.1f", profile.targetWeight)) kg
        \(eventLine)

        TODAY'S DATA:
        - Recovery score: \(latest.readinessScore ?? 0)/100 (7-day avg: \(avgScore), trend: \(trendLabel))
        - Sleep: \(latest.sleepHours.map { String(format: "%.1f h", $0) } ?? "not logged")
        - HRV: \(latest.hrvMs.map { "\(Int($0)) ms" } ?? "not logged")
        - Resting HR: \(latest.restingHR.map { "\(Int($0)) bpm" } ?? "not logged")
        - Soreness: \(latest.soreness)/10, Energy: \(latest.energy)/10, Stress: \(latest.stress)/10
        - Hydration: \(latest.hydration)/10, Mood: \(latest.mood)/10, Nutrition: \(latest.nutritionAdherence)/10

        Give exactly 3 bullet points, each under 25 words:
        - TODAY: specific training recommendation
        - TOMORROW: recovery or training prep focus
        - THIS WEEK: one nutrition or lifestyle adjustment
        """
    }

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    // MARK: - Rule-based fallback

    // Produces advice without the AI model by branching on score ranges and
    // adjusting the wording based on the user's discipline and goal.
    // This ensures the advice card always shows something useful even on
    // devices that do not support Apple Intelligence.
    private func fallback(score: Int, profile: UserProfile) -> String {
        let isStrength = profile.discipline == "strength"
        let isFatLoss  = profile.fitnessGoal == "fat_loss"
        let isMuscle   = profile.fitnessGoal == "muscle_gain"

        switch score {
        case 85...100:
            let training = isStrength ? "heavy compound lifts" : "high-intensity intervals"
            return "Today: Push hard - your CNS is fully recovered. Prioritise \(training) at peak effort.\nTomorrow: Maintain intensity; your recovery trajectory supports it.\nThis week: \(isFatLoss ? "Stay in a moderate calorie deficit and hit your protein target." : isMuscle ? "Increase your protein intake to support muscle repair." : "Keep sleep consistent to hold this recovery window.")"
        case 70..<85:
            return "Today: Solid session appropriate - moderate to high intensity.\nTomorrow: Include a mobility or lighter accessory day to sustain recovery.\nThis week: \(isFatLoss ? "Monitor hunger signals; avoid undereating on training days." : "Prioritise 7-9 hours of sleep to extend this recovery phase.")"
        case 55..<70:
            let activity = isStrength ? "technique work or accessories" : "tempo run or Zone 2 cardio"
            return "Today: Keep it moderate - \(activity) at reduced load.\nTomorrow: Light activity only or full rest; let your body rebuild.\nThis week: Reduce stress where possible and focus on hydration and whole foods."
        case 40..<55:
            return "Today: Active recovery only - walking, stretching or light mobility work.\nTomorrow: Rest or very light movement; avoid taxing your system further.\nThis week: Sleep 8-9 hours, eat nutrient-dense meals and cut back on caffeine."
        default:
            return "Today: Full rest is strongly recommended. Your recovery markers are low.\nTomorrow: Reassess after quality sleep before returning to training.\nThis week: Investigate your sleep quality, stress levels and nutrition - all three are likely contributing."
        }
    }
}

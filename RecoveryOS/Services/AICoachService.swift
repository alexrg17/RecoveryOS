import Foundation
import Combine
import FoundationModels

// Generates personalised recovery advice using Apple's on-device Foundation Models framework.
// Because the model runs entirely on device, there are no API costs and no health data
// ever leaves the phone. When Apple Intelligence is not available the service falls back
// to a rule-based response that still uses historical context so the advice card is
// never empty or generic.
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
        guard latest.id != lastCheckInID else { return }
        await generate(profile: profile, checkIns: checkIns, latest: latest)
    }

    // MARK: - Generation

    private func generate(profile: UserProfile, checkIns: [DailyCheckIn], latest: DailyCheckIn) async {
        isGenerating = true

        let model = SystemLanguageModel.default
        if case .available = model.availability {
            await generateWithAI(profile: profile, checkIns: checkIns, latest: latest)
        } else {
            advice        = fallback(score: latest.readinessScore ?? 50, profile: profile, checkIns: checkIns)
            usedAI        = false
            lastCheckInID = latest.id
        }

        isGenerating = false
    }

    private func generateWithAI(profile: UserProfile, checkIns: [DailyCheckIn], latest: DailyCheckIn) async {
        let prompt = buildPrompt(profile: profile, checkIns: checkIns)

        // The instructions define the coach persona for the whole session.
        // Referencing the sport directly and banning filler phrases keeps
        // every response feeling personal rather than templated.
        let sport = profile.sport.isEmpty ? profile.discipline : profile.sport
        let instructions = """
            You are a data-driven performance coach specialising in athlete recovery. \
            You speak directly to the athlete using "you". \
            Every point you make must reference the numbers provided — never give generic advice. \
            Be specific to \(sport). Be encouraging on strong recovery days and protective on low ones. \
            Never use filler phrases like "great job" or "remember to". Be concise and direct.
            """
        do {
            let session  = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            advice        = response.content
            usedAI        = true
            lastCheckInID = latest.id
        } catch {
            // If the model call fails fall back gracefully rather than showing
            // an error — the user still gets useful rule-based advice.
            advice        = fallback(score: latest.readinessScore ?? 50, profile: profile, checkIns: checkIns)
            usedAI        = false
            lastCheckInID = latest.id
        }
    }

    // MARK: - Prompt builder

    // Builds a structured prompt that gives the model three layers of context:
    // 1. Who the athlete is (profile + goals)
    // 2. How they have been performing historically (baselines + patterns)
    // 3. How today looks compared to their own normal (not population averages)
    // This lets the model produce advice that feels like it knows the person
    // rather than just reacting to today's numbers in isolation.
    private func buildPrompt(profile: UserProfile, checkIns: [DailyCheckIn]) -> String {
        let latest = checkIns[0]
        let last7  = Array(checkIns.prefix(7))

        // ── Goal labels ───────────────────────────────────────────────────────
        let goalLabel: String
        switch profile.fitnessGoal {
        case "fat_loss":    goalLabel = "fat loss"
        case "muscle_gain": goalLabel = "muscle gain"
        case "performance": goalLabel = "athletic performance"
        default:            goalLabel = "general health"
        }

        let weightDiff = profile.targetWeight - profile.weight
        let weightGoal: String
        if      weightDiff >  1 { weightGoal = "gaining \(String(format: "%.0f", weightDiff)) kg" }
        else if weightDiff < -1 { weightGoal = "losing \(String(format: "%.0f", abs(weightDiff))) kg" }
        else                    { weightGoal = "maintaining weight" }

        // ── Personal baselines (all-time) ─────────────────────────────────────
        // Comparing today against the athlete's own history is far more meaningful
        // than comparing against population averages, which the model might default to.
        let allScores   = checkIns.compactMap { $0.readinessScore }
        let allSleep    = checkIns.compactMap { $0.sleepHours }
        let allHRV      = checkIns.compactMap { $0.hrvMs }
        let allHR       = checkIns.compactMap { $0.restingHR }

        let avgScore    = allScores.isEmpty ? 0 : allScores.reduce(0, +) / allScores.count
        let bestScore   = allScores.max() ?? 0
        let avgSleep    = allSleep.isEmpty ? nil : allSleep.reduce(0, +) / Double(allSleep.count)
        let avgHRV      = allHRV.isEmpty   ? nil : allHRV.reduce(0, +)   / Double(allHRV.count)
        let avgHR       = allHR.isEmpty    ? nil : allHR.reduce(0, +)    / Double(allHR.count)

        // ── Today vs personal average ─────────────────────────────────────────
        let todayScore  = latest.readinessScore ?? 0
        let scoreDelta  = todayScore - avgScore
        let scoreVsAvg  = scoreDelta >= 0
            ? "+\(scoreDelta) above your average"
            : "\(scoreDelta) below your average"

        // Delta from yesterday gives the model directional momentum context.
        let yesterdayScore = checkIns.count > 1 ? checkIns[1].readinessScore : nil
        let momentumStr: String
        if let today = latest.readinessScore, let yesterday = yesterdayScore {
            let d = today - yesterday
            momentumStr = d >= 0 ? "up \(d) from yesterday" : "down \(abs(d)) from yesterday"
        } else {
            momentumStr = ""
        }

        // ── 7-day trend ───────────────────────────────────────────────────────
        let last7Scores = last7.compactMap { $0.readinessScore }
        let historyStr  = last7Scores.map { String($0) }.joined(separator: " → ")
        let trendLabel: String
        if last7Scores.count >= 3 {
            let delta = last7Scores[0] - last7Scores[min(last7Scores.count - 1, 2)]
            trendLabel = delta > 8 ? "improving" : delta < -8 ? "declining" : "stable"
        } else {
            trendLabel = "early data"
        }

        // ── Weekly pattern detection ──────────────────────────────────────────
        // Flagging persistent patterns (e.g. 5 of 7 days with low nutrition) gives
        // the model something concrete to address rather than just reacting to today.
        var patterns: [String] = []
        let lowNutrition = last7.filter { $0.nutritionAdherence < 6 }.count
        let lowHydration = last7.filter { $0.hydration < 6 }.count
        let highStress   = last7.filter { $0.stress > 7 }.count
        let highSoreness = last7.filter { $0.soreness > 7 }.count

        if lowNutrition >= 4 { patterns.append("nutrition below target \(lowNutrition)/7 days") }
        if lowHydration >= 4 { patterns.append("hydration below target \(lowHydration)/7 days") }
        if highStress   >= 3 { patterns.append("elevated stress \(highStress)/7 days") }
        if highSoreness >= 3 { patterns.append("high soreness \(highSoreness)/7 days") }

        let patternsStr = patterns.isEmpty ? "no persistent concerns" : patterns.joined(separator: "; ")

        // ── Check-in streak ───────────────────────────────────────────────────
        let streak = calculateStreak(checkIns: checkIns)

        // ── Competition phase ─────────────────────────────────────────────────
        // Telling the model which training phase the athlete is in lets it adjust
        // its intensity recommendations appropriately (e.g. taper vs base building).
        var competitionLine = ""
        if profile.hasUpcomingEvent, let eventDate = profile.upcomingEventDate {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: eventDate).day ?? 0
            if days > 0 {
                let phase = days <= 14 ? "TAPER PHASE — reduce volume, keep intensity"
                          : days <= 28 ? "COMPETITION BUILD — peak conditioning"
                          :              "BASE TRAINING"
                competitionLine = "Competition: \(days) days away (\(phase))"
            }
        }

        // ── Sleep comparison string ───────────────────────────────────────────
        let sleepStr: String
        if let s = latest.sleepHours {
            if let avg = avgSleep {
                let diff = s - avg
                let tag  = diff > 0.4 ? " (above your avg)" : diff < -0.4 ? " (below your avg)" : " (at your avg)"
                sleepStr = String(format: "%.1f h", s) + tag
            } else {
                sleepStr = String(format: "%.1f h", s)
            }
        } else {
            sleepStr = "not logged"
        }

        // ── HRV comparison string ─────────────────────────────────────────────
        let hrvStr: String
        if let h = latest.hrvMs {
            if let avg = avgHRV {
                let diff = h - avg
                let tag  = diff > 3 ? " (above your avg)" : diff < -3 ? " (below your avg)" : " (at your avg)"
                hrvStr = "\(Int(h)) ms" + tag
            } else {
                hrvStr = "\(Int(h)) ms"
            }
        } else {
            hrvStr = "not logged"
        }

        // ── Resting HR comparison string ──────────────────────────────────────
        // For resting HR, lower is better so the comparison direction is flipped.
        let hrStr: String
        if let h = latest.restingHR {
            if let avg = avgHR {
                let diff = h - avg
                let tag  = diff < -2 ? " (lower than avg — good)" : diff > 2 ? " (higher than avg)" : " (at your avg)"
                hrStr = "\(Int(h)) bpm" + tag
            } else {
                hrStr = "\(Int(h)) bpm"
            }
        } else {
            hrStr = "not logged"
        }

        return """
        ATHLETE: \(profile.name.isEmpty ? "Athlete" : profile.name), \
        \(profile.age)yo \(profile.discipline) (\(profile.sport.isEmpty ? "general training" : profile.sport)), \
        \(profile.experienceLevel) level
        Goal: \(goalLabel) — \(weightGoal)
        Trains \(profile.trainingDaysPerWeek)x/week, \(profile.intensity >= 0.5 ? "high" : "low") intensity
        \(competitionLine.isEmpty ? "" : competitionLine + "\n")
        PERSONAL BASELINES (\(checkIns.count) check-ins logged, \(streak)-day streak):
        - Avg readiness: \(avgScore)/100 | Best ever: \(bestScore)/100
        \(avgSleep.map { String(format: "- Avg sleep: %.1f h", $0) } ?? "")
        \(avgHRV.map  { "- Avg HRV: \(Int($0)) ms" } ?? "")

        TODAY vs YOUR NORMAL:
        - Readiness: \(todayScore)/100 — \(scoreVsAvg)\(momentumStr.isEmpty ? "" : ", \(momentumStr)") | Trend: \(trendLabel)
        - 7-day history: \(historyStr.isEmpty ? "not enough data" : historyStr)
        - Sleep: \(sleepStr)
        - HRV: \(hrvStr) | Resting HR: \(hrStr)
        - Soreness: \(latest.soreness)/10 | Energy: \(latest.energy)/10 | Stress: \(latest.stress)/10
        - Hydration: \(latest.hydration)/10 | Mood: \(latest.mood)/10 | Nutrition: \(latest.nutritionAdherence)/10
        - This week's patterns: \(patternsStr)

        Give 3 coaching points. Lead with the single most important action for today based \
        on the numbers above. Be specific to their sport and current phase. \
        No bullet symbols needed. Keep the whole response under 80 words.
        """
    }

    // MARK: - Streak calculation

    // Counts how many consecutive days ending today the athlete has submitted a check-in.
    // A streak of 7+ is worth mentioning in advice because it signals consistent engagement.
    private func calculateStreak(checkIns: [DailyCheckIn]) -> Int {
        let calendar = Calendar.current
        var streak   = 0
        var expected = calendar.startOfDay(for: Date())

        for checkIn in checkIns {
            let day = calendar.startOfDay(for: checkIn.date)
            if day == expected {
                streak  += 1
                expected = calendar.date(byAdding: .day, value: -1, to: expected)!
            } else if day < expected {
                break
            }
        }
        return streak
    }

    // MARK: - Date formatter

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    // MARK: - Rule-based fallback

    // Used when Apple Intelligence is unavailable. Now uses historical context
    // (streak, patterns, competition phase) so the fallback still feels personal
    // rather than producing the same generic text every time.
    private func fallback(score: Int, profile: UserProfile, checkIns: [DailyCheckIn]) -> String {
        let isStrength = profile.discipline == "strength"
        let isFatLoss  = profile.fitnessGoal == "fat_loss"
        let isMuscle   = profile.fitnessGoal == "muscle_gain"
        let sport      = profile.sport.isEmpty ? (isStrength ? "the gym" : "training") : profile.sport
        let streak     = calculateStreak(checkIns: checkIns)
        let last7      = Array(checkIns.prefix(7))

        // Detect the single most pressing pattern to personalise the weekly tip.
        let lowNutrition = last7.filter { $0.nutritionAdherence < 6 }.count >= 4
        let lowHydration = last7.filter { $0.hydration < 6 }.count >= 4
        let highStress   = last7.filter { $0.stress > 7 }.count >= 3

        let weeklyTip: String
        if lowNutrition {
            weeklyTip = isFatLoss
                ? "Nutrition has been below target most of this week — hit your protein goal even in a deficit."
                : "Nutrition has been inconsistent this week — prioritise whole foods and protein to support recovery."
        } else if lowHydration {
            weeklyTip = "Hydration has been low most of this week — aim for at least 2.5L daily, more on training days."
        } else if highStress {
            weeklyTip = "Stress has been elevated most of this week — add 10 minutes of breathing or walking to your evening routine."
        } else if isFatLoss {
            weeklyTip = "Stay in a moderate calorie deficit and hit your protein target to retain muscle while losing fat."
        } else if isMuscle {
            weeklyTip = "Increase protein intake to support muscle repair — aim for 1.8-2.2g per kg of bodyweight."
        } else {
            weeklyTip = "Keep sleep consistent — it is the single biggest lever for sustained recovery."
        }

        // Competition phase modifier for the today recommendation.
        var competitionNote = ""
        if profile.hasUpcomingEvent, let eventDate = profile.upcomingEventDate {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: eventDate).day ?? 0
            if days > 0 && days <= 14 {
                competitionNote = " With \(days) days to your event, prioritise recovery over volume."
            } else if days > 14 && days <= 28 {
                competitionNote = " \(days) days to your event — stay consistent and avoid unnecessary fatigue."
            }
        }

        let streakNote = streak >= 7 ? " \(streak)-day check-in streak — great consistency." : ""

        switch score {
        case 85...100:
            let training = isStrength ? "heavy compound work in \(sport)" : "high-intensity intervals"
            return "Today: Your CNS is fully recovered — push hard with \(training) at peak effort.\(competitionNote)\nTomorrow: Maintain intensity, your trajectory supports it.\(streakNote)\nThis week: \(weeklyTip)"

        case 70..<85:
            let training = isStrength ? "moderate-heavy \(sport) session" : "moderate-intensity \(sport) session"
            return "Today: Good recovery — a \(training) is appropriate.\(competitionNote)\nTomorrow: Include mobility or a lighter accessory day to sustain this.\(streakNote)\nThis week: \(weeklyTip)"

        case 55..<70:
            let activity = isStrength ? "technique work or light accessories in \(sport)" : "Zone 2 cardio or tempo work"
            return "Today: Keep it moderate — \(activity) at reduced load.\(competitionNote)\nTomorrow: Light movement or full rest to let your body rebuild.\(streakNote)\nThis week: \(weeklyTip)"

        case 40..<55:
            return "Today: Active recovery only — walking, stretching or mobility work.\(competitionNote)\nTomorrow: Rest or very light movement, avoid taxing your system further.\(streakNote)\nThis week: \(weeklyTip)"

        default:
            return "Today: Full rest is strongly recommended — your recovery markers are low.\(competitionNote)\nTomorrow: Reassess after quality sleep before returning to \(sport).\(streakNote)\nThis week: \(weeklyTip)"
        }
    }
}

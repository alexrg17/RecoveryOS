import SwiftUI
import SwiftData

struct EditProfileView: View {
    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let labelGray  = Color.white.opacity(0.38)

    @Environment(\.dismiss)      private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    @State private var displayName: String = ""
    @State private var discipline: String  = "strength"
    @State private var age: Double         = 25

    private let disciplines = [("strength", "Strength"), ("endurance", "Endurance")]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header("Edit Profile")

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DISPLAY NAME")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(1.2)
                            .foregroundColor(labelGray)
                        TextField("Display name", text: $displayName)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DISCIPLINE")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(1.2)
                            .foregroundColor(labelGray)
                        Picker("Discipline", selection: $discipline) {
                            ForEach(disciplines, id: \.0) { key, label in
                                Text(label).tag(key)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(accentBlue)
                    }
                }

                cardSection {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("AGE")
                                .font(.system(size: 11, weight: .semibold))
                                .kerning(1.2)
                                .foregroundColor(labelGray)
                            Spacer()
                            Text("\(Int(age))")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        Slider(value: $age, in: 14...70, step: 1)
                            .tint(accentBlue)
                    }
                }

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
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            displayName = profile?.name ?? ""
            discipline  = profile?.discipline ?? "strength"
            age         = Double(profile?.age ?? 25)
        }
    }

    private func saveAndClose() {
        if let profile {
            profile.name       = displayName.trimmingCharacters(in: .whitespaces)
            profile.discipline = discipline
            profile.age        = Int(age)
            try? modelContext.save()
        }
        dismiss()
    }

    @ViewBuilder
    private func header(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private func cardSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(14)
        .background(bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack { EditProfileView() }
}

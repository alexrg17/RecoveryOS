//
//  NotificationPickerView.swift
//  RecoveryOS
//

import SwiftUI

struct NotificationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var sentNotification: NotificationManager.DemoNotification?

    @State private var tapped: NotificationManager.DemoNotification? = nil

    private let bgPrimary  = Color(red: 0.04, green: 0.04, blue: 0.07)
    private let bgCard     = Color(red: 0.09, green: 0.09, blue: 0.13)
    private let accentBlue = Color(red: 0.28, green: 0.48, blue: 0.98)
    private let accentTeal = Color(red: 0.25, green: 0.90, blue: 0.69)
    private let labelGray  = Color.white.opacity(0.45)

    var body: some View {
        ZStack {
            bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {

                // Handle bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                // Title
                HStack {
                    Text("Send a Notification")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)

                Text("Select a notification type. It will arrive in 5 seconds — lock the screen first.")
                    .font(.system(size: 13))
                    .foregroundColor(labelGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 24)

                // Notification options
                VStack(spacing: 12) {
                    ForEach(NotificationManager.DemoNotification.allCases, id: \.self) { type in
                        notificationRow(type)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private func notificationRow(_ type: NotificationManager.DemoNotification) -> some View {
        let isSent = tapped == type

        return Button(action: {
            tapped = type
            sentNotification = type
            NotificationManager.shared.sendDemo(type)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss() }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(accentBlue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: type.icon)
                        .font(.system(size: 18))
                        .foregroundColor(accentBlue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(type.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(type.subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(labelGray)
                }

                Spacer()

                if isSent {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(accentTeal)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.2))
                }
            }
            .padding(14)
            .background(bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSent ? accentTeal.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isSent)
        }
        .disabled(tapped != nil)
    }
}

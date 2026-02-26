//
//  ContentView.swift
//  Demo
//
//  Created by yyjim on 19/02/2026.
//  Copyright © 2026 Cardinal Blue. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var controller: AssistiveTouchDemoController
    @State private var customEvent = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.22),
                    Color(red: 0.15, green: 0.26, blue: 0.43),
                    Color(red: 0.24, green: 0.45, blue: 0.62)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    statusCard
                    inputCard
                    controlCard
                    sampleCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
        }
        .onAppear {
            controller.configureIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CBAssistiveTouch Demo")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Manage the floating button, open console content, and test live event logs.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                statusItem(
                    title: "Assistive Touch",
                    value: controller.isAssistiveTouchVisible ? "Visible" : "Hidden"
                )
                statusItem(
                    title: "Logs",
                    value: "\(controller.logCount)"
                )
            }

            Text("Last event: \(controller.lastEvent)")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func statusItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Event")
                .font(.headline)
                .foregroundStyle(.white)

            TextField("Type an event message", text: $customEvent)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button("Add Event") {
                controller.addLog(customEvent)
                customEvent = ""
            }
            .buttonStyle(ProminentButtonStyle(tint: .white.opacity(0.95), textColor: .blue))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var controlCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Controls")
                .font(.headline)
                .foregroundStyle(.white)

            Button(controller.isAssistiveTouchVisible ? "Hide Assistive Touch" : "Show Assistive Touch") {
                controller.toggleAssistiveTouch()
            }
            .buttonStyle(ProminentButtonStyle(tint: .cyan, textColor: .white))

            Button("Toggle Console") {
                controller.toggleConsole()
            }
            .buttonStyle(ProminentButtonStyle(tint: .indigo, textColor: .white))

            HStack(spacing: 10) {
                Button("Show Console") {
                    controller.showConsole()
                }
                .buttonStyle(ProminentButtonStyle(tint: .teal, textColor: .white))

                Button("Hide Console") {
                    controller.hideConsole()
                }
                .buttonStyle(ProminentButtonStyle(tint: .pink, textColor: .white))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var sampleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundStyle(.white)

            Button("Log Sample Event") {
                controller.logSampleEvent()
            }
            .buttonStyle(ProminentButtonStyle(tint: .mint, textColor: .black))

            Button("Reset Demo Data") {
                controller.resetDemoState()
            }
            .buttonStyle(ProminentButtonStyle(tint: .orange, textColor: .black))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    ContentView()
        .environmentObject(AssistiveTouchDemoController())
}

private struct ProminentButtonStyle: ButtonStyle {
    let tint: Color
    let textColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(tint.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

//
//  OCRResultView.swift
//  VyroShort
//

import SwiftUI

struct OCRResultView: View {
    let result: OCRResult
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: VST.Spacing.md) {
            HStack {
                Image(systemName: "text.viewfinder").foregroundStyle(VST.Color.accent)
                Text("Extracted Text").font(VST.Font.headline)
                Spacer()
                Button(copied ? "Copied!" : "Copy All") {
                    ClipboardManager.copy(text: result.text)
                    copied = true
                }
                .buttonStyle(.borderedProminent)
            }

            ScrollView {
                Text(result.text.isEmpty ? "No text found." : result.text)
                    .font(VST.Font.mono)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(VST.Spacing.sm)
            }
            .frame(maxHeight: 240)
            .background(RoundedRectangle(cornerRadius: VST.Radius.md).fill(Color.primary.opacity(0.05)))

            if !result.urls.isEmpty { detected("Links", result.urls, "link") }
            if !result.emails.isEmpty { detected("Emails", result.emails, "envelope") }
            if !result.phoneNumbers.isEmpty { detected("Phone", result.phoneNumbers, "phone") }
        }
        .padding(VST.Spacing.lg)
        .frame(width: 420)
        .background(VST.Color.surface)
    }

    private func detected(_ title: String, _ values: [String], _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(VST.Font.caption).foregroundStyle(VST.Color.secondaryLabel)
            ForEach(values, id: \.self) { value in
                Button {
                    ClipboardManager.copy(text: value)
                } label: {
                    Label(value, systemImage: icon).font(VST.Font.body).lineLimit(1)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

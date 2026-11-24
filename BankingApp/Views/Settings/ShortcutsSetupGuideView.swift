import SwiftUI

public struct GuideStep: Equatable, Identifiable {
    public var id: String { step }
    public let step: String
    public let title: String
    public let subtitle: String

    public init(step: String, title: String, subtitle: String) {
        self.step = step
        self.title = title
        self.subtitle = subtitle
    }
}

public struct ShortcutsSetupGuideView: View {
    public static let steps: [GuideStep] = [
        GuideStep(
            step: "1",
            title: "Mở Cài Đặt iPhone",
            subtitle: "Vào Cài đặt > Trợ năng > Cảm ứng."
        ),
        GuideStep(
            step: "2",
            title: "Chọn Chạm vào mặt lưng",
            subtitle: "Cuộn xuống dưới cùng và chọn Chạm 2 lần (Double Tap)."
        ),
        GuideStep(
            step: "3",
            title: "Gán Phím Tắt",
            subtitle: "Cuộn đến mục Phím tắt và chọn 'Lưu Bill Ngân Hàng'."
        )
    ]

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "iphone.radiowaves.left.and.right")
                .font(.system(size: 64))
                .foregroundStyle(.indigo)
                .padding(.top, 20)

            VStack(spacing: 8) {
                Text("Cài đặt Gõ Mặt Lưng (Back Tap)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Lưu bill tự động chỉ với 2 lần gõ vào lưng máy mà không cần mở app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Self.steps) { step in
                    GuideStepRow(
                        step: step.step,
                        title: step.title,
                        subtitle: step.subtitle
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
        }
        .padding()
        .navigationTitle("Hướng dẫn Phím Tắt")
    }
}

public struct GuideStepRow: View {
    public let step: String
    public let title: String
    public let subtitle: String

    public init(step: String, title: String, subtitle: String) {
        self.step = step
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.indigo)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShortcutsSetupGuideView()
    }
}

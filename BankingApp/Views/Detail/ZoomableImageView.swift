import SwiftUI
import UIKit

public struct ZoomableImageView: View {
    public let image: UIImage
    @State private var scale: CGFloat = 1.0

    public init(image: UIImage) {
        self.image = image
    }

    /// Clamps scale factor to a safe zoom range [min, max] (defaults to 1.0x - 4.0x)
    public static func clampedScale(_ value: CGFloat, min: CGFloat = 1.0, max: CGFloat = 4.0) -> CGFloat {
        Swift.max(min, Swift.min(value, max))
    }

    public var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = Self.clampedScale(value)
                    }
                    .onEnded { _ in
                        withAnimation {
                            scale = 1.0
                        }
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
    }
}

#Preview {
    ZoomableImageView(image: UIImage(systemName: "doc.text.image") ?? UIImage())
        .padding()
}

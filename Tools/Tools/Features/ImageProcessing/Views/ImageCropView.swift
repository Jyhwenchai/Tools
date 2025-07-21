import AppKit
import SwiftUI

struct ImageCropView: View {
  let image: NSImage
  @Binding var cropRect: NSRect
  @State private var isDragging = false
  @State private var dragStart: CGPoint = .zero
  @State private var initialCropRect: NSRect = .zero
  @State private var imageDisplaySize: NSSize = .zero
  @State private var imageDisplayRect: NSRect = .zero

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Background
        Color.black.opacity(0.8)

        // Image with crop overlay
        if image.cgImage(forProposedRect: nil, context: nil, hints: nil) != nil {
          Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .overlay(cropOverlay)
            .onAppear {
              calculateImageDisplaySize(in: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
              calculateImageDisplaySize(in: newSize)
            }
        }
      }
    }
    .onAppear {
      initializeCropRect()
    }
  }

  private var cropOverlay: some View {
    ZStack {
      // Dimmed areas outside crop rect
      Rectangle()
        .fill(Color.black.opacity(0.5))
        .mask(
          Rectangle()
            .fill(Color.white)
            .overlay(
              Rectangle()
                .frame(
                  width: cropRect.width * imageDisplaySize.width / image.size.width,
                  height: cropRect.height * imageDisplaySize.height / image.size.height)
                .offset(
                  x: (cropRect.origin.x * imageDisplaySize.width / image.size.width) -
                    imageDisplaySize.width / 2,
                  y: (cropRect.origin.y * imageDisplaySize.height / image.size.height) -
                    imageDisplaySize.height / 2)
                .blendMode(.destinationOut)))

      // Crop rectangle border
      Rectangle()
        .stroke(Color.white, lineWidth: 2)
        .frame(
          width: cropRect.width * imageDisplaySize.width / image.size.width,
          height: cropRect.height * imageDisplaySize.height / image.size.height)
        .offset(
          x: (cropRect.origin.x * imageDisplaySize.width / image.size.width) - imageDisplaySize
            .width / 2,
          y: (cropRect.origin.y * imageDisplaySize.height / image.size.height) - imageDisplaySize
            .height / 2)

      // Corner handles
      ForEach(0..<4, id: \.self) { index in
        cropHandle(at: index)
      }
    }
    .gesture(
      DragGesture()
        .onChanged { value in
          handleDrag(value)
        }
        .onEnded { _ in
          isDragging = false
        })
  }

  private func cropHandle(at index: Int) -> some View {
    let handleSize: CGFloat = 12
    let cropDisplayRect = NSRect(
      x: (cropRect.origin.x * imageDisplaySize.width / image.size.width) - imageDisplaySize
        .width / 2,
      y: (cropRect.origin.y * imageDisplaySize.height / image.size.height) - imageDisplaySize
        .height / 2,
      width: cropRect.width * imageDisplaySize.width / image.size.width,
      height: cropRect.height * imageDisplaySize.height / image.size.height)

    let positions = [
      CGPoint(x: cropDisplayRect.origin.x, y: cropDisplayRect.origin.y), // Top-left
      CGPoint(
        x: cropDisplayRect.origin.x + cropDisplayRect.size.width,
        y: cropDisplayRect.origin.y),
      // Top-right
      CGPoint(
        x: cropDisplayRect.origin.x,
        y: cropDisplayRect.origin.y + cropDisplayRect.size.height), // Bottom-left
      CGPoint(
        x: cropDisplayRect.origin.x + cropDisplayRect.size.width,
        y: cropDisplayRect.origin.y + cropDisplayRect.size.height) // Bottom-right
    ]

    return Circle()
      .fill(Color.white)
      .stroke(Color.blue, lineWidth: 2)
      .frame(width: handleSize, height: handleSize)
      .position(positions[index])
      .gesture(
        DragGesture()
          .onChanged { value in
            handleCornerDrag(value, corner: index)
          })
  }

  private func calculateImageDisplaySize(in containerSize: CGSize) {
    let imageAspectRatio = image.size.width / image.size.height
    let containerAspectRatio = containerSize.width / containerSize.height

    if imageAspectRatio > containerAspectRatio {
      // Image is wider than container
      imageDisplaySize = NSSize(
        width: containerSize.width,
        height: containerSize.width / imageAspectRatio)
    } else {
      // Image is taller than container
      imageDisplaySize = NSSize(
        width: containerSize.height * imageAspectRatio,
        height: containerSize.height)
    }

    imageDisplayRect = NSRect(
      x: (containerSize.width - imageDisplaySize.width) / 2,
      y: (containerSize.height - imageDisplaySize.height) / 2,
      width: imageDisplaySize.width,
      height: imageDisplaySize.height)
  }

  private func initializeCropRect() {
    if cropRect == .zero {
      // Initialize with a centered crop rect that's 80% of the image size
      let cropSize = NSSize(
        width: image.size.width * 0.8,
        height: image.size.height * 0.8)
      cropRect = NSRect(
        x: (image.size.width - cropSize.width) / 2,
        y: (image.size.height - cropSize.height) / 2,
        width: cropSize.width,
        height: cropSize.height)
    }
  }

  private func handleDrag(_ value: DragGesture.Value) {
    if !isDragging {
      isDragging = true
      dragStart = value.startLocation
      initialCropRect = cropRect
    }

    let translation = CGPoint(
      x: value.location.x - dragStart.x,
      y: value.location.y - dragStart.y)

    // Convert screen coordinates to image coordinates
    let imageTranslation = CGPoint(
      x: translation.x * image.size.width / imageDisplaySize.width,
      y: translation.y * image.size.height / imageDisplaySize.height)

    var newCropRect = initialCropRect
    newCropRect.origin.x += imageTranslation.x
    newCropRect.origin.y += imageTranslation.y

    // Constrain to image bounds
    newCropRect.origin.x = max(0, min(newCropRect.origin.x, image.size.width - newCropRect.width))
    newCropRect.origin.y = max(0, min(newCropRect.origin.y, image.size.height - newCropRect.height))

    cropRect = newCropRect
  }

  private func handleCornerDrag(_ value: DragGesture.Value, corner: Int) {
    let translation = CGPoint(
      x: value.translation.width * image.size.width / imageDisplaySize.width,
      y: value.translation.height * image.size.height / imageDisplaySize.height)

    var newCropRect = cropRect

    switch corner {
    case 0: // Top-left
      newCropRect.origin.x += translation.x
      newCropRect.origin.y += translation.y
      newCropRect.size.width -= translation.x
      newCropRect.size.height -= translation.y
    case 1: // Top-right
      newCropRect.origin.y += translation.y
      newCropRect.size.width += translation.x
      newCropRect.size.height -= translation.y
    case 2: // Bottom-left
      newCropRect.origin.x += translation.x
      newCropRect.size.width -= translation.x
      newCropRect.size.height += translation.y
    case 3: // Bottom-right
      newCropRect.size.width += translation.x
      newCropRect.size.height += translation.y
    default:
      break
    }

    // Ensure minimum size
    let minSize: CGFloat = 50
    newCropRect.size.width = max(minSize, newCropRect.size.width)
    newCropRect.size.height = max(minSize, newCropRect.size.height)

    // Constrain to image bounds
    newCropRect.origin.x = max(0, min(newCropRect.origin.x, image.size.width - newCropRect.width))
    newCropRect.origin.y = max(0, min(newCropRect.origin.y, image.size.height - newCropRect.height))
    newCropRect.size.width = min(newCropRect.size.width, image.size.width - newCropRect.origin.x)
    newCropRect.size.height = min(newCropRect.size.height, image.size.height - newCropRect.origin.y)

    cropRect = newCropRect
  }
}

#Preview {
  @Previewable @State var cropRect = NSRect.zero
  let testImage = NSImage(systemSymbolName: "photo", accessibilityDescription: nil) ?? NSImage()

  return ImageCropView(image: testImage, cropRect: $cropRect)
    .frame(width: 400, height: 300)
}

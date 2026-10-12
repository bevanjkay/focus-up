// Renders the Focus Up app icon at 1024×1024.
//
//   swift scripts/render-app-icon.swift <output.png>

import AppKit
import CoreImage

let size: CGFloat = 1024
let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "AppIcon-1024.png")

// macOS icon grid: an 824pt rounded square centred on the 1024pt canvas.
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let bodyPath = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)
let centre = CGPoint(x: body.midX, y: body.midY)

func image(_ draw: (CGContext) -> Void) -> CGImage {
    let context = CGContext(
        data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.displayP3)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    draw(context)
    return context.makeImage()!
}

func colour(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        colorSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
        components: [
            CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255, alpha,
        ])!
}

// Soft shapes standing in for the blurred windows behind the focus.
let blurredShapes = image { context in
    let shapes: [(CGRect, UInt32, CGFloat)] = [
        (CGRect(x: 170, y: 560, width: 330, height: 250), 0x8FB8FF, 0.55),
        (CGRect(x: 560, y: 600, width: 300, height: 220), 0xC3A6FF, 0.5),
        (CGRect(x: 200, y: 190, width: 280, height: 230), 0x7AD7F0, 0.45),
        (CGRect(x: 580, y: 170, width: 290, height: 260), 0xB59CFF, 0.5),
    ]
    for (rect, hex, alpha) in shapes {
        context.setFillColor(colour(hex, alpha))
        context.addPath(CGPath(roundedRect: rect, cornerWidth: 40, cornerHeight: 40, transform: nil))
        context.fillPath()
    }
}
let blurred = CIImage(cgImage: blurredShapes).clampedToExtent()
    .applyingGaussianBlur(sigma: 38).cropped(to: CGRect(x: 0, y: 0, width: size, height: size))
let blurredImage = CIContext().createCGImage(blurred, from: blurred.extent)!

let icon = image { context in
    context.saveGState()
    context.addPath(bodyPath)
    context.clip()

    let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.displayP3)!,
        colors: [colour(0x3D7BFF), colour(0x4B3FD9), colour(0x2A1F8F)] as CFArray, locations: [0, 0.55, 1])!
    context.drawLinearGradient(
        gradient, start: CGPoint(x: body.minX, y: body.maxY), end: CGPoint(x: body.maxX, y: body.minY), options: [])
    context.draw(blurredImage, in: CGRect(x: 0, y: 0, width: size, height: size))

    // Dashed focus ring.
    context.setStrokeColor(colour(0xFFFFFF, 0.8))
    context.setLineWidth(30)
    context.setLineCap(.round)
    let ringRadius: CGFloat = 255
    let dashCount = 12.0
    let circumference = 2 * .pi * ringRadius
    context.setLineDash(phase: 0, lengths: [circumference / dashCount * 0.55, circumference / dashCount * 0.45])
    context.addArc(center: centre, radius: ringRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
    context.strokePath()
    context.setLineDash(phase: 0, lengths: [])

    // Sharp centre disc with a soft glow.
    context.setShadow(offset: CGSize(width: 0, height: -12), blur: 40, color: colour(0x0B0640, 0.45))
    context.setFillColor(colour(0xFFFFFF))
    context.fillEllipse(in: CGRect(x: centre.x - 165, y: centre.y - 165, width: 330, height: 330))
    context.restoreGState()

    // Subtle top highlight on the body edge.
    context.saveGState()
    context.addPath(bodyPath)
    context.setStrokeColor(colour(0xFFFFFF, 0.18))
    context.setLineWidth(4)
    context.strokePath()
    context.restoreGState()
}

let rep = NSBitmapImageRep(cgImage: icon)
try rep.representation(using: .png, properties: [:])!.write(to: output)
print("Wrote \(output.path)")

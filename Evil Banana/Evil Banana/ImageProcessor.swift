//
//  ImageProcessor.swift
//  Evil Banana
//
//  Basic utilities for downscaling and writing PNGs.
//

import Foundation
import AppKit
import AVFoundation
import ImageIO
import UniformTypeIdentifiers

enum ImageProcessor {
    static let sharedCache: NSCache<NSURL, NSImage> = {
        let c = NSCache<NSURL, NSImage>()
        c.countLimit = 64
        c.totalCostLimit = 64 * 1024 * 1024
        return c
    }()
    static func downscaleIfNeeded(image: NSImage, maxDimension: CGFloat) -> NSImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = NSSize(width: floor(size.width * scale), height: floor(size.height * scale))

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: newSize), from: .zero, operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    static func writePNGToTemp(image: NSImage) -> URL? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .png, properties: [:]) else { return nil }
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        let url = tmp.appendingPathComponent("evilbanana_\(UUID().uuidString).png")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    static func pngData(_ image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .png, properties: [:]) else { return nil }
        return data
    }

    static func pngData(_ image: NSImage, embedSessionJSON sessionJSON: String) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { return nil }
        // Put session JSON into PNG description
        let pngDict: [CFString: Any] = [kCGImagePropertyPNGDescription: sessionJSON]
        let props: [CFString: Any] = [kCGImagePropertyPNGDictionary: pngDict]
        CGImageDestinationAddImage(dest, cgImage, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
    }

    static func jpegData(_ image: NSImage, quality: CGFloat) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality]) else { return nil }
        return data
    }

    static func encodeForGemini(image: NSImage, maxBytes: Int = 5_000_000) -> (data: Data, mime: String)? {
        // Try PNG first
        if let png = pngData(image), png.count <= maxBytes {
            return (png, "image/png")
        }
        // Try JPEG qualities
        let qualities: [CGFloat] = [0.95, 0.9, 0.85, 0.8, 0.7, 0.6, 0.5, 0.4]
        for q in qualities {
            if let jpg = jpegData(image, quality: q), jpg.count <= maxBytes {
                return (jpg, "image/jpeg")
            }
        }
        // Downscale and try again
        let downscaled = downscaleIfNeeded(image: image, maxDimension: 1024)
        if let png2 = pngData(downscaled), png2.count <= maxBytes {
            return (png2, "image/png")
        }
        for q in qualities.reversed() {
            if let jpg2 = jpegData(downscaled, quality: q), jpg2.count <= maxBytes {
                return (jpg2, "image/jpeg")
            }
        }
        // Fallback to most compressed JPEG even if larger
        if let jpg3 = jpegData(downscaled, quality: 0.35) {
            return (jpg3, "image/jpeg")
        }
        return nil
    }

    static func compositeImages(_ images: [NSImage]) -> NSImage? {
        guard !images.isEmpty else { return nil }
        // Use size of first image; center others scaled to fit
        let baseSize = images.first!.size
        let canvas = NSImage(size: baseSize)
        canvas.lockFocus()
        NSColor.clear.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: baseSize)).fill()
        for image in images {
            let img = downscaleIfNeeded(image: image, maxDimension: max(baseSize.width, baseSize.height))
            let rect = AVMakeRect(aspectRatio: img.size, insideRect: NSRect(origin: .zero, size: baseSize))
            img.draw(in: rect)
        }
        canvas.unlockFocus()
        return canvas
    }

    static func readEmbeddedSessionJSON(from url: URL) -> String? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        guard let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any] else { return nil }
        if let png = props[kCGImagePropertyPNGDictionary] as? [CFString: Any],
           let desc = png[kCGImagePropertyPNGDescription] as? String {
            return desc
        }
        return nil
    }

    static func cachedImage(from url: URL) -> NSImage? {
        if let cached = sharedCache.object(forKey: url as NSURL) { return cached }
        guard let image = NSImage(contentsOf: url) else { return nil }
        sharedCache.setObject(image, forKey: url as NSURL, cost: Int(image.size.width * image.size.height * 4))
        return image
    }
}



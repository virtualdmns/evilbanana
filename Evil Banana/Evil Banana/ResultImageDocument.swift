//
//  ResultImageDocument.swift
//  Evil Banana
//
//  FileDocument for exporting result as PNG.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ResultImageDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.png] }

    let imageData: Data

    init(image: NSImage) {
        if let data = ImageProcessor.pngData(image) {
            self.imageData = data
        } else {
            self.imageData = Data()
        }
    }

    init(imageData: Data) {
        self.imageData = imageData
    }

    init(configuration: ReadConfiguration) throws {
        throw CocoaError(.fileReadUnknown)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard !imageData.isEmpty else { throw CocoaError(.fileWriteUnknown) }
        return FileWrapper(regularFileWithContents: imageData)
    }
}



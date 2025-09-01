//
//  ExportableDocument.swift
//  Habits
//
//  Created by Tiago Fernandes on 01/09/2025.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct ExportableDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.plainText]
    }

    var text: String = ""

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.text = String(decoding: data, as: UTF8.self)
       } else {
            self.text = ""
       }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

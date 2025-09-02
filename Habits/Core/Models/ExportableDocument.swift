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
        [.data]
    }

    var data: Data = Data()

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
       } else {
            self.data = Data()
       }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

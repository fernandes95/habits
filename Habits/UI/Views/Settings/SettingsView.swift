//
//  SettingsView.swift
//  Habits
//
//  Created by Tiago Fernandes on 01/09/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject
    private var router: HabitsRouter

    @EnvironmentObject
    private var state: MainState

    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    @State private var document: ExportableDocument = ExportableDocument(text: "")

    var body: some View {
        VStack {
            List {
                Section {
                    Text("settings_export_button")
                        .onTapGesture {
                            isExporting = true
                        }
                        .fileExporter(
                            isPresented: $isExporting,
                            document: self.document,
                            contentType: .plainText
                        ) { result in
                            switch result {
                            case .success(let file):
                                print(file)
                            case .failure(let error):
                                print(error)
                            }
                        }
                    Text("settings_import_button")
                        .onTapGesture {
                            isImporting = true
                        }
                        .fileImporter(
                           isPresented: $isImporting,
                           allowedContentTypes: [.plainText]
                        ) { result in
                           switch result {
                           case .success(let file):
                               Task {
                                   try await self.state.reloadHabits(url: file)
                               }
                           case .failure(let error):
                               print(error.localizedDescription)
                           }
                        }
                } header: {
                    Text("settings_data_section_title")
                }
            }
            .listStyle(.grouped)
        }
        .navigationTitle("settings_title")
        .task {
            Task {
                do {
                    self.document = try await state.getDataDocument()
                } catch { }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(MainState())
}

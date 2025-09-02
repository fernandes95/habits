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
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: LocalizedStringKey = ""
    @State private var document: ExportableDocument = ExportableDocument(text: "")

    var body: some View {
        ZStack {
            VStack {
                List {
                    Section {
                        Text("settings_export_button")
                            .onTapGesture {
                                Task {
                                    isLoading = true

                                    do {
                                        self.document = try await state.getDataDocument()
                                        isExporting = true
                                    } catch { }

                                    isLoading = false
                                }
                            }
                            .fileExporter(
                                isPresented: $isExporting,
                                document: self.document,
                                contentType: .plainText
                            ) { result in
                                switch result {
                                case .success:
                                    alertTitle = "settings_data_export_success_alert_title"
                                case .failure:
                                    alertTitle = "settings_data_export_fail_alert_title"
                                }
                                showAlert = true
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
                                       alertTitle = "settings_data_import_success_alert_title"
                                   }
                                case .failure:
                                   alertTitle = "settings_data_import_fail_alert_title"
                                }
                                showAlert = true
                            }
                    } header: {
                        Text("settings_data_section_title")
                    }
                }
                .listStyle(.grouped)
            }
            .navigationTitle("settings_title")
            .opacity(isLoading ? 0.5 : 1)
            .alert(alertTitle, isPresented: $showAlert, actions: {})
        }
        .overlay {
            if isLoading {
                SpinnerView()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(MainState())
}

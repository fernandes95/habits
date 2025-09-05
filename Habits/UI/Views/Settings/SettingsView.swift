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
    @State private var showAlert: SettingsAlert = .none
    @State private var showImportAlert: Bool = false
    @State private var document: ExportableDocument = ExportableDocument(data: Data())

    var body: some View {
        ZStack {
            VStack {
                List {
                    Section {
                        Button("settings_export_button") {
                                Task {
                                    isLoading = true

                                    do {
                                        self.document = try await state.getDataDocument()
                                        isExporting = true
                                    } catch {
                                        isLoading = false
                                    }
                                }
                            }
                            .fileExporter(
                                isPresented: $isExporting,
                                document: self.document,
                                contentType: .data
                            ) { result in
                                switch result {
                                case .success:
                                    showAlert = .exportSuccess
                                case .failure:
                                    showAlert = .exportFailure
                                }
                            }
                        Button("settings_import_button") {
                                isLoading = true
                                isImporting = true
                            }
                            .fileImporter(
                               isPresented: $isImporting,
                               allowedContentTypes: [.data]
                            ) { result in
                                switch result {
                                case .success(let url):
                                   Task {
                                       if let didImport = try await self.state.importHabits(url: url) {
                                           self.showImportAlert = didImport
                                           showAlert = didImport ? .importSuccess : .importFailure
                                       } else {
                                           showAlert = .importFailure
                                       }
                                   }
                                case .failure:
                                    showAlert = .importFailure
                                }
                            }
                    } header: {
                        Text("settings_data_section_title")
                    }
                }
                .listStyle(.grouped)
            }
            .navigationTitle("settings_title")
            .opacity(isLoading ? 0.5 : 1)
            .alert(
                showAlert.value,
                isPresented: .constant($showAlert.wrappedValue != .none),
                actions: {}
            )
            .alert(
                "settings_import_duplicate_alert_title",
                isPresented: $showImportAlert,
                actions: {
                    Button("settings_import_duplicate_alert_delete_button", role: .cancel) {
                        self.manageConflicts(.delete)
                    }
                    Button("settings_import_duplicate_alert_duplicate_button") {
                        self.manageConflicts(.duplicate)
                    }
                    Button("settings_import_duplicate_alert_replace_button") {
                        self.manageConflicts(.replace)
                    }
                },
                message: { Text("settings_import_duplicate_alert_message") }
            )
        }
        .onChange(of: self.isExporting) { value in
            if !value {
                isLoading = false
            }
        }
        .onChange(of: self.isImporting) { value in
            if !value {
                isLoading = false
            }
        }
        .overlay {
            if isLoading {
                SpinnerView()
            }
        }
    }

    private func manageConflicts(_ resolution: ConflictResolution) {
        Task {
            try await self.state.manageDuplicatedHabits(resolution)
            showAlert = .importSuccess
        }
    }
}

private enum SettingsAlert {
    case none, exportSuccess, exportFailure, importSuccess, importFailure

    internal var value: LocalizedStringKey {
        return switch self {
        case .none: ""
        case .exportSuccess: "settings_data_export_success_alert_title"
        case .exportFailure: "settings_data_export_fail_alert_title"
        case .importSuccess: "settings_data_import_success_alert_title"
        case .importFailure: "settings_data_import_fail_alert_title"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(MainState())
}

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

    @AppStorage("appTheme")
    private var theme: AppTheme = .system

    @AppStorage("appLanguage")
    private var language: AppLanguage = .system

    @Environment(\.locale)
    private var locale: Locale

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
                                       do {
                                           if let didImport = try await self.state.importHabits(url: url) {
                                               self.showImportAlert = didImport
                                               showAlert = didImport ? .importSuccess : .importFailure
                                           } else {
                                               showAlert = .importFailure
                                           }
                                       } catch {
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
                    Section {
                        Picker("settings_configs_week_title", selection: self.$state.configs.startOfWeek) {
                            ForEach(WeekDay.allCases) { day in
                                Text(day.localizedName(locale: self.locale)).tag(day)
                            }
                        }
                    } header: {
                        Text("settings_configs_section_title")
                    }
                    Section {
                        Picker("settings_appearance_theme_title", selection: self.$theme) {
                            Text("settings_theme_system_title").tag(AppTheme.system)
                            Text("settings_theme_light_title").tag(AppTheme.light)
                            Text("settings_theme_dark_title").tag(AppTheme.dark)
                        }
                    } header: {
                        Text("settings_appearance_section_title")
                    }
                    Section {
                        Picker("settings_language_title", selection: self.$language) {
                            ForEach(AppLanguage.allCases) { language in
                                language.name.tag(language)
                            }
                        }
                    } header: {
                        Text("settings_language_section_title")
                    }
                }
                .listStyle(.grouped)
            }
            .navigationTitle(String(localized: LocalizedStringResource("settings_title", locale: self.locale)))
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
        .onChange(of: self.isExporting) { _, value in
            if !value {
                isLoading = false
            }
        }
        .onChange(of: self.isImporting) { _, value in
            if !value {
                isLoading = false
            }
        }
        .onChange(of: self.state.configs.startOfWeek) { _, value in
            self.updateConfigs(day: value)
        }
        .overlay {
            if isLoading {
                SpinnerView()
            }
        }
    }

    private func updateConfigs(day: WeekDay) {
        Task {
            let newConfigs = self.state.configs.with(
                startOfWeek: day
            )

            await self.state.saveConfigs(newConfigs)
        }
    }

    private func manageConflicts(_ resolution: ConflictResolution) {
        Task {
            do {
                try await self.state.manageDuplicatedHabits(resolution)
                showAlert = .importSuccess
            } catch {
                showAlert = .importFailure
            }
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

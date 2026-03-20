import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("budgetAlertThreshold") private var budgetAlertThreshold = 80.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Form {
                        Section(header: Text("Preferences").foregroundColor(.white.opacity(0.6))) {
                            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                                .tint(Theme.accentColor)
                                .listRowBackground(Color.white.opacity(0.05))
                            
                            if notificationsEnabled {
                                VStack(alignment: .leading) {
                                    Text("Alert me when budget reaches \(Int(budgetAlertThreshold))%")
                                    Slider(value: $budgetAlertThreshold, in: 50...100, step: 5)
                                        .accentColor(Theme.accentColor)
                                }
                                .padding(.vertical, 8)
                                .listRowBackground(Color.white.opacity(0.05))
                            }
                        }
                        
                        Section(header: Text("History").foregroundColor(.white.opacity(0.6))) {
                            Text("No recent notifications")
                                .foregroundColor(.white.opacity(0.4))
                                .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
                .padding(.vertical)
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

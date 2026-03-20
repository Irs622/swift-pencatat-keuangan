import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    
    @State private var selectedTab: Tab = .dashboard
    
    enum Tab {
        case dashboard, transactions, scanner, budgets, analytics
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .transactions:
                    TransactionsListView()
                case .scanner:
                    ReceiptScannerView()
                case .budgets:
                    BudgetManagementView()
                case .analytics:
                    AnalyticsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Floating Tab Bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            seedCategoriesIfEmpty()
        }
    }
    
    private func seedCategoriesIfEmpty() {
        if categories.isEmpty {
            let defaults = [
                Category(name: "Food", iconName: "fork.knife", colorHex: "#FF9500"),
                Category(name: "Transport", iconName: "car.fill", colorHex: "#007AFF"),
                Category(name: "Shopping", iconName: "bag.fill", colorHex: "#AF52DE"),
                Category(name: "Bills", iconName: "doc.text.fill", colorHex: "#FF3B30"),
                Category(name: "Entertainment", iconName: "gamecontroller.fill", colorHex: "#34C759"),
                Category(name: "Others", iconName: "folder.fill", colorHex: "#8E8E93")
            ]
            for category in defaults {
                modelContext.insert(category)
            }
        }
    }
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "house.fill", tab: .dashboard)
            tabItem(icon: "list.bullet.rectangle.fill", tab: .transactions)
            
            // Center Scan Button
            Button(action: { selectedTab = .scanner }) {
                ZStack {
                    Circle()
                        .fill(Theme.accentColor)
                        .frame(width: 60, height: 60)
                        .shadow(color: Theme.accentColor.opacity(0.3), radius: 10, y: 5)
                    
                    Image(systemName: "camera.viewfinder")
                        .font(.title2.bold())
                        .foregroundColor(.black)
                }
                .offset(y: -20)
            }
            .frame(maxWidth: .infinity)
            
            tabItem(icon: "chart.pie.fill", tab: .budgets)
            tabItem(icon: "chart.bar.xaxis", tab: .analytics)
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 34)
        .background(
            Color.white.opacity(0.05)
                .background(BlurLayer(style: .systemThinMaterialDark))
                .ignoresSafeArea()
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .frame(maxHeight: .infinity, alignment: .top)
        )
    }
    
    private func tabItem(icon: String, tab: Tab) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(selectedTab == tab ? Theme.accentColor : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: [Category.self, Transaction.self, Budget.self], inMemory: true)
    }
}

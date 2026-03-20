import SwiftUI
import SwiftData

struct BudgetManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Budget.year, order: .reverse) private var budgets: [Budget]
    
    @State private var showingAddBudget = false
    
    var body: some View {
        ZStack {
            Theme.primaryBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    headerView
                    
                    VStack(spacing: 20) {
                        if budgets.isEmpty {
                            Text("No budgets set for this month")
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.top, 40)
                        } else {
                            ForEach(budgets) { budget in
                                BudgetCard(budget: budget)
                            }
                        }
                    }
                    
                    addBudgetButton
                }
                .padding()
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showingAddBudget) {
            AddBudgetView()
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Budgets")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Text("Set your monthly spending limits and stay on track.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private var addBudgetButton: some View {
        Button(action: { showingAddBudget = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add New Budget")
            }
            .font(.headline)
            .foregroundColor(Theme.accentColor)
            .padding()
            .frame(maxWidth: .infinity)
            .glassCard(opacity: 0.1)
        }
    }
}

struct BudgetCard: View {
    let budget: Budget
    
    var progress: Double { budget.progress }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "chart.pie.fill")
                    .font(.title3)
                    .foregroundColor(Theme.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Theme.accentColor.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget") // Map to category name later
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(Theme.formatCurrency(budget.limitAmount - budget.currentSpent)) remaining")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .foregroundColor(budget.isOverBudget ? Theme.dangerColor : .white)
            }
            
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 10)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(budget.isOverBudget ? Theme.dangerColor : Theme.accentColor)
                            .frame(width: geo.size.width * min(progress, 1.0), height: 10)
                    }
                }
                .frame(height: 10)
                
                HStack {
                    Text("\(Theme.formatCurrency(budget.currentSpent)) spent")
                    Spacer()
                    Text("\(Theme.formatCurrency(budget.limitAmount)) total")
                }
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding()
        .glassCard(opacity: 0.1)
    }
}

struct BudgetManagementView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetManagementView()
    }
}

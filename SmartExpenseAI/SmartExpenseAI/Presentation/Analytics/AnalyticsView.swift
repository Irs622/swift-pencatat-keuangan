import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    @Query private var budgets: [Budget]
    
    // Computed properties for real data
    private var expensesByCategory: [(name: String, amount: Double, color: Color, percentage: Double)] {
        let expenses = transactions.filter { $0.type == .expense }
        let totalExpense = expenses.reduce(0) { $0 + $1.amount }
        
        var categoryTotals = [UUID: Double]()
        for exp in expenses {
            if let id = exp.categoryId {
                categoryTotals[id, default: 0] += exp.amount
            }
        }
        
        var result: [(String, Double, Color, Double)] = []
        for (id, amount) in categoryTotals {
            let cat = categories.first(where: { $0.id == id })
            let name = cat?.name ?? "Others"
            let color = cat?.color ?? .gray
            let pct = totalExpense > 0 ? amount / totalExpense : 0
            result.append((name, amount, color, pct))
        }
        return result.sorted { $0.1 > $1.1 }
    }
    
    private var last7DaysTrend: [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var trend: [Double] = []
        
        // Go back 6 days + today
        for i in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else {
                trend.append(0)
                continue
            }
            let dailyTotal = transactions
                .filter { $0.type == .expense && calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.amount }
            trend.append(dailyTotal)
        }
        return trend
    }
    
    private var weekDayInitial: [String] {
        let calendar = Calendar.current
        var symbols: [String] = []
        for i in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let weekday = calendar.component(.weekday, from: date)
                // 1=Sun, 2=Mon... get very short symbol
                let symbol = calendar.veryShortWeekdaySymbols[weekday - 1]
                symbols.append(symbol)
            } else {
                symbols.append("-")
            }
        }
        return symbols
    }
    var body: some View {
        ZStack {
            Theme.primaryBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    Text("Analytics")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    // Category Breakdown Chart (Simplified)
                    categoryBreakdownSection
                    
                    // Monthly Trend Chart (Simplified)
                    monthlyTrendSection
                    
                    // Smart Insights
                    insightsSection
                }
                .padding()
            }
        }
    }
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                if expensesByCategory.isEmpty {
                    Text("No expenses yet")
                        .foregroundColor(.white.opacity(0.6))
                        .padding()
                } else {
                    ForEach(expensesByCategory, id: \.name) { item in
                        categoryRow(name: item.name, amount: CurrencyFormatter.format(item.amount), percentage: item.percentage, color: item.color)
                    }
                }
            }
            .padding()
            .glassCard(opacity: 0.1)
        }
    }
    
    private func categoryRow(name: String, amount: String, percentage: Double, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(name)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(amount)
                .bold()
                .foregroundColor(.white)
        }
    }
    
    private var monthlyTrendSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Monthly Trend")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(alignment: .bottom, spacing: 12) {
                let maxAmount = last7DaysTrend.max() ?? 1
                let cappedMax = maxAmount > 0 ? maxAmount : 1
                
                ForEach(0..<7, id: \.self) { i in
                    let amount = last7DaysTrend[i]
                    let height = CGFloat((amount / cappedMax) * 120) // max height 120
                    let displayHeight = max(height, 5) // minimum height so it's visible
                    
                    VStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(i == 6 ? Theme.accentColor : Color.white.opacity(0.1))
                            .frame(height: displayHeight)
                        Text(weekDayInitial[i])
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .frame(height: 180)
            .glassCard(opacity: 0.1)
        }
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("AI Insights")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                let nearLimitBudgets = budgets.filter { $0.isNearLimit }
                let overBudgets = budgets.filter { $0.isOverBudget }
                
                if nearLimitBudgets.isEmpty && overBudgets.isEmpty {
                    insightChoice(title: "On Track", description: "You are doing great! No budgets are over the limit.", icon: "checkmark.seal.fill", color: .green)
                }
                
                ForEach(overBudgets) { budget in
                    let catName = categories.first(where: { $0.id == budget.categoryId })?.name ?? "Category"
                    insightChoice(title: "Over Budget", description: "Your \(catName) budget exceeded its limit.", icon: "exclamationmark.octagon.fill", color: .red)
                }
                
                ForEach(nearLimitBudgets) { budget in
                    let catName = categories.first(where: { $0.id == budget.categoryId })?.name ?? "Category"
                    let pct = Int(budget.progress * 100)
                    insightChoice(title: "Budget Alert", description: "Your \(catName) budget is approaching its limit (\(pct)% used).", icon: "exclamationmark.triangle.fill", color: .yellow)
                }
            }
        }
    }
    
    private func insightChoice(title: String, description: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .glassCard(opacity: 0.1)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.bold())
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .glassCard(opacity: 0.1)
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
    }
}

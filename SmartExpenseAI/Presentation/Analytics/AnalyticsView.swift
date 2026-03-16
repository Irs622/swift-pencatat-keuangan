import SwiftUI

struct AnalyticsView: View {
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
                categoryRow(name: "Belanja", amount: Theme.formatCurrency(850000), percentage: 0.45, color: .purple)
                categoryRow(name: "Makanan & Minuman", amount: Theme.formatCurrency(420000), percentage: 0.22, color: .orange)
                categoryRow(name: "Transportasi", amount: Theme.formatCurrency(320000), percentage: 0.17, color: .blue)
                categoryRow(name: "Kebutuhan Pokok", amount: Theme.formatCurrency(300000), percentage: 0.16, color: .green)
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
                ForEach(0..<7) { i in
                    let height = CGFloat.random(in: 40...120)
                    VStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(i == 6 ? Theme.accentColor : Color.white.opacity(0.1))
                            .frame(height: height)
                        Text(["M", "T", "W", "T", "F", "S", "S"][i])
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
                insightChoice(title: "Potential Saving", description: "You spent 15% more on Coffee this month than last month.", icon: "cup.and.saucer.fill", color: .orange)
                insightChoice(title: "Budget Alert", description: "Your Shopping budget is approaching its limit (85% used).", icon: "exclamationmark.triangle.fill", color: .yellow)
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

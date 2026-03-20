import SwiftUI
import SwiftData

struct AddBudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Category.name) private var categories: [Category]
    
    @State private var selectedCategoryId: UUID?
    @State private var limitAmountString = ""
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Form {
                        Section(header: Text("Budget Details").foregroundColor(.white.opacity(0.6))) {
                            Picker("Category", selection: $selectedCategoryId) {
                                Text("Select Category").tag(UUID?.none)
                                ForEach(categories) { category in
                                    Text(category.name).tag(UUID?.some(category.id))
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                            
                            HStack {
                                Text("Limit Amount")
                                Spacer()
                                TextField("0", text: $limitAmountString)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: limitAmountString) { _, newValue in
                                        let formatted = CurrencyFormatter.formatInput(newValue)
                                        if limitAmountString != formatted {
                                            limitAmountString = formatted
                                        }
                                    }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                        
                        Section(header: Text("Period").foregroundColor(.white.opacity(0.6))) {
                            Picker("Month", selection: $selectedMonth) {
                                ForEach(1...12, id: \.self) { month in
                                    Text(Calendar.current.monthSymbols[month-1]).tag(month)
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                            
                            Picker("Year", selection: $selectedYear) {
                                ForEach(2024...2030, id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    
                    Button(action: saveBudget) {
                        Text("Save Budget")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accentColor)
                            .cornerRadius(Theme.cornerRadius)
                    }
                    .padding(.horizontal)
                    .disabled(selectedCategoryId == nil || limitAmountString.isEmpty)
                }
                .padding(.vertical)
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func saveBudget() {
        guard let categoryId = selectedCategoryId,
              let limitAmount = CurrencyFormatter.parse(limitAmountString) else { return }
        
        let newBudget = Budget(
            categoryId: categoryId,
            limitAmount: limitAmount,
            month: selectedMonth,
            year: selectedYear
        )
        
        modelContext.insert(newBudget)
        try? modelContext.save()
        dismiss()
    }
}

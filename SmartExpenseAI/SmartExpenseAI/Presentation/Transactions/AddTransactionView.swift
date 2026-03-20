import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Category.name) private var categories: [Category]
    
    @State private var amountString = ""
    @State private var selectedCategoryId: UUID?
    @State private var date = Date()
    @State private var note = ""
    @State private var storeName = ""
    @State private var transactionType: TransactionType = .expense
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.primaryBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    Form {
                        Section(header: Text("Transaction Details").foregroundColor(.white.opacity(0.6))) {
                            Picker("Type", selection: $transactionType) {
                                Text("Expense").tag(TransactionType.expense)
                                Text("Income").tag(TransactionType.income)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .listRowBackground(Color.clear)
                            
                            HStack {
                                Text("Amount")
                                Spacer()
                                TextField("0", text: $amountString)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .onChange(of: amountString) { _, newValue in
                                        let formatted = CurrencyFormatter.formatInput(newValue)
                                        if amountString != formatted {
                                            amountString = formatted
                                        }
                                    }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                            
                            Picker("Category", selection: $selectedCategoryId) {
                                Text("Select Category").tag(UUID?.none)
                                ForEach(categories) { category in
                                    Text(category.name).tag(UUID?.some(category.id))
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.05))
                            
                            DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .listRowBackground(Color.white.opacity(0.05))
                        }
                        
                        Section(header: Text("Optional Info").foregroundColor(.white.opacity(0.6))) {
                            TextField("Store / Source Name", text: $storeName)
                                .listRowBackground(Color.white.opacity(0.05))
                            
                            TextField("Note", text: $note)
                                .listRowBackground(Color.white.opacity(0.05))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    
                    Button(action: saveTransaction) {
                        Text("Save Transaction")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accentColor)
                            .cornerRadius(Theme.cornerRadius)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .disabled(selectedCategoryId == nil || amountString.isEmpty)
                }
                .padding(.vertical)
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func saveTransaction() {
        guard let categoryId = selectedCategoryId,
              let amount = CurrencyFormatter.parse(amountString) else { return }
        
        let newTx = Transaction(
            date: date,
            amount: amount,
            type: transactionType,
            categoryId: categoryId,
            storeName: storeName.isEmpty ? nil : storeName,
            note: note.isEmpty ? nil : note
        )
        
        modelContext.insert(newTx)
        try? modelContext.save()
        dismiss()
    }
}

import SwiftUI
import SwiftData
import Vision
import VisionKit

struct ReceiptScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @State private var showingScanner = false
    @State private var scannedText = ""
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            Theme.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                headerView
                
                // Scanner illustration/status
                scannerStatusCard
                
                Spacer()
                
                // Scan Button
                scanButton
            }
            .padding()
        }
        .sheet(isPresented: $showingScanner) {
            ScannerViewController(didFinishScanning: { result in
                switch result {
                case .success(let images):
                    isProcessing = true
                    processImages(images)
                case .failure(let error):
                    print("Scanner error: \(error)")
                }
                showingScanner = false
            })
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Receipt Scanner")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Text("Point your camera at a receipt to extract data automatically.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var scannerStatusCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(Theme.accentColor)
            
            if isProcessing {
                ProgressView("Analyzing Receipt...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
            } else {
                Text(scannedText.isEmpty ? "Ready to Scan" : "Scanning Complete")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .glassCard(opacity: 0.1)
    }
    
    private var scanButton: some View {
        Button(action: { showingScanner = true }) {
            HStack {
                Image(systemName: "camera.fill")
                Text("Start Scanning")
                    .font(.headline)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Theme.accentColor)
            .cornerRadius(Theme.cornerRadius)
        }
    }
    
    private func processImages(_ images: [UIImage]) {
        guard let firstImage = images.first, let cgImage = firstImage.cgImage else {
            isProcessing = false
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var recognizedText = ""
            for observation in observations {
                if let topCandidate = observation.topCandidates(1).first {
                    recognizedText += topCandidate.string + "\n"
                }
            }
            
            DispatchQueue.main.async {
                self.scannedText = recognizedText
                
                // Call AI Parser Service
                AIParserService.shared.parseReceiptText(recognizedText) { result in
                    switch result {
                    case .success(let data):
                        let newTransaction = Transaction(
                            amount: data.totalAmount,
                            type: TransactionType.expense,
                            storeName: data.storeName,
                            note: "Scanned from receipt"
                        )
                        modelContext.insert(newTransaction)
                        
                        // Check and update budget
                        updateBudgetAndNotify(for: data)
                        
                        self.isProcessing = false
                    case .failure(let error):
                        print("AI Parsing failed: \(error)")
                        self.isProcessing = false
                    }
                }
            }
        }
        
        request.recognitionLevel = .accurate
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform text recognition: \(error)")
                DispatchQueue.main.async { self.isProcessing = false }
            }
        }
    }
    
    private func updateBudgetAndNotify(for data: AIReceiptData) {
        if let budget = budgets.first {
            let previousProgress = budget.progress
            budget.currentSpent += data.totalAmount
            let currentProgress = budget.progress
            
            if previousProgress < 0.8 && currentProgress >= 0.8 && currentProgress < 1.0 {
                NotificationManager.shared.scheduleBudgetAlert(categoryName: data.category, percentUsed: 80)
            } else if previousProgress < 1.0 && currentProgress >= 1.0 {
                NotificationManager.shared.scheduleBudgetAlert(categoryName: data.category, percentUsed: 100)
            }
        }
    }
}

// Data Source for Scanner
enum ScannerResult {
    case success([UIImage])
    case failure(Error)
}

struct ScannerViewController: UIViewControllerRepresentable {
    var didFinishScanning: (ScannerResult) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(didFinishScanning: didFinishScanning)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        var didFinishScanning: (ScannerResult) -> Void
        
        init(didFinishScanning: @escaping (ScannerResult) -> Void) {
            self.didFinishScanning = didFinishScanning
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var images = [UIImage]()
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            didFinishScanning(.success(images))
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            didFinishScanning(.failure(error))
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            didFinishScanning(.success([]))
        }
    }
}

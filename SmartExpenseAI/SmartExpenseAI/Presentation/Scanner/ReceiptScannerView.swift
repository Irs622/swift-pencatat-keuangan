import SwiftUI
import SwiftData
import Vision
import AVFoundation
import Combine
import CoreImage
import CoreImage.CIFilterBuiltins

struct ReceiptScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query private var categories: [Category]
    @State private var showingScanner = false
    @State private var showingLibrary = false
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
                
                // Buttons
                VStack(spacing: 12) {
                    scanButton
                    
                    Button(action: { showingScanner = false; openPhotoLibrary() }) {
                        Text("Choose from Library")
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.accentColor)
                    }
                }
            }
            .padding()
            .padding(.bottom, 120) // Ensure button is above the floating tab bar
        }
        .fullScreenCover(isPresented: $showingScanner) {
            CustomCameraScannerView(didFinishScanning: { image in
                if let image = image {
                    isProcessing = true
                    processImages([image])
                }
                showingScanner = false
            })
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingLibrary) {
            ImagePicker(didFinishPicking: { image in
                if let image = image {
                    isProcessing = true
                    processImages([image])
                }
                showingLibrary = false
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
                VStack(spacing: 12) {
                    Text(scannedText.isEmpty ? "Ready to Scan" : "Scanning Complete")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if !scannedText.isEmpty {
                        ScrollView {
                            Text(scannedText)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(8)
                        }
                        .frame(height: 100)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
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
        guard let firstImage = images.first else {
            isProcessing = false
            return
        }
        
        // Use PaddleOCR Backend instead of local Vision
        uploadToPaddleOCR(image: firstImage) { result in
            DispatchQueue.main.async {
                guard let result = result else {
                    self.scannedText = "Failed to read text from PaddleOCR."
                    isProcessing = false
                    return
                }
                
                self.scannedText = result.rawText
                let data = result.structured
                
                let matchedCat = categories.first(where: { $0.name.lowercased() == data.category.lowercased() })
                
                let newTransaction = Transaction(
                    date: Date(),
                    amount: data.totalAmount,
                    type: TransactionType.expense,
                    categoryId: matchedCat?.id,
                    storeName: data.storeName,
                    note: "Auto-scanned receipt (\(data.date))"
                )
                
                modelContext.insert(newTransaction)
                try? modelContext.save()
                
                // Update budget
                if let budget = budgets.first {
                    budget.currentSpent += data.totalAmount
                    // (Omit notification logic here or move to a separate helper)
                }
                
                isProcessing = false
            }
        }
    }
    
    // Struct to match Backend response
    struct OCRResponse {
        let rawText: String
        let structured: AIReceiptData
    }
    
    private func uploadToPaddleOCR(image: UIImage, completion: @escaping (OCRResponse?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(nil)
            return
        }
        
        // --- KONEKSI BACKEND ---
        // Jika pakai SIMULATOR: gunakan "http://localhost:8000/ocr/scan"
        // Jika pakai iPHONE ASLI: gunakan IP Mac Anda (misal: "http://192.168.1.10:8000/ocr/scan")
        let apiUrl = "http://localhost:8000/ocr/scan" 
        guard let url = URL(string: apiUrl) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"receipt.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let rawText = json["raw_text"] as? String,
                   let structured = json["structured"] as? [String: Any] {
                    
                    let receiptData = AIReceiptData(
                        storeName: structured["store_name"] as? String ?? "Unknown",
                        date: structured["date"] as? String ?? "",
                        totalAmount: structured["total_amount"] as? Double ?? 0.0,
                        category: structured["category"] as? String ?? "Others"
                    )
                    
                    completion(OCRResponse(rawText: rawText, structured: receiptData))
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
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
    
    private func openPhotoLibrary() {
        showingLibrary = true
    }
    
    private func preprocessImage(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let context = CIContext(options: nil)
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.contrast = 1.5
        filter.brightness = 0.1
        filter.saturation = 0.0 // Grayscale often helps OCR
        
        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return image
    }
}

// MARK: - AVFoundation Custom Camera Implementation

struct CustomCameraScannerView: View {
    var didFinishScanning: (UIImage?) -> Void
    @StateObject private var cameraService = CameraService()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if cameraService.isAuthorized {
                CameraPreviewView(session: cameraService.captureSession)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            didFinishScanning(nil)
                        }) {
                            Text("Cancel")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Capsule())
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                        
                        Button(action: {
                            cameraService.capturePhoto()
                        }) {
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 58, height: 58)
                                )
                        }
                        
                        Spacer()
                        
                        // Empty view for symmetry
                        Color.clear.frame(width: 80, height: 50)
                            .padding(.trailing, 20)
                    }
                    .padding(.bottom, 30)
                }
            } else {
                VStack(spacing: 20) {
                    Text("Layar Kamera (Simulator Photo Fallback)")
                        .foregroundColor(.white)
                    Text("If on a real device, please grant camera permissions in settings.")
                        .foregroundColor(.white)
                    Button("Close") {
                        didFinishScanning(nil)
                    }
                    .padding()
                    .background(Theme.accentColor)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
            }
        }
        .onAppear {
            cameraService.checkPermissions()
        }
        .onChange(of: cameraService.capturedImage) { _, newImage in
            if let image = newImage {
                didFinishScanning(image)
            }
        }
    }
}

class CameraService: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedImage: UIImage?
    @Published var isAuthorized = true
    var captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted { self?.setupCamera() }
                }
            }
        case .denied, .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    func setupCamera() {
        guard captureSession.inputs.isEmpty else { return }
        
        do {
            // Use discovery session to find the best available camera
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTripleCamera], mediaType: .video, position: .back)
            
            guard let device = discoverySession.devices.first ?? AVCaptureDevice.default(for: .video) else {
                DispatchQueue.main.async { self.isAuthorized = false }
                return
            }
            
            let input = try AVCaptureDeviceInput(device: device)
            
            captureSession.beginConfiguration()
            if captureSession.canAddInput(input) { captureSession.addInput(input) }
            if captureSession.canAddOutput(photoOutput) { captureSession.addOutput(photoOutput) }
            captureSession.sessionPreset = .photo
            captureSession.commitConfiguration()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        } catch {
            print("Camera Error: \(error)")
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        DispatchQueue.main.async {
            self.capturedImage = image
            self.captureSession.stopRunning()
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Handle resizing dynamically if needed
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - Simple Image Picker for Library Fallback

struct ImagePicker: UIViewControllerRepresentable {
    var didFinishPicking: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(didFinishPicking: didFinishPicking)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var didFinishPicking: (UIImage?) -> Void
        
        init(didFinishPicking: @escaping (UIImage?) -> Void) {
            self.didFinishPicking = didFinishPicking
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                didFinishPicking(image)
            } else {
                didFinishPicking(nil)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            didFinishPicking(nil)
        }
    }
}


import SwiftUI
import Foundation
import UIKit
import Vision

// MARK: - Navigation State Management
enum DrawerNavigationState: Equatable {
    case main
    case imagePicker(sourceType: UIImagePickerController.SourceType)
    case imageEdit(image: UIImage)
    case addReceipt(imageUrl: String?)
}

// MARK: - Sheet-Compatible PlusDrawerView

struct PlusDrawerView: View {
    @EnvironmentObject var receiptsViewModel: ReceiptsViewModel
    @Binding var isPresented: Bool
    @State private var navigationState: DrawerNavigationState = .main
    @State private var selectedImage: UIImage?
    @State private var processedImageUrl: String?

    // Track current detent for proper spacing
    @State private var currentDetent: PresentationDetent = .medium

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if navigationState == .main {
                    mainDrawerContent
                } else {
                    navigationContent
                }
            }
        }
        .presentationDetents(presentationDetents, selection: $currentDetent)
        .presentationDragIndicator(.visible)
        .onChange(of: navigationState) { newState in
            // Automatically expand to large when navigating to image picker or edit
            if case .imagePicker = newState, currentDetent == .medium {
                currentDetent = .large
            } else if case .imageEdit = newState, currentDetent == .medium {
                currentDetent = .large
            }
        }
    }

    // Dynamic presentation detents based on navigation state
    private var presentationDetents: Set<PresentationDetent> {
        switch navigationState {
        case .main:
            return [.medium, .large]
        case .imagePicker, .imageEdit:
            return [.large]
        case .addReceipt:
            return [.medium, .large]
        }
    }

    // MARK: - Main Drawer Content

    private var mainDrawerContent: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header with dynamic spacing
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)

                        Text("Quick Actions")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Choose how you'd like to add your receipt")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: currentDetent == .medium ? 20 : 32)

                    // Action buttons
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            ModernActionButton(
                                icon: "camera.fill",
                                title: "",
                                subtitle: "Take photo",
                                color: .blue,
                                action: {
                                    navigationState = .imagePicker(sourceType: .camera)
                                }
                            )

                            ModernActionButton(
                                icon: "photo.on.rectangle.angled",
                                title: "",
                                subtitle: "Choose photo",
                                color: .green,
                                action: {
                                    navigationState = .imagePicker(sourceType: .photoLibrary)
                                }
                            )
                        }

                        ModernActionButton(
                            icon: "doc.text.fill",
                            title: "Manual Entry",
                            subtitle: "Type receipt details manually",
                            color: .orange,
                            isWide: true,
                            action: {
                                navigationState = .addReceipt(imageUrl: nil)
                            }
                        )
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                        .frame(height: currentDetent == .medium ? 16 : 32)

                    // Close button
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Close")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 32)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                    }
                    .padding(.bottom, max(20, geometry.safeAreaInsets.bottom + 8))
                }
                .frame(minHeight: geometry.size.height)
            }
        }
    }

    // MARK: - Navigation Content

    @ViewBuilder
    private var navigationContent: some View {
        switch navigationState {
        case .main:
            EmptyView()

        case .imagePicker(let sourceType):
            ImagePickerWrapperView(
                sourceType: sourceType,
                onImageSelected: { image in
                    selectedImage = image
                    navigationState = .imageEdit(image: image)
                },
                onCancel: {
                    navigationState = .main
                    currentDetent = .medium
                }
            )

        case .imageEdit(let image):
            ImageEditView(
                imageToEdit: image,
                onUpload: { imageUrl in
                    processedImageUrl = imageUrl
                    navigationState = .addReceipt(imageUrl: imageUrl)
                },
                onCancel: {
                    navigationState = .main
                    selectedImage = nil
                    currentDetent = .medium
                }
            )

        case .addReceipt(let imageUrl):
            AddReceiptView(
                imageUrl: imageUrl,
                onDismiss: {
                    navigationState = .main
                    selectedImage = nil
                    processedImageUrl = nil
                    currentDetent = .medium
                    isPresented = false
                }
            )
        }
    }
}

// MARK: - Modern Action Button

struct ModernActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isWide: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(color)
                }

                if isWide {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.gray.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isWide ? 70 : 100)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .if(!isWide) { view in
            view.overlay(
                VStack(spacing: 6) {
                    Spacer()

                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 12)
            )
        }
    }
}

// MARK: - Image Picker Wrapper (for in-sheet presentation)

struct ImagePickerWrapperView: View {
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    let onCancel: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header with proper spacing
                VStack(spacing: 16) {
                    Text("Select an image to process with AI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)
                .padding(.horizontal, 20)

//                Spacer()
//                    .frame(height: 24)

                // Image picker with better framing
                ImagePickerView(
                    sourceType: sourceType,
                    onResult: { result in
                        switch result {
                        case .success(let image):
                            onImageSelected(image)
                        case .failure:
                            onCancel()
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                .frame(height: max(650, geometry.size.height * 0.6))
                .cornerRadius(30)
                .padding(.horizontal, 20)

                Spacer()
                    .frame(height: 24)

                // Cancel button with proper spacing
                Button("Cancel") {
                    onCancel()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.bottom, max(24, geometry.safeAreaInsets.bottom + 8))
            }
        }
    }
}

// MARK: - Image Picker

struct ImagePickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onResult: (Result<UIImage, Error>) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onResult: (Result<UIImage, Error>) -> Void

        init(onResult: @escaping (Result<UIImage, Error>) -> Void) {
            self.onResult = onResult
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onResult(.success(image))
            } else {
                onResult(.failure(ImagePickerError.noImage))
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onResult(.failure(ImagePickerError.cancelled))
        }
    }

    enum ImagePickerError: Error {
        case noImage
        case cancelled
    }
}

// MARK: - Image Edit View

struct ImageEditView: View {
    @EnvironmentObject var receiptsViewModel: ReceiptsViewModel
    let imageToEdit: UIImage
    let onUpload: (String?) -> Void
    let onCancel: () -> Void

    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with better spacing
                        VStack(spacing: 12) {
                            Text("Review & Process")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("AI will extract receipt details automatically")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 24)
                        .padding(.horizontal, 20)

                        Spacer()
                            .frame(height: 24)

                        // Image preview with better sizing
                        VStack(spacing: 16) {
                            Image(uiImage: imageToEdit)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: min(400, geometry.size.height * 0.5))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                            Text("Receipt image ready for processing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)

                        Spacer()
                            .frame(height: 32)

                        // Action buttons with proper spacing
                        VStack(spacing: 16) {
                            Button(action: {
                                processImage()
                            }) {
                                HStack(spacing: 12) {
                                    if isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 16, weight: .semibold))
                                    }

                                    Text(isProcessing ? "Processing..." : "Process with AI")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .disabled(isProcessing)

                            Button("Cancel") {
                                onCancel()
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, max(24, geometry.safeAreaInsets.bottom + 8))
                    }
                    .frame(minHeight: geometry.size.height)
                }

                // Processing overlay
                if isProcessing {
                    ProcessingOverlayView(progress: processingProgress)
                }
            }
        }
    }

    private func processImage() {
        guard let imageData = imageToEdit.jpegData(compressionQuality: 0.8) else { return }
        isProcessing = true
        processingProgress = 0.0

        Task {
            guard let url = URL(string: "http://192.168.1.205/receipts") else { return }
            do {
                let jsonFromImage = try await ImageService.shared.extractTextFromImage(imageToEdit)
                let quality = await ImageService.shared.assessImageQuality(imageToEdit)

                print("Extracted JSON: \(jsonFromImage)")
                print("Image Quality: \(quality)")

                // if (quality.shouldUseAI) {
                    let _ = try await Api.shared.uploadImages(url: url, images: [imageToEdit])
                // } else {
                //     let _ = try await Api.shared.postJSON(url: url, body: [
                //         "data": jsonFromImage
                //     ])
                // }

                await receiptsViewModel.refreshReceipts()

                DispatchQueue.main.async {
                    isProcessing = false
                    let mockUrl = "http://192.168.1.205/receipts/\(UUID().uuidString)"
                    onUpload(mockUrl)
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    // Handle error (show alert, etc.)
                }
            }
        }
    }
}

// MARK: - Processing Overlay

struct ProcessingOverlayView: View {
    let progress: Double
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(rotationAngle))
                }

                VStack(spacing: 8) {
                    Text("AI Processing Receipt")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("\(Int(progress * 100))% Complete")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Add Receipt View

struct AddReceiptView: View {
    let imageUrl: String?
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 32)

                // Header with better spacing
                VStack(spacing: 20) {
                    Text("Receipt Added")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let url = imageUrl {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("Image processed successfully!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Ready for manual entry")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                if let url = imageUrl {
                    VStack(spacing: 12) {
                        Text("Processed Image URL:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(url)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()

                Button("Done") {
                    onDismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, max(24, geometry.safeAreaInsets.bottom + 8))
            }
        }
    }
}

// MARK: - View Extension

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    PlusDrawerView(isPresented: .constant(true))
}

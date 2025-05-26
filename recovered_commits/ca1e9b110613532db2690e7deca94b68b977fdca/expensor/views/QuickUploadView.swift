import SwiftUI
import UIKit

struct QuickUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showSourcePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isUploading = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
                        .cornerRadius(12)
                        .padding()
                    
                    Button(action: {
                        isUploading = true
                        // Upload logic here
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isUploading = false
                            dismiss()
                        }
                    }) {
                        HStack {
                            if isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                            }
                            Text(isUploading ? "Uploading..." : "Upload Receipt")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(isUploading)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Take a photo or select from library")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .navigationTitle("Quick Upload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                if selectedImage == nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showSourcePicker = true
                        }) {
                            Image(systemName: "camera")
                                .font(.headline)
                        }
                    }
                }
            }
        }
        .confirmationDialog("Select Photo", isPresented: $showSourcePicker) {
            Button("Take Photo") {
                imageSourceType = .camera
                showImagePicker = true
            }
            Button("Choose from Library") {
                imageSourceType = .photoLibrary
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: imageSourceType)
        }
        .onAppear {
            showSourcePicker = true
        }
    }
}

#Preview {
    QuickUploadView()
}
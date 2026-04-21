import SwiftUI
import PhotosUI
import UIKit

// MARK: - Photo Library Picker (PHPickerViewController — iOS 14+)

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    var onImageSelected: () -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        if sourceType == .camera {
            return makeCameraPicker(context: context)
        } else {
            return makePhotoPicker(context: context)
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    // MARK: Photo library — PHPickerViewController (no process-map issues)
    private func makePhotoPicker(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    // MARK: Camera — UIImagePickerController (camera only, no LS issue)
    private func makeCameraPicker(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    // MARK: - Coordinator

    class Coordinator: NSObject,
                       PHPickerViewControllerDelegate,
                       UIImagePickerControllerDelegate,
                       UINavigationControllerDelegate {

        let parent: ImagePickerView

        init(_ parent: ImagePickerView) {
            self.parent = parent
        }

        // PHPicker — photo library
        func picker(_ picker: PHPickerViewController,
                    didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        self.parent.image = image
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.parent.onImageSelected()
                        }
                    }
                }
            }
        }

        // UIImagePickerController — camera only
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                let parentRef = parent
                parentRef.image = image
                parentRef.dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    parentRef.onImageSelected()
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

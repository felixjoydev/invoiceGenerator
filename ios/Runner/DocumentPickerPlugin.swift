import Flutter
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

@objc public class DocumentPickerPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
    private var documentPickerResult: FlutterResult?
    
    // Public registration method called by Flutter
    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.invoicegenerator/document_picker",
            binaryMessenger: registrar.messenger()
        )
        let instance = DocumentPickerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        print("✅ DocumentPickerPlugin: Successfully registered document picker plugin")
    }
    
    // Handle method calls from Flutter
    @objc public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("DocumentPickerPlugin: Received method call: \(call.method)")
        
        if call.method == "openDocumentPicker" {
            print("DocumentPickerPlugin: openDocumentPicker called")
            openDocumentPicker(result: result)
            return
        }
        
        print("DocumentPickerPlugin: Method not implemented: \(call.method)")
        result(FlutterMethodNotImplemented)
    }
    
    // Present a document picker
    private func openDocumentPicker(result: @escaping FlutterResult) {
        print("DocumentPickerPlugin: Opening document picker")
        
        // Store result callback
        self.documentPickerResult = result
        
        // Define document types - images only
        var documentTypes: [String]
        if #available(iOS 14.0, *) {
            documentTypes = [
                UTType.jpeg.identifier,
                UTType.png.identifier,
                UTType.image.identifier
            ]
        } else {
            documentTypes = [
                kUTTypeJPEG as String,
                kUTTypePNG as String,
                kUTTypeImage as String
            ]
        }
        
        // Create and present document picker on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                print("DocumentPickerPlugin: self is nil during picker presentation")
                result(FlutterError(code: "NO_INSTANCE", message: "Plugin instance is nil", details: nil))
                return
            }
            
            let picker: UIDocumentPickerViewController
            
            // Create document picker
            if #available(iOS 14.0, *) {
                let utTypes = documentTypes.map { UTType(identifier: $0)! }
                picker = UIDocumentPickerViewController(forOpeningContentTypes: utTypes)
            } else {
                picker = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)
            }
            
            picker.delegate = self
            picker.allowsMultipleSelection = false
            
            // Find view controller to present from
            if let viewController = UIApplication.shared.windows.first?.rootViewController {
                print("DocumentPickerPlugin: Found root view controller")
                viewController.present(picker, animated: true) {
                    print("DocumentPickerPlugin: Document picker presented")
                }
            } else {
                print("DocumentPickerPlugin: ERROR - Could not get root view controller")
                self.documentPickerResult?(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not present document picker", details: nil))
                self.documentPickerResult = nil
            }
        }
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("DocumentPickerPlugin: Document picker did pick documents: \(urls)")
        
        guard let url = urls.first else {
            print("DocumentPickerPlugin: No URLs returned from document picker")
            documentPickerResult?(nil)
            documentPickerResult = nil
            return
        }
        
        print("DocumentPickerPlugin: Selected document URL: \(url.absoluteString)")
        
        // Start accessing the security-scoped resource
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("DocumentPickerPlugin: Successfully read \(data.count) bytes from document")
            
            // Create a local copy in the app's temporary directory
            let tempDirectory = NSTemporaryDirectory()
            let fileName = url.lastPathComponent
            let tempFilePath = tempDirectory + fileName
            let tempFileURL = URL(fileURLWithPath: tempFilePath)
            
            try data.write(to: tempFileURL)
            print("DocumentPickerPlugin: Copied document to \(tempFilePath)")
            
            // Return the path of the local copy
            documentPickerResult?(tempFilePath)
        } catch {
            print("DocumentPickerPlugin: ERROR reading document: \(error.localizedDescription)")
            documentPickerResult?(FlutterError(code: "FILE_ACCESS_ERROR", message: error.localizedDescription, details: nil))
        }
        
        documentPickerResult = nil
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("DocumentPickerPlugin: Document picker was cancelled")
        documentPickerResult?(nil)
        documentPickerResult = nil
    }
} 
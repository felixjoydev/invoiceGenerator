import Flutter
import UIKit
import MobileCoreServices

@objc public class FilePickerPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
    private var documentPickerResult: FlutterResult?
    
    // Public registration method called by Flutter
    @objc public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.invoicegenerator/custom_file_picker",
            binaryMessenger: registrar.messenger()
        )
        let instance = FilePickerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        print("✅ FilePickerPlugin: Successfully registered custom plugin")
    }
    
    // Handle method calls from Flutter
    @objc public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("FilePickerPlugin: Received method call: \(call.method)")
        
        if call.method == "isAvailable" {
            print("FilePickerPlugin: isAvailable called - returning TRUE")
            result(true)
            return
        }
        
        if call.method == "pickDocument" {
            print("FilePickerPlugin: pickDocument called")
            pickDocument(result: result)
            return
        }
        
        print("FilePickerPlugin: Method not implemented: \(call.method)")
        result(FlutterMethodNotImplemented)
    }
    
    // Present a document picker
    private func pickDocument(result: @escaping FlutterResult) {
        print("FilePickerPlugin: pickDocument implementation started")
        
        // Store result callback
        self.documentPickerResult = result
        
        // Create array of allowed UTIs
        let documentTypes = [
            kUTTypeJPEG as String,
            kUTTypePNG as String,
            "public.svg-image",
            kUTTypeImage as String
        ]
        
        // Create and present document picker on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                print("FilePickerPlugin: self is nil during picker presentation")
                result(FlutterError(code: "NO_INSTANCE", message: "Plugin instance is nil", details: nil))
                return
            }
            
            // Create document picker
            let picker = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)
            picker.delegate = self
            picker.allowsMultipleSelection = false
            
            // Find view controller to present from
            guard let viewController = UIApplication.shared.keyWindow?.rootViewController else {
                print("FilePickerPlugin: ERROR - Could not get root view controller")
                self.documentPickerResult?(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not present document picker", details: nil))
                self.documentPickerResult = nil
                return
            }
            
            print("FilePickerPlugin: Presenting document picker")
            viewController.present(picker, animated: true, completion: nil)
        }
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("FilePickerPlugin: Document picker did pick documents")
        
        guard let url = urls.first else {
            print("FilePickerPlugin: No URLs returned from document picker")
            documentPickerResult?(nil)
            documentPickerResult = nil
            return
        }
        
        print("FilePickerPlugin: Selected document URL: \(url.absoluteString)")
        
        // Start accessing the security-scoped resource
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            print("FilePickerPlugin: Successfully read \(data.count) bytes from document")
            
            // Create a local copy in the app's temporary directory
            let tempDirectory = NSTemporaryDirectory()
            let tempFilePath = tempDirectory + url.lastPathComponent
            let tempFileURL = URL(fileURLWithPath: tempFilePath)
            
            try data.write(to: tempFileURL)
            print("FilePickerPlugin: Copied document to \(tempFilePath)")
            
            // Return the path of the local copy
            documentPickerResult?(tempFilePath)
        } catch {
            print("FilePickerPlugin: ERROR reading document: \(error.localizedDescription)")
            documentPickerResult?(FlutterError(code: "FILE_ACCESS_ERROR", message: error.localizedDescription, details: nil))
        }
        
        documentPickerResult = nil
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("FilePickerPlugin: Document picker was cancelled")
        documentPickerResult?(nil)
        documentPickerResult = nil
    }
} 
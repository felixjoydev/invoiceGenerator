import Flutter
import UIKit
import MobileCoreServices

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("AppDelegate: application did finish launching")
    
    // Register other Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up document picker method channel
    let controller = window?.rootViewController as? FlutterViewController
    let documentPickerChannel = FlutterMethodChannel(
      name: "com.invoicegenerator/document_picker",
      binaryMessenger: controller!.binaryMessenger)
    
    documentPickerChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      
      if call.method == "openDocumentPicker" {
        self.openDocumentPicker(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Present a document picker to open the Files app
  private func openDocumentPicker(result: @escaping FlutterResult) {
    // Define document types for images
    let documentTypes = [
      kUTTypeJPEG as String,
      kUTTypePNG as String,
      "public.svg-image",
      kUTTypeImage as String
    ]
    
    // Create and present document picker on main thread
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        result(FlutterError(code: "NO_INSTANCE", message: "AppDelegate instance is nil", details: nil))
        return
      }
      
      // Create document picker
      let picker = UIDocumentPickerViewController(documentTypes: documentTypes, in: .import)
      picker.delegate = self
      picker.allowsMultipleSelection = false
      
      // Find view controller to present from
      guard let viewController = UIApplication.shared.windows.first?.rootViewController else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not present document picker", details: nil))
        return
      }
      
      // Store the result callback
      self.documentPickerResult = result
      
      // Present the picker
      viewController.present(picker, animated: true)
    }
  }
  
  // Store the result callback
  private var documentPickerResult: FlutterResult?
}

// MARK: - UIDocumentPickerDelegate
extension AppDelegate: UIDocumentPickerDelegate {
  public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else {
      documentPickerResult?(nil)
      documentPickerResult = nil
      return
    }
    
    // Start accessing the security-scoped resource
    let didStartAccessing = url.startAccessingSecurityScopedResource()
    
    defer {
      if didStartAccessing {
        url.stopAccessingSecurityScopedResource()
      }
    }
    
    do {
      let data = try Data(contentsOf: url)
      
      // Create a local copy in the app's temporary directory
      let tempDirectory = NSTemporaryDirectory()
      let tempFilePath = tempDirectory + url.lastPathComponent
      let tempFileURL = URL(fileURLWithPath: tempFilePath)
      
      try data.write(to: tempFileURL)
      
      // Return the path of the local copy
      documentPickerResult?(tempFilePath)
    } catch {
      documentPickerResult?(FlutterError(code: "FILE_ACCESS_ERROR", message: error.localizedDescription, details: nil))
    }
    
    documentPickerResult = nil
  }
  
  public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    documentPickerResult?(nil)
    documentPickerResult = nil
  }
}

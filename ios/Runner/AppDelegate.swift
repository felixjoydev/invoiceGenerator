import Flutter
import UIKit
import MobileCoreServices
import SafariServices  // Import for SFSafariViewController

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Auth method channel for communication with Flutter
  private var authMethodChannel: FlutterMethodChannel?
  
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
    
    // Set up auth method channel
    authMethodChannel = FlutterMethodChannel(
      name: "com.invoicegenerator/auth",
      binaryMessenger: controller!.binaryMessenger)
    
    documentPickerChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      
      if call.method == "openDocumentPicker" {
        self.openDocumentPicker(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    // Listen for application activation notifications - helps with auth flows when Safari crashes
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleApplicationDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Called when app becomes active - can happen after Safari crashes during OAuth
  @objc func handleApplicationDidBecomeActive(_ notification: Notification) {
    print("AppDelegate: application did become active - might be returning from OAuth")
    
    // Use method channel to notify Flutter about potential Safari crash
    authMethodChannel?.invokeMethod("checkAuthAfterSafariCrash", arguments: nil, result: { (result) in
      if let error = result as? FlutterError {
        print("Error invoking Flutter method: \(error.message ?? "unknown error")")
      } else if let methodResult = result as? Bool, methodResult {
        print("Flutter auth check successfully initiated")
      }
    })
  }
  
  // Handle URL scheme callbacks for OAuth authentication
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    print("AppDelegate: received URL callback: \(url)")
    
    // Let FlutterAppDelegate handle the URL first (handles plugin callbacks)
    let handled = super.application(app, open: url, options: options)
    
    // Log whether the URL was handled
    print("URL handled by Flutter plugins: \(handled)")
    
    return handled
  }
  
  // Handle universal links (alternative to URL schemes)
  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    print("AppDelegate: handling universal link")
    
    // Handle universal links for authentication
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let incomingURL = userActivity.webpageURL {
      print("Universal link received: \(incomingURL)")
      // Let FlutterAppDelegate handle the URL
      return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
    
    return false
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

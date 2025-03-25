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
  
  // Handle URL open events for deep links and Google Sign-In
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    // Log the URL being opened
    print("AppDelegate: Received URL: \(url.absoluteString)")
    print("AppDelegate: URL scheme: \(url.scheme ?? "none")")
    print("AppDelegate: URL host: \(url.host ?? "none")")
    print("AppDelegate: URL path: \(url.path)")
    print("AppDelegate: URL query: \(url.query ?? "none")")
    print("AppDelegate: Source application: \(options[UIApplication.OpenURLOptionsKey.sourceApplication] ?? "unknown")")
    
    // Parse URL parameters
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
       let queryItems = components.queryItems {
      print("AppDelegate: URL parameters:")
      for item in queryItems {
        print("  \(item.name): \(item.value ?? "nil")")
      }
    }
    
    // For debugging supabase auth issues
    print("AppDelegate: Attempting to manually process the URL")
    
    // Try to directly handle the URL if it's a Supabase OAuth callback
    if url.scheme == "felix.invoicegenerator" && url.host == "login-callback" {
        print("AppDelegate: This is a Supabase OAuth callback URL")
        
        // Add more detailed logging
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            print("AppDelegate: URL components - scheme: \(components.scheme ?? "none"), host: \(components.host ?? "none"), path: \(components.path)")
            
            // Check for access token in fragment or query
            if let fragment = components.fragment, !fragment.isEmpty {
                print("AppDelegate: URL contains fragment: \(fragment)")
            }
            
            if let items = components.queryItems {
                print("AppDelegate: Query items:")
                for item in items {
                    // Don't log the actual token value for security
                    if item.name.contains("token") || item.name.contains("code") {
                        print("AppDelegate: - \(item.name): [REDACTED]")
                    } else {
                        print("AppDelegate: - \(item.name): \(item.value ?? "nil")")
                    }
                }
            }
        }
        
        // Handle it through the normal mechanism first
        let handled = super.application(app, open: url, options: options)
        print("AppDelegate: URL handled by Flutter plugins: \(handled)")
        
        // Return early since we're handling this specially
        return handled
    }
    
    // Let Flutter plugins handle the URL
    let handled = super.application(app, open: url, options: options)
    print("AppDelegate: URL handled by Flutter: \(handled)")
    return handled
  }
  
  // Handle universal links
  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    // Handle universal links if we implement them later
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
      print("AppDelegate: Received universal link: \(url.absoluteString)")
    }
    
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
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

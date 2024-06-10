import UIKit
import SwiftUI
import Flutter
import Firebase
import UserNotifications
import FirebaseCore

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let channelName = "download_pdf_channel"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)

        channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "downloadFile" {
                if let args = call.arguments as? [String: Any],
                   let urlString = args["url"] as? String,
                   let url = URL(string: urlString) {
                    self.downloadFile(from: url)
                    result("Download started")
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid URL", details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        // Request permission for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied: \(error?.localizedDescription ?? "")")
            }
        }
        application.registerForRemoteNotifications()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Handle registration for remote notifications
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token: \(token)")
    }

    // Handle receiving remote notifications
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let aps = userInfo["aps"] as? [String: AnyObject] {
            print("Received notification: \(aps)")
        }
        completionHandler(.newData)
    }

    private func downloadFile(from url: URL) {
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        let downloadTask = session.downloadTask(with: url) { (location, response, error) in
            guard let location = location, error == nil else { return }

            let fileManager = FileManager.default
            let destinationURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("document.pdf")

            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: location, to: destinationURL)
                print("File downloaded to: \(destinationURL)")

                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Download Complete", message: "File has been downloaded to: \(destinationURL.path)", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.window?.rootViewController?.present(alert, animated: true, completion: nil)
                }

            } catch {
                print("Error moving file: \(error)")
            }
        }
        downloadTask.resume()
    }
}

//
//  AppDelegate.swift
//  iTorrent
//
//  Created by  XITRIX on 12.05.2018.
//  Copyright © 2018  XITRIX. All rights reserved.
//

#if TRANSMISSION
import ITorrentTransmissionFramework
#else
import ITorrentFramework
#endif

import AppTrackingTransparency
import UIKit
// import ObjectiveC

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    static var backgrounded = false
    var openedByFile = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
//        ObjC.oldOSPatch()

        pushNotificationsInit(application)
        rootWindowInit()
        Core.configure()

        if #available(iOS 13.0, *) {
            Themes.shared.currentUserTheme = window?.traitCollection.userInterfaceStyle.rawValue
        }

        if UserPreferences.ftpKey {
            Core.shared.startFileSharing()
        }

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("Path: " + url.path)
        if url.absoluteString.hasPrefix("magnet:") {
            Core.shared.addMagnet(url.absoluteString)
        } else if url.absoluteString.hasPrefix("iTorrent:hash:") {
            AppDelegate.openTorrentDetailsViewController(withHash: url.absoluteString.replacingOccurrences(of: "iTorrent:hash:", with: ""), sender: self)
        } else {
            let openInPlace = options[.openInPlace] as? Bool ?? false
            Core.shared.addTorrentFromFile(url, openInPlace: openInPlace)
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        Core.shared.saveTorrents()
        _ = BackgroundTask.shared.startBackground()
        AppDelegate.backgrounded = true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        } else {
            UIApplication.shared.cancelAllLocalNotifications()
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
        BackgroundTask.shared.stopBackgroundTask()
        TorrentSdk.resumeToApp()
        AppDelegate.backgrounded = false
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Core.shared.saveTorrents(filesStatesOnly: false)
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        RssFeedProvider.shared.fetchUpdates { updates in
            if updates.keys.count > 0 {
                let unmuted = updates.keys
                    .filter { !$0.muteNotifications.value }

                if unmuted.count > 0 {
                    let text = unmuted
                        .map { updates[$0]! }
                        .reduce([], +)
                        .compactMap { $0.title }
                        .joined(separator: "\n")

                    NotificationHelper.showNotification(title: Localize.get("RssFeedProvider.Notification.Title"),
                                                        body: text,
                                                        hash: "RSS")
                }
                completionHandler(.newData)
            } else {
                completionHandler(.noData)
            }
        }
    }
}

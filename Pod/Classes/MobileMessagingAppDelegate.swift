//
//  MobileMessagingAppDelegate.swift
//
//  Created by Andrey K. on 12/04/16.
//
//

import Foundation

/**
The Application Delegate inheritance - is a way to integrate Mobile Messaging SDK into your application.
To implement this way, you should inherit your Application Delegate from `MobileMessagingAppDelegate`.
*/
public class MobileMessagingAppDelegate: UIResponder, UIApplicationDelegate {
	/**
	Defines whether the Geofencing service is enabled. Default value is `false` (The service is enabled by default). If you want to disable the Geofencing service you override this variable in your application delegate (the one you inherit from `MobileMessagingAppDelegate`) and return `true`.
	*/
	public var geofencingServiceDisabled: Bool {
		return false
	}
	
	/**
	Passes your Application Code to the Mobile Messaging SDK. In order to provide your own unique Application Code, you override this variable in your application delegate, that you inherit from `MobileMessagingAppDelegate`.
	*/
	public var applicationCode: String {
		fatalError("Application code not set. Please override `applicationCode` variable in your subclass of `MobileMessagingAppDelegate`.")
	}
	
	/**
	Preferable notification types that indicating how the app alerts the user when a  push notification arrives. You should override this variable in your application delegate, that you inherit from `MobileMessagingAppDelegate`.
	- remark: For now, Mobile Messaging SDK doesn't support badge. You should handle the badge counter by yourself.
	*/
	public var userNotificationType: UIUserNotificationType {
		fatalError("UserNotificationType not set. Please override `userNotificationType` variable in your subclass of `MobileMessagingAppDelegate`.")
	}
	
	//MARK: Public
	final public func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		if !isTesting {
			MobileMessaging.withApplicationCode(applicationCode, notificationType: userNotificationType).withGeofencingServiceDisabled(geofencingServiceDisabled).start()
		}
		return mm_application(application, didFinishLaunchingWithOptions: launchOptions)
	}
	
	final public func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
		if !isTesting {
			MobileMessaging.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
		}
		mm_application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
	}
	
	final public func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
		if !isTesting {
			MobileMessaging.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
		}
		mm_application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
	}
	
	//iOS8
	final public func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: Void -> Void) {
		guard let identifier = identifier else {
			return
		}
		if !isTesting {
			MobileMessaging.handleActionWithIdentifier(identifier, userInfo: userInfo, responseInfo: nil, completionHandler: completionHandler)
		}
		mm_application(application, handleActionWithIdentifier: identifier, forRemoteNotification: userInfo, completionHandler: completionHandler)
	}
	
	//iOS9
	@available(iOS 9.0, *)
	final public func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: Void -> Void) {
		guard let identifier = identifier else {
			return
		}
		if !isTesting {
			MobileMessaging.handleActionWithIdentifier(identifier, userInfo: userInfo, responseInfo: responseInfo, completionHandler: completionHandler)
		}
		mm_application(application, handleActionWithIdentifier: identifier, forRemoteNotification: userInfo, withResponseInfo: responseInfo, completionHandler: completionHandler)
	}
	
	/**
	This is a substitution for the standard `application(:didFinishLaunchingWithOptions:)`.
	You override this method in your own application delegate in case you have chosen the Application Delegate inheritance way to integrate with Mobile Messaging SDK and you have some work to be done when the launch process is almost done and the app is almost ready to run.
	*/
	public func mm_application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		return true
	}
	
	/**
	This is a substitution for the standard `application(:didRegisterForRemoteNotificationsWithDeviceToken:)`.
	You override this method in your own application delegate in case you have chosen the Application Delegate inheritance way to integrate with Mobile Messaging SDK and you have some work to be done when the app successfully registered with Apple Push Notification service (APNs).
	*/
	public func mm_application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) { }
	
	/**
	This is an substitution for the standard `application(:didReceiveRemoteNotification:fetchCompletionHandler:)`.
	You override this method in your own application delegate in case you have chosen the Application Delegate inheritance way to integrate with Mobile Messaging SDK and you have some work to be done when a remote notification arrived that indicates there is data to be fetched.
	*/
	public func mm_application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) { }
	
	/**
	This is an substitution for the `application(:handleActionWithIdentifier:forRemoteNotification:completionHandler:)`.
	You override this method in your own application delegate in case you have chosen the Application Delegate inheritance way to integrate with Mobile Messaging SDK and you have some work to be done when the user taps an action button in an alert displayed in response to a remote notification.
	This method is avaliable for iOS 8.0 and later.
	*/
	public func mm_application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], completionHandler: Void -> Void) { }
	
	/**
	This is an substitution for the `application(:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:)`.
	You override this method in your own application delegate in case you have chosen the Application Delegate inheritance way to integrate with Mobile Messaging SDK and you have some work to be done when the user taps an action button in an alert displayed in response to a remote notification.
	This method is avaliable for iOS 9.0 and later.
	*/
	@available(iOS 9.0, *)
	public func mm_application(application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [NSObject : AnyObject], withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: Void -> Void) { }
	
	//MARK: Private
	var isTesting: Bool {
		return NSProcessInfo.processInfo().arguments.contains("-IsDeviceStartedToRunTests")
	}
}
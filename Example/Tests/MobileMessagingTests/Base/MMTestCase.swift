
//  MMTestCase.swift
//  MobileMessaging
//
//  Created by Andrey K. on 16/04/16.
//

import XCTest
import Foundation
import CoreData
@testable import MobileMessaging


class ApnsRegistrationManagerDisabledStub: ApnsRegistrationManager {
	override var isRegistrationHealthy: Bool {
		return true
	}

	override func setRegistrationIsHealthy() {

	}

	override func registerForRemoteNotifications() {

	}
}

class ApnsRegistrationManagerStub: ApnsRegistrationManager {
	override var isRegistrationHealthy: Bool {
		return true
	}
	
	override func setRegistrationIsHealthy() {
		
	}
}

class MessageHandlingDelegateMock : MessageHandlingDelegate {
    var didReceiveNewMessageHandler: ((MTMessage) -> Void)?
    var willPresentInForegroundHandler: ((MTMessage?) -> UserNotificationType)?
    var canPresentInForeground: ((MTMessage) -> Void)?
    var didPerformActionHandler: ((NotificationAction, MTMessage?, () -> Void) -> Void)?
    var didReceiveNewMessageInForegroundHandler: ((MTMessage) -> Void)?
    var willScheduleLocalNotification: ((MTMessage) -> Void)?
    
    func didReceiveNewMessageInForeground(message: MTMessage) {
        didReceiveNewMessageInForegroundHandler?(message)
    }
    
    func willScheduleLocalNotification(for message: MTMessage) {
        willScheduleLocalNotification?(message)
    }
    
    func didReceiveNewMessage(message: MTMessage) {
        didReceiveNewMessageHandler?(message)
    }
    
    @available(iOS 10.0, *)
    func willPresentInForeground(message: MTMessage?, withCompletionHandler completionHandler: @escaping (UserNotificationType) -> Void) {
        
        completionHandler(willPresentInForegroundHandler?(message) ?? UserNotificationType.none)
    }
    
    func canPresentInForeground(message: MTMessage) {
        canPresentInForeground?(message)
    }
    
    func didPerform(action: NotificationAction, forMessage message: MTMessage?, notificationUserInfo: [String: Any]?, completion: @escaping () -> Void) {
        didPerformActionHandler?(action, message, completion)
        completion()
    }
}


let sendDateTimeMillis = 1503583689984 as Double
func apnsNormalMessagePayload(_ messageId: String) -> [AnyHashable: Any] {
    return [
        "messageId": messageId,
        "aps": ["alert": ["title": "msg_title", "body": "msg_body"], "badge": 6, "sound": "default"],
        Consts.APNSPayloadKeys.internalData: ["sendDateTime": sendDateTimeMillis, "internalKey": "internalValue"],
        Consts.APNSPayloadKeys.customPayload: ["customKey": "customValue"]
    ]
}

func sendPushes(_ preparingFunc:(String) -> [AnyHashable: Any], count: Int, receivingHandler: ([AnyHashable: Any]) -> Void) {
    for _ in 0..<count {
        let newMessageId = UUID().uuidString
        if let payload = MTMessage(payload: preparingFunc(newMessageId), deliveryMethod: .undefined, seenDate: nil, deliveryReportDate: nil, seenStatus: .NotSeen, isDeliveryReportSent: false)?.originalPayload {
            receivingHandler(payload)
        } else {
            XCTFail()
        }
    }
}


class ActiveApplicationStub: MMApplication {
	var applicationState: UIApplication.State {
		return .active
	}
	
	var applicationIconBadgeNumber: Int {
		get { return 0 }
		set {}
	}
	
	var isRegisteredForRemoteNotifications: Bool { return true }
	func unregisterForRemoteNotifications() {}
	func registerForRemoteNotifications() {}
	func presentLocalNotificationNow(_ notification: UILocalNotification) {}
	func registerUserNotificationSettings(_ notificationSettings: UIUserNotificationSettings) {}
	var currentUserNotificationSettings: UIUserNotificationSettings? { return nil }
}


class InactiveApplicationStub: MMApplication {
	var applicationState: UIApplication.State {
		return .inactive
	}
	
	var applicationIconBadgeNumber: Int {
		get { return 0 }
		set {}
	}

	var isRegisteredForRemoteNotifications: Bool { return true }
	func unregisterForRemoteNotifications() {}
	func registerForRemoteNotifications() {}
	func presentLocalNotificationNow(_ notification: UILocalNotification) {}
	func registerUserNotificationSettings(_ notificationSettings: UIUserNotificationSettings) {}
	var currentUserNotificationSettings: UIUserNotificationSettings? { return nil }
}

class UserAgentStub: UserAgent {
	override var language: String {return "en"}
	override var notificationsEnabled: Bool {return true}
	override var osVersion: String {return "1.0"}
	override var osName: String {return "mobile OS"}
	override var libraryVersion: String {return "1.0.0"}
	override var libraryName: String {return "MobileMessaging"}
	override var hostingAppVersion: String {return "1.0"}
	override var hostingAppName: String {return "WheatherApp"}
	override var deviceManufacturer: String {return "GoogleApple"}
	override var deviceName: String {return "iPhone Galaxy"}
	override var deviceModelName : String {return "XS"}
	override var deviceSecure: Bool {return true}
	override var deviceTimeZone: String? { return "GMT+03:30"}
}


class MMTestCase: XCTestCase {
    var mobileMessagingInstance: MobileMessaging {
        return MobileMessaging.sharedInstance!
    }
    
    var storage: MMCoreDataStorage {
        return self.mobileMessagingInstance.internalStorage
    }
    
    override func setUp() {
        super.setUp()
		MobileMessaging.logger = MMDefaultLogger()
        MobileMessaging.logger?.logOutput = .Console
        MobileMessaging.logger?.logLevel = .All

        MMTestCase.startWithCorrectApplicationCode()
		MobileMessaging.reachabilityManagerFactory = { return ReachabilityManagerStub(isReachable: true) }
    }
    
    class func cleanUpAndStop() {
        MobileMessaging.stop(true)
		MobileMessaging.sharedInstance = nil
    }
    
    override func tearDown() {
        super.tearDown()
		MMTestCase.cleanUpAndStop()
		MobileMessaging.privacySettings = PrivacySettings()
		GeofencingService.currentDate = nil
		MobileMessaging.timeZone = TimeZone.current
		MobileMessaging.calendar = Calendar.current
		MobileMessaging.userAgent = UserAgent()
	}
    
    class func nonReportedStoredMessagesCount(_ ctx: NSManagedObjectContext) -> Int {
        var count: Int = 0
        ctx.performAndWait {
			ctx.reset()
            count = MessageManagedObject.MM_countOfEntitiesWithPredicate(NSPredicate(format: "reportSent == false"), inContext: ctx)
        }
        return count
    }
    
    class func allStoredMessagesCount(_ ctx: NSManagedObjectContext) -> Int {
        var count: Int = 0
        ctx.performAndWait {
			ctx.reset()
            count = MessageManagedObject.MM_countOfEntitiesWithContext(ctx)
        }
        return count
    }
	
	class func startWithApplicationCode(_ code: String) {
		let mm = stubbedMMInstanceWithApplicationCode(code)
		mm?.start()
	}
	
	class func stubbedMMInstanceWithApplicationCode(_ code: String) -> MobileMessaging? {
		let mm = MobileMessaging.withApplicationCode(code, notificationType: UserNotificationType(options: []) , backendBaseURL: "")!
		mm.setupMockedQueues()
		MobileMessaging.application = ActiveApplicationStub()
		mm.apnsRegistrationManager = ApnsRegistrationManagerStub(mmContext: mm)
		return mm
	}
	
	class func startWithCorrectApplicationCode() {
		let mm = stubbedMMInstanceWithApplicationCode(MMTestConstants.kTestCorrectApplicationCode)!
		mm.apnsRegistrationManager = ApnsRegistrationManagerDisabledStub(mmContext: mm)
		mm.start()
	}
	
	class func startWithWrongApplicationCode() {
		let mm = stubbedMMInstanceWithApplicationCode(MMTestConstants.kTestWrongApplicationCode)!
		mm.apnsRegistrationManager = ApnsRegistrationManagerDisabledStub(mmContext: mm)
		mm.start()
	}
}
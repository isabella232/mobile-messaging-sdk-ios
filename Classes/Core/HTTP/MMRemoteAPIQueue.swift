//
//  RemoteAPIQueue.swift
//  MobileMessaging
//
//  Created by Andrey K. on 19/02/16.
//  
//

enum Result<ValueType> {
	case Success(ValueType)
	case Failure(NSError?)
	case Cancel
	
	var value: ValueType? {
		switch self {
		case .Success(let value):
			return value
		case .Failure, .Cancel:
			return nil
		}
	}
	
	var error: NSError? {
		switch self {
		case .Success, .Cancel:
			return nil
		case .Failure(let error):
			return error
		}
	}
}

class RemoteAPIQueue {
	lazy var queue: MMRetryOperationQueue = {
		return MMRetryOperationQueue.newSerialQueue
	}()
	
	func perform<R: RequestData>(request: R, exclusively: Bool = false, completion: @escaping (Result<R.ResponseType>) -> Void) {
		let requestOperation = MMRetryableRequestOperation<R>(request: request, reachabilityManager: MobileMessaging.reachabilityManagerFactory(), sessionManager: MobileMessaging.httpSessionManager) { responseResult in
			
			completion(responseResult)
			UserEventsManager.postApiErrorEvent(responseResult.error)
		}
		if exclusively {
			if queue.addOperationExclusively(requestOperation) == false {
				MMLogDebug("\(type(of: request)) cancelled due to non-exclusive condition.")
				completion(Result.Cancel)
			}
		} else {
			queue.addOperation(requestOperation)
		}
	}
}

//
//  ChatJSWrapper.swift
//  MobileMessaging
//
//  Created by okoroleva on 24.04.2020.
//

import Foundation
import WebKit

class ChatAttachment {
    let base64: String
    let mimeType: String
    
    init(data: Data) {
        self.base64 = data.base64EncodedString(options: NSData.Base64EncodingOptions.init(rawValue: 0))
        self.mimeType = ChatAttachmentUtils.mimeType(forData: data)
    }
    
    func base64UrlString() -> String {
        return "data:\(self.mimeType);base64,\(self.base64)"
    }
}

protocol ChatJSWrapper {
    func sendMessage(_ message: String?, attachment: ChatAttachment?)
}

extension WKWebView: ChatJSWrapper {
    func sendMessage(_ message: String? = nil, attachment: ChatAttachment? = nil) {
        let escapedMessage = message?.javaScriptEscapedString()
        guard escapedMessage != nil || attachment != nil else {
			MMLogDebug("[InAppChat] sendMessage failed, neither message nor the attachment provided")
			return
		}
        self.evaluateJavaScript("sendMessage(\(escapedMessage ?? "''"), '\(attachment?.base64UrlString() ?? "")')") { (response, error) in
			MMLogDebug("[InAppChat] sendMessage call got a response: \(response.debugDescription), error: \(error?.localizedDescription ?? "")")
		}
	}
}

extension String
{
    func javaScriptEscapedString() -> String?
    {
        let data = try! JSONSerialization.data(withJSONObject:[self], options: [])
		if let encodedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
			return encodedString.substring(with: NSMakeRange(1, encodedString.length - 2))
		}
        return nil
    }
}

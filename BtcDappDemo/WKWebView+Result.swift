//
//  WKWebView+Result.swift
//  BtcDappDemo
//
//  Created by liugang zhang on 2024/3/19.
//

import Foundation
import WebKit

extension WKWebView {
    public func sendError(_ error: String, to id: UInt64) {
        let script = String(format: "window.unisat.sendError(%ld, \"%@\")", id, error)
        print("sendError: \(error)")
        DispatchQueue.main.async {
            self.evaluateJavaScript(script)
        }
    }

    public func sendResult(_ result: String, to id: UInt64) {
        let script = String(format: "window.unisat.sendResponse(%ld, '%@')", id, result)
        print("sendResult: \(script)")
        DispatchQueue.main.async {
            self.evaluateJavaScript(script)
        }
    }

    public func sendAccountChanged(_ accounts: [String]) {
        let script = String(format: "window.unisat.sendAccountChangeEvent('%@')", String(data: try! JSONEncoder().encode(accounts), encoding: .utf8)!)
        DispatchQueue.main.async {
            self.evaluateJavaScript(script)
        }
    }

    public func sendNetworkChanged(_ network: String) {
        let script = String(format: "window.unisat.sendNetworkChangeEvent('%@')", network)
        DispatchQueue.main.async {
            self.evaluateJavaScript(script)
        }
    }
}

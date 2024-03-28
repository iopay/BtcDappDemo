//
//  BtcUserConfigScript.swift
//  BtcDappDemo
//
//  Created by liugang zhang on 2024/3/19.
//

import Foundation
import WebKit

struct BtcUserConfigScript {
    var providerJsUrl: URL {
        return Bundle.main.url(forResource: "index.js", withExtension: nil)!
    }

    var providerScript: WKUserScript {
        let source = try! String(contentsOf: providerJsUrl)
        let script = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        return script
    }

    var injectedScript: WKUserScript {
        let source =
        """
        (function() {

            const provider = new window.bitcoin.Provider();
            window.bitcoin.postMessage = (jsonString) => {
                webkit.messageHandlers._iopay_.postMessage(jsonString)
            }
            window.unisat = provider
        })();
        """

        let script = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        return script
    }
}

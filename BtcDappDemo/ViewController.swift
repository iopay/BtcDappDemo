//
//  ViewController.swift
//  BtcDappDemo
//
//  Created by liugang zhang on 2024/3/19.
//

import UIKit
import WebKit
import BitcoinKit
import CryptoSwift
import secp256k1

class ViewController: UIViewController {
    let webView = WKWebView()
    let scriptConfig = BtcUserConfigScript()

    /// livenet or testnet
    var network = "testnet"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        webView.isInspectable = true
        webView.configuration.userContentController.addUserScript(scriptConfig.providerScript)
        webView.configuration.userContentController.addUserScript(scriptConfig.injectedScript)
        webView.configuration.userContentController.add(self, name: "_iopay_")
        webView.load(URLRequest(url: URL(string: "https://demo.unisat.io/")!))
    }

}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.body)
        guard let obj = message.body as? [String: Any], 
              let id = obj["id"] as? UInt64,
              let method = obj["method"] as? String else {
            return
        }

        let params = obj["params"] as? [String: Any]
        let pk = try! PrivateKey(wif: "cW62cANWa6wXmGPvLMUziJY9Y92apyqRcoopqLfdbaBQw58UMziF")

        switch method {
        case "getAccounts", "requestAccounts":
            let res = [pk.publicKey().taproot().address]
            webView.sendResult(String(data: try! JSONEncoder().encode(res), encoding: .utf8)!, to: id)
        case "getPublicKey":
            let res = pk.publicKey().data.hex
            webView.sendResult(res, to: id)
        case "getBalance":
            let res = [
                "confirmed": 0,
                "unconfirmed": 100000,
                "total": 100000
            ]
            webView.sendResult(String(data: try! JSONEncoder().encode(res), encoding: .utf8)!, to: id)
        case "getNetwork":
            webView.sendResult(network, to: id)
        case "sendBitcoin":
            let sato = params!["satoshis"] as! UInt64
            let toAddress = params!["toAddress"] as! String
            // TODO: build transaction and sign and broadcast
            webView.sendResult("", to: id)
        case "switchNetwork":
            if let network = params?["network"] as? String {
                self.network = network
                webView.sendNetworkChanged(network)
            }
        case "signMessage":
            let text = params!["text"] as! String
            let type = (params!["type"] as? String) ?? "ecdsa"

            if (type == "ecdsa") {
                let res = Crypto.signMessage(text, privateKey: privateKey)
                webView.sendResult(res, to: id)
            } else if type == "bip322-simple" {
                do {
                    let res = try Crypto.signMessageOfBIP322Simple(text, address: pk.publicKey().taproot().address, network: .testnetBTC, privateKey: pk)
                    webView.sendResult(res, to: id)
                } catch {
                    webView.sendError(error.localizedDescription, to: id)
                }
            }
        case "signPsbt":
            // TODO: sign options
            let hex = params!["psbtHex"] as! String
            do {
                let tx = try Transaction.fromPsbtHex(hex)
                let signer = TransactionSigner(transaction: tx, sighashHelper: BTCSignatureHashHelper(hashType: .ALL))
                let signed = try signer.sign(with: [pk])
                webView.sendResult(signed.serializedPsbtHex().hex, to: id)
            } catch {
                webView.sendError(error.localizedDescription, to: id)
            }
        case "signPsbts":
            // TODO: sign multi psbt
            webView.sendError("method not supported", to: id)
        case "pushPsbt":
            let hex = params!["psbtHex"] as! String
            Task {
                do {
                    let tx = try Transaction.fromPsbtHex(hex)
                    let res = try await broadcast(tx.serialized().hex)
                    webView.sendResult(res, to: id)
                } catch {
                    webView.sendError(error.localizedDescription, to: id)
                }
            }
        case "pushTx":
            let hex = params!["rawtx"] as! String
            Task {
                do {
                    let res = try await broadcast(hex)
                    webView.sendResult(res, to: id)
                } catch {
                    webView.sendError(error.localizedDescription, to: id)
                }
            }
        default:
            // TODO: getInscriptions, sendInscription, inscribeTransfer
            webView.sendError("method not supported", to: id)
        }
    }
}

func broadcast(_ tx: String) async throws -> String {
    let url = URL(string: "https://mempool.space/testnet/api/tx")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = tx.data(using: .utf8)
    let (data, _) = try await URLSession.shared.data(for: request)
    return String(data: data, encoding: .utf8)!
}

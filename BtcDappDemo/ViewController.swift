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

/// implement this func in your project
func getPrivateKey(from pubkey: String) throws -> PrivateKey {
    fatalError()
}

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

            Task {
                do {
                    let (psbt, userSignInputs) = try PsbtBuilder.build([], to: [createAddress(from: toAddress)], toAmount: [sato], change: pk.publicKey().legacy(), feeRate: 1)
                    try pk.sign(psbt, options: userSignInputs)
                    let txid = try await broadcast(psbt.extractTransaction().serialized().hex)
                    webView.sendResult(txid, to: id)
                } catch {

                }
            }
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
            guard let hex = params?["psbtHex"] as? String else {
                webView.sendError("", to: id)
                return
            }
            let options = (params?["options"] as? [String : Any]) ?? [:]
            do {
                let psbt = try Psbt.deserialize(hex)
                let options = try formatOptionsToSignInputs(psbt: psbt, toSignInputs: (options["toSignInputs"] as? [[String : Any]]) ?? [])
                let autoFinalized = (params?["autoFinalized"] as? Bool) ?? true
                try pk.sign(psbt, options: options, autoFinalized: autoFinalized)

                webView.sendResult(psbt.serialized().hex, to: id)
            } catch {
                webView.sendError(error.localizedDescription, to: id)
            }
        case "signPsbts":
            guard let psbtHexs = params?["psbtHexs"] as? [String] else {
                return
            }
            for (idx, hex) in psbtHexs.enumerated() {
                let options = (params?["options"] as? [[String: Any]]) ?? []
                let option = idx < options.count ? options[idx] : nil
                /// sign single psbt and return signed hex as string array
            }
        case "pushPsbt":
            let hex = params!["psbtHex"] as! String
            Task {
                do {
                    let psbt = try Psbt.deserialize(hex)
                    let res = try await broadcast(psbt.extractTransaction().serialized().hex)
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

func formatOptionsToSignInputs(psbt: Psbt, toSignInputs: [[String: Any]]?) throws -> [UserToSignInput] {
    let currentAddress = ""
    let currentPublicKey = ""

    if let toSignInputs {
        return try toSignInputs.map { obj in
            guard let index = obj["index"] as? Int else {
                throw ""
            }
            let address = obj["address"] as? String
            let publicKey = obj["publicKey"] as? String
            if address == nil && publicKey == nil {
                throw ""
            }
            if let address, address != currentAddress {
                throw ""
            }
            if let publicKey, publicKey != currentPublicKey {
                throw ""
            }
            let sighashType = (obj["sighashTypes"] as? [UInt8])?.map { BTCSighashType.init(rawValue: $0) }

            return UserToSignInput(
                index: index,
                publicKey: currentPublicKey,
                sighashTypes: sighashType,
                disableTweakSigner: obj["disableTweakSigner"] as? Bool
            )
        }
    } else {
        return try psbt.inputs.enumerated().compactMap { index, input in
            let (script, _) = try psbt.getScriptAndAmountFromUtxo(input: input, index: index)
            let isSigned = input.finalScriptSig != nil || input.finalScriptWitness != nil
            if !isSigned {
                /// FIX: use real world network
                let address = try createAddress(from: script, network: .mainnetBTC)
                let sighashTypes: [BTCSighashType]? = if let type = input.sighashType {
                    [BTCSighashType(rawValue: type)]
                } else {
                    nil
                }
                if address.address == currentAddress {
                    return UserToSignInput(
                        index: index,
                        publicKey: currentPublicKey,
                        sighashTypes: sighashTypes,
                        disableTweakSigner: nil
                    )
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
    }
}

//struct UserToSignInput {
//    let index: Int
//    let publicKey: String
//    let sighashTypes: [BTCSighashType]?
//    let disableTweakSigner: Bool?
//}

/// dont use this
extension String: Error {}

 (function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
 "use strict";
 var __importDefault = (this && this.__importDefault) || function (mod) {
     return (mod && mod.__esModule) ? mod : { "default": mod };
 };
 Object.defineProperty(exports, "__esModule", { value: true });
 const unisat_provider_1 = __importDefault(require("./unisat_provider"));
 // @ts-ignore
 window.bitcoin = {
     Provider: unisat_provider_1.default,
     postMessage: null
 };
 // Object.defineProperty(window, 'bitcoin', {
 //     value: {
 //         Provider: Unisat_provider
 //     }
 // })

 },{"./unisat_provider":3}],2:[function(require,module,exports){
 "use strict";
 Object.defineProperty(exports, "__esModule", { value: true });
 exports.TxType = void 0;
 var TxType;
 (function (TxType) {
     TxType[TxType["SIGN_TX"] = 0] = "SIGN_TX";
     TxType[TxType["SEND_BITCOIN"] = 1] = "SEND_BITCOIN";
     TxType[TxType["SEND_ORDINALS_INSCRIPTION"] = 2] = "SEND_ORDINALS_INSCRIPTION";
     TxType[TxType["SEND_ATOMICALS_INSCRIPTION"] = 3] = "SEND_ATOMICALS_INSCRIPTION";
 })(TxType || (exports.TxType = TxType = {}));

 },{}],3:[function(require,module,exports){
 "use strict";
 var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
     function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
     return new (P || (P = Promise))(function (resolve, reject) {
         function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
         function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
         function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
         step((generator = generator.apply(thisArg, _arguments || [])).next());
     });
 };
 Object.defineProperty(exports, "__esModule", { value: true });
 const types_1 = require("./types");
 const utils_1 = require("./utils");
 class Unisat_provider {
     constructor() {
         // channel = new BroadcastChannel("");
         this._waitingMap = new Map();
         this._eventCallback = {};
         this._request = (data) => __awaiter(this, void 0, void 0, function* () {
             const id = utils_1.Utils.genId();
             return new Promise((resolve, reject) => {
                 this._waitingMap.set(id, {
                     data,
                     resolve,
                     reject
                 });
                 // this.channel.postMessage({ id, data
                 this.sendRequest(Object.assign({ id }, data));
             });
         });
         this.sendRequest = (data) => {
             // @ts-ignore
             if (window.bitcoin.postMessage) {
                 // @ts-ignore
                 window.bitcoin.postMessage(data);
             }
             else {
                 throw new Error('not implemented');
             }
         };
         this.sendResponse = (id, result) => {
             const cb = this._waitingMap.get(id);
             if (cb) {
                 try {
                     const json = JSON.parse(result);
                     cb.resolve(json);
                 }
                 catch (_a) {
                     cb.resolve(result);
                 }
                 this._waitingMap.delete(id);
             }
             else {
                 console.log('no callback found for id', id);
             }
         };
         this.sendError = (id, error) => {
             const cb = this._waitingMap.get(id);
             if (cb) {
                 cb.reject(error);
                 this._waitingMap.delete(id);
             }
             else {
                 console.log('no callback found for id', id);
             }
         };
         this.sendAccountChangeEvent = (accounts) => {
             accounts = JSON.parse(accounts);
             this._eventCallback['accountsChanged'].forEach(cb => cb(accounts));
         };
         this.sendNetworkChangeEvent = (network) => {
             this._eventCallback['networkChanged'].forEach(cb => cb(network));
         };
         // public methods
         this.requestAccounts = () => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'requestAccounts'
             });
         });
         this.getNetwork = () => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'getNetwork'
             });
         });
         this.switchNetwork = (network) => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'switchNetwork',
                 params: {
                     network
                 }
             });
         });
         this.getAccounts = () => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'getAccounts'
             });
         });
         this.getPublicKey = () => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'getPublicKey'
             });
         });
         this.getBalance = () => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'getBalance'
             });
         });
         this.getInscriptions = (...args_1) => __awaiter(this, [...args_1], void 0, function* (cursor = 0, size = 20) {
             return this._request({
                 method: 'getInscriptions',
                 params: {
                     cursor,
                     size
                 }
             });
         });
         this.signMessage = (text, type) => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'signMessage',
                 params: {
                     text,
                     type
                 }
             });
         });
         this.signData = (data, type) => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'signData',
                 params: {
                     data,
                     type
                 }
             });
         });
         this.sendBitcoin = (toAddress, satoshis, options) => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'sendBitcoin',
                 params: {
                     toAddress,
                     satoshis,
                     feeRate: options === null || options === void 0 ? void 0 : options.feeRate,
                     memo: options === null || options === void 0 ? void 0 : options.memo,
                     type: types_1.TxType.SEND_BITCOIN
                 }
             });
         });
         this.sendInscription = (toAddress, inscriptionId, options) => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'sendInscription',
                 params: {
                     toAddress,
                     inscriptionId,
                     feeRate: options === null || options === void 0 ? void 0 : options.feeRate,
                     type: types_1.TxType.SEND_ORDINALS_INSCRIPTION
                 }
             });
         });
         // signTx = async (rawtx: string) => {
         //   return this._request({
         //     method: 'signTx',
         //     params: {
         //       rawtx
         //     }
         //   });
         // };
         /**
          * push transaction
          */
         this.pushTx = (rawtx) => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'pushTx',
                 params: {
                     rawtx
                 }
             });
         });
         this.signPsbt = (psbtHex, options) => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'signPsbt',
                 params: {
                     psbtHex,
                     type: types_1.TxType.SIGN_TX,
                     options
                 }
             });
         });
         this.signPsbts = (psbtHexs, options) => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'multiSignPsbt',
                 params: {
                     psbtHexs,
                     options
                 }
             });
         });
         this.pushPsbt = (psbtHex) => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'pushPsbt',
                 params: {
                     psbtHex
                 }
             });
         });
         this.inscribeTransfer = (ticker, amount) => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'inscribeTransfer',
                 params: {
                     ticker,
                     amount
                 }
             });
         });
         this.getVersion = () => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'getVersion'
             });
         });
         this.isAtomicalsEnabled = () => __awaiter(this, void 0, void 0, function* () {
             return this._request({
                 method: 'isAtomicalsEnabled'
             });
         });
         this.getBitcoinUtxos = (...args_2) => __awaiter(this, [...args_2], void 0, function* (cursor = 0, size = 20) {
             return this._request({
                 method: 'getBitcoinUtxos',
                 params: {
                     cursor,
                     size
                 }
             });
         });
         this.on = (event, cb) => {
             if (!this._eventCallback[event]) {
                 this._eventCallback[event] = [];
             }
             this._eventCallback[event].push(cb);
         };
         this.removeListener = (event, cb) => {
             this._eventCallback[event] = this._eventCallback[event].filter(c => c !== cb);
         };
         // this.channel.postMessage()
     }
 }
 exports.default = Unisat_provider;

 },{"./types":2,"./utils":4}],4:[function(require,module,exports){
 "use strict";
 Object.defineProperty(exports, "__esModule", { value: true });
 exports.Utils = void 0;
 class Utils {
     static genId() {
         return new Date().getTime() + Math.floor(Math.random() * 1000);
     }
 }
 exports.Utils = Utils;

 },{}]},{},[1]);


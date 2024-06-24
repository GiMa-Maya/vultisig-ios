//
//  JoinKeygenViewModel.swift
//  VultisigApp
//
//  Created by Johnny Luo on 18/3/2024.
//

import Foundation
import OSLog

#if os(iOS)
import CodeScanner
#endif

import CoreImage
import Vision

enum JoinKeygenStatus {
    case DiscoverSessionID
    case DiscoverService
    case JoinKeygen
    case WaitingForKeygenToStart
    case KeygenStarted
    case FailToStart
    case NoCameraAccess
}

@MainActor
class JoinKeygenViewModel: ObservableObject {
    private let logger = Logger(subsystem: "join-keygen", category: "viewmodel")
    var vault: Vault
    var serviceDelegate: ServiceDelegate?
    
    @Published var tssType: TssType = .Keygen
    @Published var isShowingScanner = false
    @Published var sessionID: String? = nil
    @Published var hexChainCode: String = ""
    @Published var isCameraPermissionGranted: Bool? = nil
    
    @Published var netService: NetService? = nil
    @Published var status = JoinKeygenStatus.DiscoverSessionID
    @Published var keygenCommittee = [String]()
    @Published var oldCommittee = [String]()
    @Published var localPartyID: String = ""
    @Published var serviceName = ""
    @Published var errorMessage = ""
    @Published var serverAddress: String? = nil
    @Published var oldResharePrefix: String = ""
    var encryptionKeyHex: String = ""
    var vaults: [Vault] = []
    
    init() {
        self.vault = Vault(name: "Main Vault")
    }
    
    func setData(vault: Vault, serviceDelegate: ServiceDelegate,vaults: [Vault], isCameraPermissionGranted: Bool) {
        self.vault = vault
        self.vaults = vaults
        self.serviceDelegate = serviceDelegate
        self.isCameraPermissionGranted = isCameraPermissionGranted
        
        if !vault.localPartyID.isEmpty {
            self.localPartyID = vault.localPartyID
        } else {
            self.localPartyID = Utils.getLocalDeviceIdentity()
            vault.localPartyID = self.localPartyID
        }
        
        if let isAllowed = self.isCameraPermissionGranted, !isAllowed {
            status = .NoCameraAccess
        }
    }
    
    func showBarcodeScanner() {
        isShowingScanner = true
    }
    
    func setStatus(status: JoinKeygenStatus) {
        self.status = status
    }
    
    func discoverService(){
        self.netService = NetService(domain: "local.", type: "_http._tcp.", name: self.serviceName)
        netService?.delegate = self.serviceDelegate
        netService?.resolve(withTimeout: 10)
    }
    
    func joinKeygenCommittee() {
        guard let serverURL = serverAddress, let sessionID = sessionID else {
            logger.error("Required information for joining key generation committee is missing.")
            return
        }
        
        let urlString = "\(serverURL)/\(sessionID)"
        let body = [localPartyID]
        Utils.sendRequest(urlString: urlString, 
                          method: "POST",
                          headers: TssHelper.getKeygenRequestHeader(),
                          body: body) { success in
            if success {
                self.logger.info("Successfully joined the key generation committee.")
                DispatchQueue.main.async {
                    self.status = .WaitingForKeygenToStart
                }
                
            }
        }
    }
    func stopJoinKeygen(){
        self.status = .DiscoverService
    }
    func waitForKeygenStart() async {
        do{
            let t = Task {
                repeat {
                    checkKeygenStarted()
                    try await Task.sleep(for: .seconds(1))
                } while self.status == .WaitingForKeygenToStart
            }
            try await t.value
        }
        catch{
            logger.error("Failed to wait for keygen to start.")
        }
    }
    private func checkKeygenStarted() {
        guard let serverURL = serverAddress, let sessionID = sessionID else {
            logger.error("Required information for checking key generation start is missing.")
            return
        }
        
        let urlString = "\(serverURL)/start/\(sessionID)"
        Utils.getRequest(urlString: urlString,
                         headers: TssHelper.getKeygenRequestHeader(),
                         completion: { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let peers = try decoder.decode([String].self, from: data)
                    DispatchQueue.main.async {
                        if peers.contains(self.localPartyID) {
                            self.keygenCommittee.append(contentsOf: peers)
                            self.status = .KeygenStarted
                        }
                    }
                } catch {
                    self.logger.error("Failed to decode response to JSON: \(data)")
                }
            case .failure(let error):
                self.logger.error("Failed to check if key generation has started, error: \(error)")
            }
        })
    }
    
#if os(iOS)
    func handleScan(result: Result<ScanResult, ScanError>) {
        defer {
            isShowingScanner = false
        }
        
        guard let isCameraPermissionGranted, isCameraPermissionGranted else {
            status = .NoCameraAccess
            return
        }
        
        switch result {
        case .success(let result):
            
            guard let json = DeeplinkViewModel.getJsonData(URL(string: result.string)), let jsonData = json.data(using: .utf8) else {
                status = .FailToStart
                return
            }
            handleQrCodeSuccessResult(scanData: jsonData)
            
        case .failure(_):
            errorMessage = "Unable to scan the QR code. Please import an image using the button below."
            status = .FailToStart
            return
        }
    }
#endif
    func isVaultNameAlreadyExist(name: String) -> Bool  {
        for v in self.vaults {
            if v.name == name && !v.pubKeyECDSA.isEmpty {
                return true
            }
        }
        return false
    }
    
    func handleQrCodeSuccessResult(scanData: Data) {
        var useVultisigRelay = false
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(PeerDiscoveryPayload.self, from: scanData)
            switch result {
            case .Keygen(let keygenMsg):
                tssType = .Keygen
                sessionID = keygenMsg.sessionID
                hexChainCode = keygenMsg.hexChainCode
                vault.hexChainCode = hexChainCode
                serviceName = keygenMsg.serviceName
                encryptionKeyHex = keygenMsg.encryptionKeyHex
                useVultisigRelay = keygenMsg.useVultisigRelay
                vault.name = keygenMsg.vaultName
                if isVaultNameAlreadyExist(name: keygenMsg.vaultName) {
                    errorMessage = "Vault with name:\(keygenMsg.vaultName) already exist"
                    logger.error("\(self.errorMessage)")
                    status = .FailToStart
                    return
                }
            case .Reshare(let reshareMsg):
                tssType = .Reshare
                oldCommittee = reshareMsg.oldParties
                sessionID = reshareMsg.sessionID
                hexChainCode = reshareMsg.hexChainCode
                serviceName = reshareMsg.serviceName
                encryptionKeyHex = reshareMsg.encryptionKeyHex
                useVultisigRelay = reshareMsg.useVultisigRelay
                oldResharePrefix = reshareMsg.oldResharePrefix
                // this means the vault is new , and it join the reshare to become the new committee
                if vault.pubKeyECDSA.isEmpty {
                    if !reshareMsg.pubKeyECDSA.isEmpty {
                        if let reshareVault = vaults.first(where: { $0.pubKeyECDSA == reshareMsg.pubKeyECDSA }) {
                            self.vault = reshareVault
                            self.localPartyID = reshareVault.localPartyID
                        } else {
                            vault.hexChainCode = reshareMsg.hexChainCode
                            vault.name = reshareMsg.vaultName
                            if isVaultNameAlreadyExist(name: reshareMsg.vaultName) {
                                errorMessage = "Vault with name:\(reshareMsg.vaultName) already exist"
                                logger.error("\(self.errorMessage)")
                                status = .FailToStart
                                return
                            }
                        }
                    }
                    
                } else {
                    if vault.pubKeyECDSA != reshareMsg.pubKeyECDSA {
                        errorMessage = "You choose the wrong vault"
                        logger.error("The vault's public key doesn't match the reshare message's public key")
                        status = .FailToStart
                        return
                    }
                }
            }
            
        } catch {
            errorMessage = "Failed to decode peer discovery message: \(error.localizedDescription)"
            status = .FailToStart
            return
        }
        if useVultisigRelay {
            self.serverAddress = Endpoint.vultisigRelay
            status = .JoinKeygen
        } else {
            status = .DiscoverService
        }
    }
    
    func handleQrCodeFromImage(result: Result<[URL], Error>) {
        handleQrCodeSuccessResult(scanData: Utils.handleQrCodeFromImage(result: result))
    }
    
    func handleDeeplinkScan(_ url: URL?) {
        guard let url else {
            return
        }
        
        guard let json = DeeplinkViewModel.getJsonData(url), let jsonData = json.data(using: .utf8) else {
            status = .FailToStart
            return
        }
        handleQrCodeSuccessResult(scanData: jsonData)
    }
}

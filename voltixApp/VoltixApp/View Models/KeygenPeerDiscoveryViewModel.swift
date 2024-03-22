//
//  KeygenPeerDiscoveryViewModel.swift
//  VoltixApp
//

import Foundation
import Mediator
import OSLog

enum PeerDiscoveryStatus {
    case WaitingForDevices
    case Keygen
    case Failure
}

class KeygenPeerDiscoveryViewModel: ObservableObject {
    private let logger = Logger(subsystem: "peers-discory-viewmodel", category: "communication")
    var tssType: TssType
    var vault: Vault
    var participantDiscovery: ParticipantDiscovery?
    
    @Published var status = PeerDiscoveryStatus.WaitingForDevices
    @Published var serviceName = ""
    @Published var errorMessage = ""
    @Published var sessionID = ""
    @Published var localPartyID = ""
    @Published var selections = Set<String>()
    @Published var serverAddr = "http://127.0.0.1:8080"
    
    private let mediator = Mediator.shared
    
    init() {
        self.tssType = .Keygen
        self.vault = Vault(name: "New Vault")
        self.status = .WaitingForDevices
        self.participantDiscovery = nil
    }
    
    func setData(vault: Vault, tssType: TssType, participantDiscovery: ParticipantDiscovery) {
        self.vault = vault
        self.tssType = tssType
        self.participantDiscovery = participantDiscovery
        
        if self.sessionID.isEmpty {
            self.sessionID = UUID().uuidString
        }
        
        if self.serviceName.isEmpty {
            self.serviceName = "VoltixApp-" + Int.random(in: 1 ... 1000).description
        }
        
        if self.vault.hexChainCode.isEmpty {
            guard let chainCode = Utils.getChainCode() else {
                self.logger.error("fail to get chain code")
                self.status = .Failure
                return
            }
            self.vault.hexChainCode = chainCode
        }
        
        if !self.vault.localPartyID.isEmpty {
            self.localPartyID = vault.localPartyID
        } else {
            self.localPartyID = Utils.getLocalDeviceIdentity()
            self.vault.localPartyID = self.localPartyID
        }
    }
    
    func startDiscovery() {
        self.mediator.start(name: self.serviceName)
        self.logger.info("mediator server started")
        self.startSession()
        self.participantDiscovery?.getParticipants(serverAddr: self.serverAddr, sessionID: self.sessionID)
    }
    
    func startKeygen() {
        self.startKeygen(allParticipants: self.selections.map { $0 })
        self.status = .Keygen
        self.participantDiscovery?.stop()
    }

    func stopMediator() {
        self.logger.info("mediator server stopped")
        self.participantDiscovery?.stop()
        self.mediator.stop()
    }

    private func startSession() {
        let urlString = "\(self.serverAddr)/\(self.sessionID)"
        let body = [self.localPartyID]
        Utils.sendRequest(urlString: urlString, method: "POST", body: body) { success in
            if success {
                self.logger.info("Started session successfully.")
            } else {
                self.logger.info("Failed to start session.")
            }
        }
    }
    
    private func startKeygen(allParticipants: [String]) {
        let urlString = "\(self.serverAddr)/start/\(self.sessionID)"
        Utils.sendRequest(urlString: urlString, method: "POST", body: allParticipants) { _ in
            self.logger.info("kicked off keygen successfully")
        }
    }
}
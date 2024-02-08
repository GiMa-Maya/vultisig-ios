//
//  JoinKeysignView.swift
//  VoltixApp
#if os(iOS)
import CodeScanner
#endif
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "join-keysign", category: "communication")
struct JoinKeysignView: View {
    enum JoinKeysignStatus {
        case DiscoverSigningMsg
        case DiscoverService
        case JoinKeysign
        case WaitingForKeysignToStart
        case KeysignStarted
        case FailedToStart
    }

    @EnvironmentObject var appState: ApplicationState
    @Binding var presentationStack: [CurrentScreen]
    @State private var isShowingScanner = false
    @State private var sessionID: String = ""
    @State private var keysignMessages = [String]()
    @ObservedObject private var serviceDelegate = ServiceDelegate()
    private let netService = NetService(domain: "local.", type: "_http._tcp.", name: "VoltixApp")
    @State private var currentStatus = JoinKeysignStatus.DiscoverService
    @State private var keysignCommittee = [String]()
    @State var localPartyID: String = ""
    @State private var errorMsg: String = ""
    @State private var keysignType: KeyType = .ECDSA

    var body: some View {
        VStack {
            switch self.currentStatus {
            case .DiscoverSigningMsg:
                Text("Scan the barcode on another VoltixApp")
                Button("Scan", systemImage: "qrcode.viewfinder") {
                    self.isShowingScanner = true
                }
                .sheet(isPresented: self.$isShowingScanner, content: {
                    #if os(iOS)
                    CodeScannerView(codeTypes: [.qr], completion: self.handleScan)
                    #endif
                })
            case .DiscoverService:
                HStack {
                    Text("discovering mediator service")
                    if self.serviceDelegate.serverUrl == nil {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.blue)
                            .padding(2)
                    } else {
                        Image(systemName: "checkmark").foregroundColor(/*@START_MENU_TOKEN@*/ .blue/*@END_MENU_TOKEN@*/).onAppear {
                            self.currentStatus = .DiscoverSigningMsg
                        }
                    }
                }
            case .JoinKeysign:
                Text("Are you sure to sign the following message?")
                Text("Keysign message:")
                List {
                    ForEach(self.keysignMessages, id: \.self) { item in
                        Text("\(item)")
                    }
                }
                Button("Join keysign committee", systemImage: "person.2.badge.key") {
                    self.joinKeysignCommittee()
                    self.currentStatus = .WaitingForKeysignToStart
                }
            case .WaitingForKeysignToStart:
                HStack {
                    Text("Waiting for keysign to start")
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.blue)
                        .padding(2)
                }.task {
                    Task {
                        repeat {
                            self.checkKeysignStarted()
                            try await Task.sleep(nanoseconds: 1_000_000_000)
                        } while self.currentStatus == .WaitingForKeysignToStart
                    }
                }
            case .KeysignStarted:
                HStack {
                    if self.serviceDelegate.serverUrl != nil && !self.sessionID.isEmpty {
                        KeysignView(presentationStack: self.$presentationStack,
                                    keysignCommittee: self.keysignCommittee,
                                    mediatorURL: self.serviceDelegate.serverUrl ?? "",
                                    sessionID: self.sessionID,
                                    keysignType: self.keysignType,
                                    messsageToSign: self.keysignMessages,
                                    localPartyKey: self.localPartyID)
                    } else {
                        Text("Mediator server url is empty or session id is empty")
                    }
                }.navigationBarBackButtonHidden(true)
            case .FailedToStart:
                // TODO: update this message to be more friendly, it shouldn't happen
                Text("keysign fail to start")
            }

        }.onAppear {
            logger.info("start to discover service")
            self.netService.delegate = self.serviceDelegate
            self.netService.resolve(withTimeout: TimeInterval(10))
            // by this step , creatingVault should be available already
            if self.appState.currentVault == nil {
                self.errorMsg = "no vault"
                self.currentStatus = .FailedToStart
            }

            if let localPartyID = appState.currentVault?.localPartyID, !localPartyID.isEmpty {
                self.localPartyID = localPartyID
            } else {
                self.localPartyID = Utils.getLocalDeviceIdentity()
            }
        }
    }

    private func checkKeysignStarted() {
        guard let serverUrl = serviceDelegate.serverUrl else {
            logger.error("didn't discover server url")
            return
        }
        guard !self.sessionID.isEmpty else {
            logger.error("session id has not acquired")
            return
        }

        let urlString = "\(serverUrl)/start/\(sessionID)"
        Utils.getRequest(urlString: urlString, headers: [String: String](), completion: { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let peers = try decoder.decode([String].self, from: data)
                    if peers.contains(self.localPartyID) {
                        self.keysignCommittee.append(contentsOf: peers)
                        self.currentStatus = .KeysignStarted
                    }
                } catch {
                    logger.error("Failed to decode response to JSON, \(data)")
                }
            case .failure(let error):
                let err = error as NSError
                if err.code == 404 {
                    return
                }
                logger.error("Failed to check keysign started, error: \(error)")
            }
        })
    }

    private func joinKeysignCommittee() {
        guard let serverUrl = serviceDelegate.serverUrl else {
            logger.error("didn't discover server url")
            return
        }
        guard !self.sessionID.isEmpty else {
            logger.error("session id has not acquired")
            return
        }

        let urlString = "\(serverUrl)/\(sessionID)"
        let body = [self.localPartyID]

        Utils.sendRequest(urlString: urlString, method: "POST", body: body) { success in
            if success {
                logger.info("Joined keysign committee successfully.")
            }
        }
    }
    #if os(iOS)
    private func handleScan(result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let result):
            let qrCodeResult = result.string
            let decoder = JSONDecoder()
            if let data = qrCodeResult.data(using: .utf8) {
                do {
                    let keysignMsg = try decoder.decode(KeysignMessage.self, from: data)
                    self.sessionID = keysignMsg.sessionID
                    self.keysignMessages = keysignMsg.keysignMessages
                    self.keysignType = keysignMsg.keysignType
                } catch {
                    logger.error("fail to decode keysign message,error:\(error.localizedDescription)")
                    self.errorMsg = error.localizedDescription
                    self.currentStatus = .FailedToStart
                }
            }
            logger.debug("session id: \(result.string)")
        case .failure(let err):
            logger.error("fail to scan QR code,error:\(err.localizedDescription)")
        }
        self.currentStatus = .JoinKeysign
    }
    #endif
}

#Preview {
    JoinKeysignView(presentationStack: .constant([]))
}
//
//  TokenSelectionViewModel.swift
//  VultisigApp
//
//  Created by Amol Kumar on 2024-03-11.
//

import Foundation
import OSLog
import WalletCore

@MainActor
class CoinSelectionViewModel: ObservableObject {
    
    @Published var groupedAssets: [String: [Coin]] = [:]
    @Published var selection = Set<Coin>()
    
    let actionResolver = CoinActionResolver()
    let balanceService = BalanceService.shared
    let priceService = CryptoPriceService.shared

    private let logger = Logger(subsystem: "assets-list", category: "view")
    
    func allCoins(vault: Vault) -> [Coin] {
        return vault.coins.filter { $0.isNativeToken }
    }
    
    func loadData(coin: Coin) async {
        await balanceService.updateBalance(for: coin)
    }
    
    func setData(for vault: Vault) {
        groupAssets()
        checkSelected(for: vault)
    }
    
    private func checkSelected(for vault: Vault) {
        selection = Set(vault.coins)
    }

    private func groupAssets() {
        groupedAssets = [:]
        groupedAssets = Dictionary(grouping: TokensStore.TokenSelectionAssets.sorted(by: { first, second in
            if first.isNativeToken {
                return true
            }
            return false
        })) { $0.chain.name }
    }

    func handleSelection(isSelected: Bool, asset: Coin) {
        if isSelected {
            if !selection.contains(where: { $0.chain == asset.chain && $0.ticker == asset.ticker }) {
                selection.insert(asset)
            }
        } else {
            if let remove = selection.first(where: { $0.chain == asset.chain && $0.ticker == asset.ticker }) {
                selection.remove(remove)
            }
        }
    }

    func saveAssets(for vault: Vault) async {
        do {
            let removedCoins = vault.coins.filter { coin in
                !selection.contains(where: { $0.ticker == coin.ticker && $0.chain == coin.chain})
            }

            for coin in removedCoins {
                if let idx = vault.coins.firstIndex(where: { $0.ticker == coin.ticker && $0.chain == coin.chain }) {
                    vault.coins.remove(at: idx)
                }
                
                try await Storage.shared.delete(coin)
                
            }

            var newCoins: [Coin] = []

            for asset in selection {
                if !vault.coins.contains(where: { $0.ticker == asset.ticker && $0.chain == asset.chain}) {
                    newCoins.append(asset)
                }
            }

            try await addToChain(assets: newCoins, to: vault)

        } catch {
            print("fail to save asset,\(error)")
        }
    }
    private func getNewCoin(asset: Coin, vault: Vault) -> Coin? {
        switch asset.chain {
        case .thorChain:
            let runeCoinResult = THORChainHelper.getRUNECoin(hexPubKey: vault.pubKeyECDSA, hexChainCode: vault.hexChainCode)
            switch runeCoinResult {
            case .success(let coin):
                coin.priceProviderId = asset.priceProviderId
                return coin
            case .failure(let error):
                logger.info("fail to get thorchain address,error:\(error.localizedDescription)")
            }
        case .mayaChain:
            let cacaoCoinResult = MayaChainHelper.getMayaCoin(hexPubKey: vault.pubKeyECDSA,
                                                              hexChainCode: vault.hexChainCode,
                                                              coinTicker: asset.ticker)
            switch cacaoCoinResult {
            case .success(let coin):
                coin.priceProviderId = asset.priceProviderId
                return coin
            case .failure(let error):
                logger.info("fail to get thorchain address,error:\(error.localizedDescription)")
            }
        case .ethereum, .arbitrum, .base, .optimism, .polygon, .bscChain, .avalanche, .blast, .cronosChain:
            let evmHelper = EVMHelper.getHelper(coin: asset)
            
            let coinResult = evmHelper.getCoin(hexPubKey: vault.pubKeyECDSA, hexChainCode: vault.hexChainCode)
            switch coinResult {
            case .success(let coin):
                let newCoin = Coin(chain: asset.chain,
                                   ticker: asset.ticker,
                                   logo: asset.logo,
                                   address: coin.address,
                                   priceRate: 0.0,
                                   decimals: asset.decimals, // Assuming 18 for Ethereum-based tokens
                                   hexPublicKey: coin.hexPublicKey,
                                   priceProviderId: asset.priceProviderId ,
                                   contractAddress: asset.contractAddress , // Assuming asset has a contractAddress field
                                   rawBalance: "0",
                                   isNativeToken: asset.isNativeToken
                )
                return newCoin
                
            case .failure(let error):
                logger.info("fail to get ethereum address, error: \(error.localizedDescription)")
            }
            
        case .bitcoin, .bitcoinCash, .litecoin, .dogecoin, .dash:
            guard let coinType = CoinType.from(string: asset.chain.name.replacingOccurrences(of: "-", with: "")) else {
                print("Coin type not found on Wallet Core")
                return nil
            }
            let coinResult = UTXOChainsHelper(coin: coinType, vaultHexPublicKey: vault.pubKeyECDSA, vaultHexChainCode: vault.hexChainCode).getCoin()
            switch coinResult {
            case .success(let btc):
                btc.priceProviderId = asset.priceProviderId
                return btc
            case .failure(let err):
                logger.info("fail to get bitcoin address,error:\(err.localizedDescription)")
            }
        case .solana:
            let coinResult = SolanaHelper.getSolana(hexPubKey: vault.pubKeyEdDSA, hexChainCode: vault.hexChainCode)
            switch coinResult {
            case .success(let sol):
                sol.priceProviderId = asset.priceProviderId
                return sol
            case .failure(let err):
                logger.info("fail to get solana address,error:\(err.localizedDescription)")
            }
        case .sui:
            let coinResult = SuiHelper.getSui(hexPubKey: vault.pubKeyEdDSA, hexChainCode: vault.hexChainCode)
            switch coinResult {
            case .success(let sui):
                sui.priceProviderId = asset.priceProviderId
                return sui
            case .failure(let err):
                logger.info("fail to get sui address,error:\(err.localizedDescription)")
            }
        case .polkadot:
            let coinResult = PolkadotHelper.getPolkadot(hexPubKey: vault.pubKeyEdDSA, hexChainCode: vault.hexChainCode)
            switch coinResult {
            case .success(let dot):
                dot.priceProviderId = asset.priceProviderId
                return dot
            case .failure(let err):
                logger.info("fail to get polkadot address,error:\(err.localizedDescription)")
            }
        case .gaiaChain:
            let coinResult = ATOMHelper().getATOMCoin(hexPubKey: vault.pubKeyECDSA, hexChainCode: vault.hexChainCode)
            switch coinResult {
            case .success(let atom):
                atom.priceProviderId = asset.priceProviderId
                return atom
            case .failure(let err):
                logger.info("fail to get solana address,error:\(err.localizedDescription)")
            }
        case .kujira:
            let coinResult = KujiraHelper().getCoin(hexPubKey: vault.pubKeyECDSA, hexChainCode: vault.hexChainCode)
            switch coinResult {
            case .success(let kuji):
                kuji.priceProviderId = asset.priceProviderId
                return kuji
            case .failure(let err):
                logger.info("fail to get solana address,error:\(err.localizedDescription)")
            }
        }
        return nil
    }

    private func addToChain(assets: [Coin], to vault: Vault) async throws {
        if let coin = assets.first, coin.chainType == .EVM, !coin.isNativeToken {
            let addresses = assets.map { $0.contractAddress }
            let coingekoIDs = try await priceService.fetchCoingeckoId(chain: coin.chain, addresses: addresses)

            guard coingekoIDs.count == assets.count else {
                return
            }

            for (index, asset) in assets.enumerated() {
                if let priceProviderId = coingekoIDs[index] {
                    try await addToChain(asset: asset, to: vault, priceProviderId: priceProviderId)
                }
            }
        } else {
            for asset in assets {
                try await addToChain(asset: asset, to: vault, priceProviderId: nil)
            }
        }
    }

    private func addToChain(asset: Coin, to vault: Vault, priceProviderId: String?) async throws {
        guard let newCoin = getNewCoin(asset: asset, vault: vault) else {
            return
        }
        if let priceProviderId {
            newCoin.priceProviderId = priceProviderId
        }
        // Save the new coin first
        try await Storage.shared.save(newCoin)
        vault.coins.append(newCoin)
    }
}
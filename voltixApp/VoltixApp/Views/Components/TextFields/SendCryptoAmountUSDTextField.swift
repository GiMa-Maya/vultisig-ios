//
//  SendCryptoAmountUSDTextField.swift
//  VoltixApp
//
//  Created by Amol Kumar on 2024-03-18.
//

import SwiftUI

struct SendCryptoAmountUSDTextField: View {
    @ObservedObject var tx: SendTransaction
    @ObservedObject var utxoBtc: BitcoinUnspentOutputsService
    @ObservedObject var utxoLtc: LitecoinUnspentOutputsService
    @ObservedObject var eth: EthplorerAPIService
    @ObservedObject var thor: ThorchainService
    @ObservedObject var sol: SolanaService
    @ObservedObject var sendCryptoViewModel: SendCryptoViewModel
    
    var body: some View {
        ZStack(alignment: .trailing) {
            if tx.amountInUSD.isEmpty {
                Text(NSLocalizedString("enterAmount", comment: ""))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            TextField(NSLocalizedString("enterAmount", comment: "").capitalized, text: Binding<String>(
                get: { self.tx.amountInUSD },
                set: { newValue in
                    self.tx.amountInUSD = newValue
                    DebounceHelper.shared.debounce {
                        sendCryptoViewModel.convertUSDToCoin(newValue: newValue, tx: tx, eth: eth)
                    }
                }
            ))
            .submitLabel(.next)
        }
        .font(.body12Menlo)
        .foregroundColor(.neutral0)
        .frame(height: 48)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .background(Color.blue600)
        .cornerRadius(10)
    }
}

#Preview {
    SendCryptoAmountUSDTextField(
        tx: SendTransaction(),
        utxoBtc: BitcoinUnspentOutputsService(),
        utxoLtc: LitecoinUnspentOutputsService(),
        eth: EthplorerAPIService(),
        thor: ThorchainService.shared,
        sol: SolanaService.shared,
        sendCryptoViewModel: SendCryptoViewModel()
    )
}

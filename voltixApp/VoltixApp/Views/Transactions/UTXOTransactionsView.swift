//
//  UTXOTransactionsView.swift
//  VoltixApp
//
//  Created by Amol Kumar on 2024-03-26.
//

import SwiftUI

struct UTXOTransactionsView: View {
    let coin: Coin?
    
    @State var tx: SendTransaction? = nil
    @StateObject var utxoTransactionsService: UTXOTransactionsService = .init()
    
    @EnvironmentObject var appState: ApplicationState
    
    var body: some View {
        view
            .onAppear {
                Task {
                    await setData()
                }
            }
    }
    
    var view: some View {
        ZStack {
            if let transactions = utxoTransactionsService.walletData, let tx = tx {
                if transactions.count>0 {
                    getList(for: transactions, tx: tx)
                } else {
                    ErrorMessage(text: "noTransactions")
                }
            } else if let error = utxoTransactionsService.errorMessage {
                getErrorMessage(error)
            } else {
                loader
            }
        }
    }
    
    var loader: some View {
        ProgressView()
            .preferredColorScheme(.dark)
    }
    
    private func setData() async {
        guard let coin else {
            return
        }
        
        tx = SendTransaction(coin: coin)
        
        guard let tx else {
            return
        }
        
        if tx.coin.chain.name == Chain.Bitcoin.name {
            await utxoTransactionsService.fetchTransactions(tx.coin.address, endpointUrl: Endpoint.fetchBitcoinTransactions(tx.coin.address))
        } else if tx.coin.chain.name == Chain.Litecoin.name {
            await utxoTransactionsService.fetchTransactions(tx.coin.address, endpointUrl: Endpoint.fetchLitecoinTransactions(tx.coin.address))
        }
    }
    
    private func getErrorMessage(_ error: String) -> some View {
        VStack(spacing: 12) {
            ErrorMessage(text: "errorFetchingTransactions")
            Text(error)
        }
    }
    
    private func getList(for transactions: [UTXOTransactionMempool], tx: SendTransaction) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(transactions, id: \.txid) { transaction in
                    TransactionCell(transaction: transaction, tx: tx)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Background()
        UTXOTransactionsView(coin: Coin.example)
            .environmentObject(ApplicationState.shared)
    }
}

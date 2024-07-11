//
//  Solana.swift
//  VultisigApp
//

import Foundation
import Tss
import WalletCore
import BigInt

enum SolanaHelper {
    
    static let defaultFeeInLamports: BigInt = 1000000 //0.001
    
    static func getPreSignedInputData(keysignPayload: KeysignPayload) throws -> Data {
        guard keysignPayload.coin.chain.ticker == "SOL" else {
            throw HelperError.runtimeError("coin is not SOL")
        }
        guard case .Solana(let recentBlockHash, let priorityFee) = keysignPayload.chainSpecific else {
            throw HelperError.runtimeError("fail to get to address")
        }
        guard let toAddress = AnyAddress(string: keysignPayload.toAddress, coin: .solana) else {
            throw HelperError.runtimeError("fail to get to address")
        }
        
        if keysignPayload.coin.isNativeToken {
            let input = SolanaSigningInput.with {
                $0.transferTransaction = SolanaTransfer.with {
                    $0.recipient = toAddress.description
                    $0.value = UInt64(keysignPayload.toAmount)
                    if let memo = keysignPayload.memo {
                        $0.memo = memo
                    }
                }
                $0.recentBlockhash = recentBlockHash
                $0.sender = keysignPayload.coin.address
                $0.priorityFeePrice = SolanaPriorityFeePrice.with {
                    $0.price = UInt64(priorityFee)
                }
            }
            return try input.serializedData()
        } else {
            
            print("Sender Address: \(keysignPayload.coin.address)")
            print("To Amount: \(keysignPayload.toAmount)")
            print("Decimals: \(keysignPayload.coin.decimals)")
            print("Token Mint Address: \(keysignPayload.coin.contractAddress)")
            print("To Address: \(toAddress.description)")
            
            //Sender PUB KEY: FcYeo7FdKWQ4BS96g4ob4uzk2bdL882ZR4SLUfRW6dze
            // To PUB KEY: 5VtQfAZtPmtP3koCmmdsYPmgo6k2z3NabF7vwUor37k9
            
            let fromPubKey = "FcYeo7FdKWQ4BS96g4ob4uzk2bdL882ZR4SLUfRW6dze"
            let toPubKey = "5VtQfAZtPmtP3koCmmdsYPmgo6k2z3NabF7vwUor37k9"
            
            let tokenTransferMessage = SolanaTokenTransfer.with {
                $0.tokenMintAddress = keysignPayload.coin.contractAddress
                $0.senderTokenAddress = fromPubKey
                $0.recipientTokenAddress = toPubKey
                $0.amount = UInt64(keysignPayload.toAmount)
                $0.decimals = UInt32(keysignPayload.coin.decimals)
            }
            
            let input = SolanaSigningInput.with {
                $0.tokenTransferTransaction = tokenTransferMessage
                $0.recentBlockhash = recentBlockHash
                $0.sender = keysignPayload.coin.address
                $0.priorityFeePrice = SolanaPriorityFeePrice.with {
                    $0.price = UInt64(priorityFee)
                }
            }
            
            return try input.serializedData()
            
        }
    }
    
    
    static func getPreSignedImageHash(keysignPayload: KeysignPayload) throws -> [String] {
        let inputData = try getPreSignedInputData(keysignPayload: keysignPayload)
        let hashes = TransactionCompiler.preImageHashes(coinType: .solana, txInputData: inputData)
        let preSigningOutput = try SolanaPreSigningOutput(serializedData: hashes)
        
        print(preSigningOutput.errorMessage)
        
        return [preSigningOutput.data.hexString]
    }
    
    static func getSignedTransaction(vaultHexPubKey: String,
                                     vaultHexChainCode: String,
                                     keysignPayload: KeysignPayload,
                                     signatures: [String: TssKeysignResponse]) throws -> SignedTransactionResult
    {
        guard let pubkeyData = Data(hexString: vaultHexPubKey) else {
            throw HelperError.runtimeError("public key \(vaultHexPubKey) is invalid")
        }
        guard let publicKey = PublicKey(data: pubkeyData, type: .ed25519) else {
            throw HelperError.runtimeError("public key \(vaultHexPubKey) is invalid")
        }
        
        let inputData = try getPreSignedInputData(keysignPayload: keysignPayload)
        let hashes = TransactionCompiler.preImageHashes(coinType: .solana, txInputData: inputData)
        let preSigningOutput = try SolanaPreSigningOutput(serializedData: hashes)
        let allSignatures = DataVector()
        let publicKeys = DataVector()
        let signatureProvider = SignatureProvider(signatures: signatures)
        let signature = signatureProvider.getSignature(preHash: preSigningOutput.data)
        guard publicKey.verify(signature: signature, message: preSigningOutput.data) else {
            throw HelperError.runtimeError("fail to verify signature")
        }
        
        allSignatures.add(data: signature)
        publicKeys.add(data: pubkeyData)
        let compileWithSignature = TransactionCompiler.compileWithSignatures(coinType: .solana,
                                                                             txInputData: inputData,
                                                                             signatures: allSignatures,
                                                                             publicKeys: publicKeys)
        let output = try SolanaSigningOutput(serializedData: compileWithSignature)
        let result = SignedTransactionResult(rawTransaction: output.encoded,
                                             transactionHash: getHashFromRawTransaction(tx:output.encoded))
        return result
    }
    
    static func getHashFromRawTransaction(tx: String) -> String {
        let sig =  Data(tx.prefix(64).utf8)
        return sig.base64EncodedString()
    }
}

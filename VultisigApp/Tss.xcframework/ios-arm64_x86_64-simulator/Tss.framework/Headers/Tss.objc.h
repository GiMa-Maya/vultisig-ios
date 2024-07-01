// Objective-C API for talking to github.com/vultisig/mobile-tss-lib/tss Go package.
//   gobind -lang=objc github.com/vultisig/mobile-tss-lib/tss
//
// File is generated by gobind. Do not edit.

#ifndef __Tss_H__
#define __Tss_H__

@import Foundation;
#include "ref.h"
#include "Universe.objc.h"


@class TssKeygenRequest;
@class TssKeygenResponse;
@class TssKeysignRequest;
@class TssKeysignResponse;
@class TssLocalState;
@class TssMessageFromTss;
@class TssReshareRequest;
@class TssReshareResponse;
@class TssServiceImpl;
@protocol TssLocalStateAccessor;
@class TssLocalStateAccessor;
@protocol TssMessenger;
@class TssMessenger;
@protocol TssService;
@class TssService;

@protocol TssLocalStateAccessor <NSObject>
- (NSString* _Nonnull)getLocalState:(NSString* _Nullable)pubKey error:(NSError* _Nullable* _Nullable)error;
- (BOOL)saveLocalState:(NSString* _Nullable)pubkey localState:(NSString* _Nullable)localState error:(NSError* _Nullable* _Nullable)error;
@end

@protocol TssMessenger <NSObject>
- (BOOL)send:(NSString* _Nullable)from to:(NSString* _Nullable)to body:(NSString* _Nullable)body error:(NSError* _Nullable* _Nullable)error;
@end

@protocol TssService <NSObject>
/**
 * ApplyData applies the keygen data to the service
 */
- (BOOL)applyData:(NSString* _Nullable)p0 error:(NSError* _Nullable* _Nullable)error;
/**
 * KeygenECDSA generates a new ECDSA keypair
 */
- (TssKeygenResponse* _Nullable)keygenECDSA:(TssKeygenRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
/**
 * KeygenEDDSA generates a new EDDSA keypair
 */
- (TssKeygenResponse* _Nullable)keygenEdDSA:(TssKeygenRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
/**
 * KeysignECDSA signs a message using ECDSA
 */
- (TssKeysignResponse* _Nullable)keysignECDSA:(TssKeysignRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
/**
 * KeysignEDDSA signs a message using EDDSA
 */
- (TssKeysignResponse* _Nullable)keysignEdDSA:(TssKeysignRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
@end

@interface TssKeygenRequest : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
@property (nonatomic) NSString* _Nonnull localPartyID;
@property (nonatomic) NSString* _Nonnull allParties;
@property (nonatomic) NSString* _Nonnull chainCodeHex;
// skipped method KeygenRequest.GetAllParties with unsupported parameter or return types

@end

@interface TssKeygenResponse : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
@property (nonatomic) NSString* _Nonnull pubKey;
@end

@interface TssKeysignRequest : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
@property (nonatomic) NSString* _Nonnull pubKey;
@property (nonatomic) NSString* _Nonnull messageToSign;
@property (nonatomic) NSString* _Nonnull keysignCommitteeKeys;
@property (nonatomic) NSString* _Nonnull localPartyKey;
@property (nonatomic) NSString* _Nonnull derivePath;
// skipped method KeysignRequest.GetKeysignCommitteeKeys with unsupported parameter or return types

@end

@interface TssKeysignResponse : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
@property (nonatomic) NSString* _Nonnull msg;
@property (nonatomic) NSString* _Nonnull r;
@property (nonatomic) NSString* _Nonnull s;
@property (nonatomic) NSString* _Nonnull derSignature;
@property (nonatomic) NSString* _Nonnull recoveryID;
@end

/**
 * LocalState represent the information that will be saved locally
 */
@interface TssLocalState : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
@property (nonatomic) NSString* _Nonnull pubKey;
// skipped field LocalState.ECDSALocalData with unsupported type: github.com/bnb-chain/tss-lib/v2/ecdsa/keygen.LocalPartySaveData

// skipped field LocalState.EDDSALocalData with unsupported type: github.com/bnb-chain/tss-lib/v2/eddsa/keygen.LocalPartySaveData

// skipped field LocalState.KeygenCommitteeKeys with unsupported type: []string

@property (nonatomic) NSString* _Nonnull localPartyKey;
@property (nonatomic) NSString* _Nonnull chainCodeHex;
@property (nonatomic) NSString* _Nonnull resharePrefix;
@end

@interface TssMessageFromTss : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
@property (nonatomic) NSData* _Nullable wireBytes;
@property (nonatomic) NSString* _Nonnull from;
@property (nonatomic) NSString* _Nonnull to;
@property (nonatomic) BOOL isBroadcast;
@end

/**
 * ReshareRequest is used to request a reshare
 */
@interface TssReshareRequest : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
@property (nonatomic) NSString* _Nonnull pubKey;
@property (nonatomic) NSString* _Nonnull localPartyID;
@property (nonatomic) NSString* _Nonnull newParties;
@property (nonatomic) NSString* _Nonnull chainCodeHex;
@property (nonatomic) NSString* _Nonnull oldParties;
@property (nonatomic) NSString* _Nonnull resharePrefix;
@property (nonatomic) NSString* _Nonnull newResharePrefix;
// skipped method ReshareRequest.GetNewParties with unsupported parameter or return types

// skipped method ReshareRequest.GetOldParties with unsupported parameter or return types

@end

@interface TssReshareResponse : NSObject <goSeqRefInterface> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
@property (nonatomic) NSString* _Nonnull pubKey;
@property (nonatomic) NSString* _Nonnull resharePrefix;
@end

@interface TssServiceImpl : NSObject <goSeqRefInterface, TssService> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (nonnull instancetype)init;
/**
 * ApplyData accept the data from other peers , usually the communication is coordinate by the library user
 */
- (BOOL)applyData:(NSString* _Nullable)msg error:(NSError* _Nullable* _Nullable)error;
- (TssKeygenResponse* _Nullable)keygenECDSA:(TssKeygenRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
- (TssKeygenResponse* _Nullable)keygenEdDSA:(TssKeygenRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
- (TssKeysignResponse* _Nullable)keysignECDSA:(TssKeysignRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
- (TssKeysignResponse* _Nullable)keysignEdDSA:(TssKeysignRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
- (TssReshareResponse* _Nullable)reshareECDSA:(TssReshareRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
- (TssReshareResponse* _Nullable)resharingEdDSA:(TssReshareRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
@end

// skipped const MaxUint32 with unsupported type: uint32


// skipped function Contains with unsupported parameter or return types


// skipped function GetDERSignature with unsupported parameter or return types


// skipped function GetDerivePathBytes with unsupported parameter or return types


FOUNDATION_EXPORT NSString* _Nonnull TssGetDerivedPubKey(NSString* _Nullable hexPubKey, NSString* _Nullable hexChainCode, NSString* _Nullable path, BOOL isEdDSA, NSError* _Nullable* _Nullable error);

// skipped function GetHexEncodedPubKey with unsupported parameter or return types


/**
 * GetThreshold calculates the threshold value based on the input value.
It takes an integer value as input and returns the threshold value and an error.
If the input value is negative, it returns an error with the message "invalid input".
 */
FOUNDATION_EXPORT BOOL TssGetThreshold(long value, long* _Nullable ret0_, NSError* _Nullable* _Nullable error);

// skipped function HashToInt with unsupported parameter or return types


/**
 * NewService returns a new instance of the TSS service
 */
FOUNDATION_EXPORT TssServiceImpl* _Nullable TssNewService(id<TssMessenger> _Nullable msg, id<TssLocalStateAccessor> _Nullable stateAccessor, BOOL createPreParam, NSError* _Nullable* _Nullable error);

@class TssLocalStateAccessor;

@class TssMessenger;

@class TssService;

@interface TssLocalStateAccessor : NSObject <goSeqRefInterface, TssLocalStateAccessor> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (NSString* _Nonnull)getLocalState:(NSString* _Nullable)pubKey error:(NSError* _Nullable* _Nullable)error;
- (BOOL)saveLocalState:(NSString* _Nullable)pubkey localState:(NSString* _Nullable)localState error:(NSError* _Nullable* _Nullable)error;
@end

@interface TssMessenger : NSObject <goSeqRefInterface, TssMessenger> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
- (BOOL)send:(NSString* _Nullable)from to:(NSString* _Nullable)to body:(NSString* _Nullable)body error:(NSError* _Nullable* _Nullable)error;
@end

@interface TssService : NSObject <goSeqRefInterface, TssService> {
}
@property(strong, readonly) _Nonnull id _ref;

- (nonnull instancetype)initWithRef:(_Nonnull id)ref;
/**
 * ApplyData applies the keygen data to the service
 */
- (BOOL)applyData:(NSString* _Nullable)p0 error:(NSError* _Nullable* _Nullable)error;
/**
 * KeygenECDSA generates a new ECDSA keypair
 */
- (TssKeygenResponse* _Nullable)keygenECDSA:(TssKeygenRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
/**
 * KeygenEDDSA generates a new EDDSA keypair
 */
- (TssKeygenResponse* _Nullable)keygenEdDSA:(TssKeygenRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
/**
 * KeysignECDSA signs a message using ECDSA
 */
- (TssKeysignResponse* _Nullable)keysignECDSA:(TssKeysignRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
/**
 * KeysignEDDSA signs a message using EDDSA
 */
- (TssKeysignResponse* _Nullable)keysignEdDSA:(TssKeysignRequest* _Nullable)req error:(NSError* _Nullable* _Nullable)error;
@end

#endif
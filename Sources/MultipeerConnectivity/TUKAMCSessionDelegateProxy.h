//
//  TUKAMCSessionDelegateProxy.h
//  Tuka
//
//  Created by Jun Tanaka on 2017/04/06.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>

/**
 This protocol is a workaround for an incorrect ObjC-Swift bridging of MCSessionDelegate.

 The original `session(_:​did​Finish​Receiving​Resource​With​Name:​from​Peer:​at:​with​Error:​)`
 will pass **nil** as `localURL` when the operation was cancelled, but the variable
 is labeled as `nonnull` :(
 
 See this StackOverflow post for more details:
 https://stackoverflow.com/questions/42477025/
 */
@protocol TUKAMCSessionDelegate <NSObject>

- (void)session:(nonnull MCSession *)session peer:(nonnull MCPeerID *)peerID didChangeState:(MCSessionState)state;
- (void)session:(nonnull MCSession *)session didReceiveData:(nonnull NSData *)data fromPeer:(nonnull MCPeerID *)peerID;
- (void)session:(nonnull MCSession *)session didReceiveStream:(nonnull NSInputStream *)stream withName:(nonnull NSString *)streamName fromPeer:(nonnull MCPeerID *)peerID;
- (void)session:(nonnull MCSession *)session didStartReceivingResourceWithName:(nonnull NSString *)resourceName fromPeer:(nonnull MCPeerID *)peerID withProgress:(nonnull NSProgress *)progress;
- (void)session:(nonnull MCSession *)session didFinishReceivingResourceWithName:(nonnull NSString *)resourceName fromPeer:(nonnull MCPeerID *)peerID atURL:(nullable NSURL *)localURL withError:(nullable NSError *)error;

@optional
- (void)session:(nonnull MCSession *)session didReceiveCertificate:(nullable NSArray *)certificate fromPeer:(nonnull MCPeerID *)peerID certificateHandler:(nonnull void (^)(BOOL accept))certificateHandler;

@end

@interface TUKAMCSessionDelegateProxy: NSObject<MCSessionDelegate>

@property (nonatomic, weak, nullable) id<TUKAMCSessionDelegate> delegte;

@end

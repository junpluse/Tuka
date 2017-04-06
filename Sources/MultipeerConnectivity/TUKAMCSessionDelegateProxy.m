//
//  TUKASessionDelegateProxy.m
//  Tuka
//
//  Created by Jun Tanaka on 2017/04/06.
//  Copyright © 2017 Jun Tanaka. All rights reserved.
//

#import "TUKAMCSessionDelegateProxy.h"

@implementation TUKAMCSessionDelegateProxy

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    [_delegte session:session peer:peerID didChangeState:state];
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    [_delegte session:session didReceiveData:data fromPeer:peerID];
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    [_delegte session:session didReceiveStream:stream withName:streamName fromPeer:peerID];
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    [_delegte session:session didStartReceivingResourceWithName:resourceName fromPeer:peerID withProgress:progress];
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    [_delegte session:session didFinishReceivingResourceWithName:resourceName fromPeer:peerID atURL:localURL withError:error];
}

- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL))certificateHandler {
    if ([_delegte respondsToSelector:@selector(session:didReceiveCertificate:fromPeer:certificateHandler:)]) {
        [_delegte session:session didReceiveCertificate:certificate fromPeer:peerID certificateHandler:certificateHandler];
    }
}

@end

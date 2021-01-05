//
//  GameScene.h
//  spritekit
//
//  Created by HidehikoKondo on 2016/09/16.
//  Copyright © 2016年 UDONKOAPPS. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameScene : SKScene<SKPhysicsContactDelegate>

- (void)statusCheck:(NSTimer*)timer;
- (void)blinkDetection:(NSTimer*)timer;
- (void)stopAllBGM;
- (void)playStatusBGM;
- (void)closeDebugMenu;
- (void)invalidateTimer;

@end


//
//  AppDelegate.h
//  spritekit
//
//  Created by HidehikoKondo on 2016/09/16.
//  Copyright © 2016年 UDONKOAPPS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MEMELib/MEMELib.h>

//瞬きのステータス
#define NORMAL @"normal"
#define CAUTION @"caution"
#define DANGER @"danger"

//閾値
#define BLINKCOUNTLIMIT 15
#define DANGERTIMELIMIT 1800
#define STATUSCHECKINTERVAL 60.0f
#define TUTORIALLOOPINTERVAL 85.0f
#define TUTORIALEATINTERVAL 2.1f
#define TUTORIALINTERVAL 7.4f

@interface AppDelegate : UIResponder <UIApplicationDelegate,MEMELibDelegate>
@property (strong, nonatomic) UIWindow *window;

//MEMEから取得した値たちをDelegateで持っておく。
//で、GameSceneから呼び出して使うとかそういう風にしたい。
@property (strong ,nonatomic) MEMERealTimeData *memeValue;
@property (nonatomic ,strong) NSMutableDictionary *blinkStatus;
@property BOOL isTutorial;


@end


//
//  GameScene.m
//  spritekit
//
//  Created by HidehikoKondo on 2016/09/16.
//  Copyright © 2016年 UDONKOAPPS. All rights reserved.
//

#import "GameScene.h"
#import "AppDelegate.h"
#import <AudioToolbox/AudioServices.h>

@implementation GameScene{
    //ノード
    SKSpriteNode *_pacman;
    SKSpriteNode *_ghost;
    SKSpriteNode *_cookieBig;
    SKSpriteNode *_cookieSmall;
    SKSpriteNode *_tronBig;
    SKSpriteNode *_tronSmall;
    SKSpriteNode *_statusBackground;
    SKSpriteNode *_statusSprite;
    SKSpriteNode *_battery;
    SKAudioNode *_bgmGhost;
    SKAudioNode *_bgmNormal;
    SKSpriteNode *_wall;
    SKSpriteNode *_tutorial;
    SKSpriteNode *_tutorialMessage;
    SKSpriteNode *_tutorialPacman;
    
    //変数宣言
    AppDelegate *appDelegete;
    NSString  *blinkValueBuffer;
    
    //CAUTION状態の経過時間
    float _elapsedTime;
    
    //ステータスチェックを呼び出すタイマー
    NSTimer *statusCheckTimer;
    
    //チュートリアル用
    BOOL isTutorial;
    
    //タイマー
    NSTimer *tutorialTimer1;
    NSTimer *tutorialTimer2;
    NSTimer *tutorialTimer3;
    NSTimer *tutorialTimer4;
    NSTimer *tutorialTimer5;
    NSTimer *tutorialTimer6;
    NSTimer *tutorialTimer7;
    NSTimer *tutorialTimer8;
    
    
    //自動パクパク
    NSTimer *tutorialEatTimer;
    //チュートリアルの無限ループ
    NSTimer *tutorialLoopTimer;
    
    
    /**
     デバッグ用
     */
    //いらない
    SKLabelNode *_label;
    //瞬きのステータス、回数、経過時間表示
    SKLabelNode *_statusLabel;
    //※強さ
    SKLabelNode *_statusBlinkStrengthLabel;
    //※スピード
    SKLabelNode *_statusBlinkSpeedLabel;
    //※装着エラー
    SKLabelNode *_statusFitErrorLabel;
    //*背景
    SKSpriteNode *_statusAreaNode;
    //statusCheckを実行した回数
    int checkCount;
}


#pragma mark シーン関連
/**
 トップに戻る時によばれる
 */
- (void)willMoveFromView:(SKView *)view{
    
}

/**
 sceneロード時に呼ばれる
 */
- (void)didMoveToView:(SKView *)view {
    /**
     変数初期化
     */
    //デバッグ用
    checkCount = 0;
    
    //衝突判定のデリゲート
    self.physicsWorld.contactDelegate = self;
    
    //経過時間の初期化
    _elapsedTime = 0.0f;
    
    //memeValueをNSStringに変換した値。同じ値を連続取得しないようにする判定用バッファ。
    blinkValueBuffer = @"";
    
    //ステータスを初期値に戻す
    appDelegete =  (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegete.blinkStatus setObject:NORMAL forKey:@"status"];
    [appDelegete.blinkStatus setObject:[NSNumber numberWithInt:16] forKey:@"blinkcount"];
    [appDelegete.blinkStatus setObject:[NSDate date] forKey:@"cautiondatetime"];
    
    //チュートリアルフラグ
    isTutorial = appDelegete.isTutorial;
    
    /**
     各種ノードの初期設定
     GameScene.sksで配置したオブジェクトとコードの紐付け
     */
    _pacman = (SKSpriteNode *)[self childNodeWithName:@"//pacman"];
    [_pacman runAction:[SKAction actionNamed:@"PacmanDefault"] withKey:@"PacmanDefault"];
    _ghost = (SKSpriteNode *)[self childNodeWithName:@"//ghost"];
    [_ghost runAction:[SKAction actionNamed:@"GhostDefault"] withKey:@"GhostDefault"];
    [_ghost runAction:[SKAction actionNamed:@"GhostNormalTexture"]];
    _cookieBig = (SKSpriteNode *)[self childNodeWithName:@"//cookieBig"];
    _cookieSmall = (SKSpriteNode *)[self childNodeWithName:@"//cookieSmall"];
    _tronBig = (SKSpriteNode *)[self childNodeWithName:@"//tronBig"];
    _tronSmall = (SKSpriteNode *)[self childNodeWithName:@"//tronSmall"];
    _statusBackground = (SKSpriteNode *)[self childNodeWithName:@"//statusBackground"];
    _statusSprite = (SKSpriteNode *)[self childNodeWithName:@"//statusSprite"];
    _wall = (SKSpriteNode *)[self childNodeWithName:@"//wall"];
    _battery = (SKSpriteNode *)[self childNodeWithName:@"//battery"];
    _statusLabel = (SKLabelNode *)[self childNodeWithName:@"//statusLabel"];
    _statusBlinkStrengthLabel = (SKLabelNode *)[self childNodeWithName:@"//statusBlinkStrengthLabel"];
    _statusBlinkSpeedLabel = (SKLabelNode *)[self childNodeWithName:@"//statusBlinkSpeedLabel"];
    _statusFitErrorLabel = (SKLabelNode *)[self childNodeWithName:@"//statusFitErrorLabel"];
    _statusAreaNode = (SKSpriteNode *)[self childNodeWithName:@"//statusAreaNode"];
    _bgmGhost = [[SKAudioNode alloc ]initWithFileNamed:@"pac_se_ghost_turn2blue.mp3"];
    [_bgmGhost setAutoplayLooped:YES];
    _bgmNormal = [[SKAudioNode alloc ]initWithFileNamed:@"pac_se_ghost_movesound.mp3"];
    [_bgmNormal setAutoplayLooped:YES];
    
    //ノーマルBGM再生
    if(!isTutorial){
        [self playBGM:_bgmNormal];
    }
    
    
    [tutorialLoopTimer invalidate];
    tutorialLoopTimer = nil;
    
    
    //ステータスチェックのタイマー（１分毎）
    statusCheckTimer = [NSTimer scheduledTimerWithTimeInterval: STATUSCHECKINTERVAL
                                                        target: self
                                                      selector: @selector(statusCheck:)
                                                      userInfo: nil
                                                       repeats: YES];
    
    //設定によりデバッグメニューの表示を切り替え
    NSUserDefaults *settingUD = [NSUserDefaults standardUserDefaults];
    if([settingUD boolForKey:@"DEBUGMODE"]){
        [_statusAreaNode setHidden:NO];
    }else{
        [_statusAreaNode setHidden:YES];
    }
    
    //背景スクロール
    [self wallScroll:NO];
    
    //バッテリー残量表示
    [self batteryLeft];
    
    
    
    //以下、チュートリアル関連
    
    
    //画像
    _tutorial = (SKSpriteNode*)[self childNodeWithName:@"//tutorial"];
    _tutorialMessage = (SKSpriteNode*)[self childNodeWithName:@"//tutorialmessage"];
    _tutorialPacman = (SKSpriteNode*)[self childNodeWithName:@"//pacmantutorial"];
    [_tutorial setHidden:YES];
    
    // 通知設定
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(statusChangeNormal) name:NORMAL object:nil];
    [nc addObserver:self selector:@selector(statusChangeCaution) name:CAUTION object:nil];
    [nc addObserver:self selector:@selector(statusChangeDanger) name:DANGER object:nil];
    
    // 通知、タイマー実行（仮実装）
    if(isTutorial) {
        //チュートリアル画像
        [_tutorial setHidden:NO];
        
        //通知
        //        NSNotification *n = [NSNotification notificationWithName:CAUTION object:self];
        //        [[NSNotificationCenter defaultCenter] postNotification:n];
        
        //タイマー
        tutorialLoopTimer = [NSTimer scheduledTimerWithTimeInterval: TUTORIALLOOPINTERVAL
                                                             target: self
                                                           selector: @selector(tutorialLoop)
                                                           userInfo: nil
                                                            repeats: YES];
        [tutorialLoopTimer fire];
        
        
    }
}


# pragma mark update処理
-(void)update:(CFTimeInterval)currentTime {
    //まばたき検出
    if ((appDelegete.memeValue.blinkStrength != 0) && (![blinkValueBuffer isEqualToString: [appDelegete.memeValue description]]))
    {
        [self blinkDetection:nil];
    }
    //今回のフレームでのmemeValueの値を保持
    blinkValueBuffer = [appDelegete.memeValue description];
    
    //ステータスラベル更新
    [self statusLabelUpdate];
}

# pragma mark - チュートリアル
//チュートリアルの無限ループ用
-(void)tutorialLoop{
    NSLog(@"ループ");
    
    //dispatch_afterを使って遅延させる
     tutorialTimer1 = [NSTimer scheduledTimerWithTimeInterval: 0.0f
                                                        target: self
                                                      selector: @selector(tutorial1About)
                                                      userInfo: nil
                                                       repeats: NO];
    tutorialTimer2 = [NSTimer scheduledTimerWithTimeInterval: 10.0f
                                                      target: self
                                                    selector: @selector(tutorial2Connect)
                                                    userInfo: nil
                                                     repeats: NO];
    tutorialTimer3 = [NSTimer scheduledTimerWithTimeInterval: 20.0f
                                                      target: self
                                                    selector: @selector(tutorial3Eat)
                                                    userInfo: nil
                                                     repeats: NO];
    tutorialTimer4 = [NSTimer scheduledTimerWithTimeInterval: 30.0f
                                                      target: self
                                                    selector: @selector(tutorial4Normal)
                                                    userInfo: nil
                                                     repeats: NO];
    tutorialTimer5 = [NSTimer scheduledTimerWithTimeInterval: 40.0f
                                                      target: self
                                                    selector: @selector(tutorial5Caution)
                                                    userInfo: nil
                                                     repeats: NO];
    tutorialTimer6 = [NSTimer scheduledTimerWithTimeInterval: 50.0f
                                                      target: self
                                                    selector: @selector(tutorial6Danger)
                                                    userInfo: nil
                                                     repeats: NO];
    tutorialTimer7 = [NSTimer scheduledTimerWithTimeInterval: 60.0f
                                                      target: self
                                                    selector: @selector(tutorial7Health)
                                                    userInfo: nil
                                                     repeats: NO];
    tutorialTimer8 = [NSTimer scheduledTimerWithTimeInterval: 70.0f
                                                      target: self
                                                    selector: @selector(tutorial8Credit)
                                                    userInfo: nil
                                                     repeats: NO];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [self tutorial1About];
//    });
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [self tutorial2Connect];
//    });
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 20.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [self tutorial3Eat];
//    });
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [self tutorial4Normal];
//    });
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 40.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [self tutorial5Caution];
//    });
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 50.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [self tutorial6Danger];
//    });
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 60.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [self tutorial7Health];
//    });
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 70.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        [self tutorial8Credit];
//    });
}

//こんなアプリだよ
-(void)tutorial1About{
    NSLog(@"こんなアプリだよ tutorial1About");
    [self changeTutorialBackground:[SKTexture textureWithImageNamed:@"tutorial1background.png"] messtexture:[SKTexture textureWithImageNamed:@"tutorial1message.png"]];
    [_tutorialPacman setHidden:NO];
}
//接続しましょう
-(void)tutorial2Connect{
    NSLog(@"接続しましょう　tutorial2Connect");
    [self changeTutorialBackground:[SKTexture textureWithImageNamed:@"tutorial2background.png"] messtexture:[SKTexture textureWithImageNamed:@"tutorial2message.png"]];
    
}
//瞬きでパクパク
-(void)tutorial3Eat{
    NSLog(@"瞬きでパクパク　tutorial3Eat");
    [self changeTutorialBackground:[SKTexture textureWithImageNamed:@"tutorial3background.png"] messtexture:[SKTexture textureWithImageNamed:@"tutorial3message.png"]];
    
    //通知
    //    NSNotification *n = [NSNotification notificationWithName:NORMAL object:self];
    //    [[NSNotificationCenter defaultCenter] postNotification:n];
    
    [self statusChangeNormal];
    
    //パクパク開始
    tutorialEatTimer = [NSTimer scheduledTimerWithTimeInterval: TUTORIALEATINTERVAL
                                                        target: self
                                                      selector: @selector(blinkDetection:)
                                                      userInfo: nil
                                                       repeats: YES];
    [tutorialEatTimer fire];
}
//正常
-(void)tutorial4Normal{
    NSLog(@"正常　tutorial4Normal");
    [self changeTutorialBackground:[SKTexture textureWithImageNamed:@"tutorial4background.png"] messtexture:[SKTexture textureWithImageNamed:@"tutorial4message.png"]];
    
}
//注意
-(void)tutorial5Caution{
    NSLog(@"注意　tutorial5Caution");
    [self changeTutorialBackground:[SKTexture textureWithImageNamed:@"tutorial5background.png"] messtexture:[SKTexture textureWithImageNamed:@"tutorial5message.png"]];
    //    NSNotification *n = [NSNotification notificationWithName:CAUTION object:self];
    //    [[NSNotificationCenter defaultCenter] postNotification:n];
    
    [self statusChangeCaution];
    
}

-(void)tutorial6Danger{
    NSLog(@"回復　tutorial6CautionToNormal");
    [self changeTutorialBackground:[SKTexture textureWithImageNamed:@"tutorial6background.png"] messtexture:[SKTexture textureWithImageNamed:@"tutorial6message.png"]];
    //    NSNotification *n = [NSNotification notificationWithName:DANGER object:self];
    //    [[NSNotificationCenter defaultCenter] postNotification:n];
    
    [self statusChangeDanger];
    
    
    //ぱくぱく停止
    [tutorialEatTimer invalidate];
}
//危険
-(void)tutorial7Health{
    NSLog(@"危険　tutorial7Danger");
    [self changeTutorialBackground:[SKTexture textureWithImageNamed:@"tutorial7background.png"] messtexture:[SKTexture textureWithImageNamed:@"tutorial7message.png"]];
    
    
    //ゴーストとパックマンをnormal状態に復帰
    [self normalAnimation];
    [_pacman runAction:[SKAction actionNamed:@"eat"]];
    [_pacman setAlpha:1.0f];
    
}
//健康に気をつけましょう
-(void)tutorial8Credit{
    NSLog(@"健康に気をつけましょう　tutorial8Health");
    [self changeTutorialBackground:[SKTexture textureWithImageNamed:@"tutorial8background.png"] messtexture:[SKTexture textureWithImageNamed:@"tutorial8message.png"]];
    [_tutorialPacman setHidden:YES];
    
    
}

//チュートリアルの変更
-(void)changeTutorialBackground:(SKTexture*)bgtexture messtexture:(SKTexture*)messtexture{
    //背景
    [_tutorial setTexture:bgtexture];
    
    //メッセージ
    [_tutorialMessage runAction:[SKAction actionNamed:@"closeTutorialMessage"] completion:^{
        [_tutorialMessage setTexture:messtexture];
        [_tutorialMessage runAction:[SKAction actionNamed:@"openTutorialMessage"]];
    }];
}

# pragma mark - 警告のステータスのチェック
/**
 [警告ロジック]
 １分ごとにチェックをする
 ★チェック内容
	瞬き回数が１５回以上の場合
 ・瞬き回数をクリア
 ・状態をNORMALに変更
 ・状態がCAUTIONになった時刻をクリア（めっちゃ未来の日時を設定しておく むりやりw）
	瞬き回数が14回以下の場合
 ・瞬き回数をクリア
 ・状態をCAUTIONに変更
 ・状態がCAUTIONになった時刻を保存
	CAUTIONになった時刻からの経過時間が30分を超えた場合
 ・状態をDANGERに変更
 */
- (void)statusCheck:(NSTimer*)timer{
    if(isTutorial){
        return;
    }
    
    //デバッグ用
    checkCount++;
    
    NSLog(@"%@",[appDelegete.blinkStatus objectForKey:@"status"]);
    NSLog(@"%@",[appDelegete.blinkStatus objectForKey:@"blinkcount"]);
    NSLog(@"%@",[appDelegete.blinkStatus objectForKey:@"cautiondatetime"]);
    
    if([[appDelegete.blinkStatus objectForKey:@"blinkcount"] intValue] >= BLINKCOUNTLIMIT){
        [self statusChangeNormal];
        
    }else if([[appDelegete.blinkStatus objectForKey:@"blinkcount"] intValue] < BLINKCOUNTLIMIT){
        [self statusChangeCaution];
    }
    
    //CAUTION状態が３０分超えた場合
    NSDate *cautiondatetime = [appDelegete.blinkStatus objectForKey:@"cautiondatetime"];
    // [NSDate date]からcautiondatetimeを引いて差分を取得
    //（NORMALの場合はめっちゃ未来の日付になってるのでマイナスになる
    _elapsedTime = [[NSDate date] timeIntervalSinceDate: cautiondatetime];
    NSLog(@"%f",_elapsedTime);
    
    //DANGERの判定 （デバッグモード時は10秒）
    float time = 0.0f;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DEBUGMODE"]){
        time = 10.0f;
    }else{
        time = DANGERTIMELIMIT;
    }
    
    if(_elapsedTime > time){
        [self statusChangeDanger];
    }else{
        NSLog(@"まだ大丈夫");
    }
    
    //ステータス表示のアニメーション
    [_statusSprite setScale:3.0f];
    [_statusSprite setAlpha:0.0f];
    [_statusSprite runAction:[SKAction actionNamed:@"statusChange"]];
    
    //バッテリー残量表示
    [self batteryLeft];
}


- (void)statusChangeNormal{
    NSLog(@"ステータス：NORMAL");
    
    //CAUTION->NORMALアニメーション
    if([[appDelegete.blinkStatus objectForKey:@"status"] isEqualToString:CAUTION]){
        [self normalAnimation];
        [self wallScroll:NO];
        [_statusSprite removeActionForKey:@"statusFlashLoop"];
    }
    
    //瞬き回数をクリア
    [appDelegete.blinkStatus setObject:[NSNumber numberWithInt:0] forKey:@"blinkcount"];
    //ステータスをNORMALに変更
    [appDelegete.blinkStatus setObject:NORMAL forKey:@"status"];
    //CAUTIONになった時刻をクリア
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
    NSDate *futureDate = [dateFormatter dateFromString:@"2030/10/10 00:00:00"];
    [appDelegete.blinkStatus setObject:futureDate forKey:@"cautiondatetime"];
    
    //CAUTION表示
    [_statusBackground setTexture: [SKTexture textureWithImageNamed:@"background_normal.png"]];
    [_statusSprite setTexture: [SKTexture textureWithImageNamed:@"status_normal.png"]];
    
    
    //BGMを消す
    [self stopBGM:_bgmGhost];
    //[self stopBGM:_bgmNormal];
    
    //BGMを再生する
    [self playBGM:_bgmNormal];
}

- (void)statusChangeCaution{
    NSLog(@"ステータス：CAUTION");
    //CAUTIONになった時刻を保存(NORMAL->CAUTIONに変わった時だけ)
    if([[appDelegete.blinkStatus objectForKey:@"status"] isEqualToString:NORMAL]){
        [appDelegete.blinkStatus setObject:[NSDate date] forKey:@"cautiondatetime"];
        //大きいクッキー
        [self bigCookieArrival];
        [self wallScroll:YES];
        [_statusSprite runAction:[SKAction actionNamed:@"statusFlashLoop"] withKey:@"statusFlashLoop"];
    }
    //CAUTIONに変更
    [appDelegete.blinkStatus setObject:CAUTION forKey:@"status"];
    //瞬き回数をクリア
    [appDelegete.blinkStatus setObject:[NSNumber numberWithInt:0] forKey:@"blinkcount"];
    
    //CAUTION表示
    [_statusBackground setTexture: [SKTexture textureWithImageNamed:@"background_caution.png"]];
    [_statusSprite setTexture: [SKTexture textureWithImageNamed:@"status_caution.png"]];
}

- (void)statusChangeDanger{
    NSLog(@"デンジャー！！");
    [appDelegete.blinkStatus setObject:DANGER forKey:@"status"];
    //ここで「休憩しましょう」メッセージ出して強制終了。
    //DANGER表示
    [_statusBackground setTexture: [SKTexture textureWithImageNamed:@"background_danger.png"]];
    [_statusSprite setTexture: [SKTexture textureWithImageNamed:@"status_danger.png"]];
    [_statusSprite runAction:[SKAction actionNamed:@"statusFlashLoop"] withKey:@"statusFlashLoop"];
    
    //死亡アニメーション
    [_pacman setXScale:1];
    [_pacman runAction:[SKAction actionNamed:@"PacmanDead"]];
    
    
    [NSTimer scheduledTimerWithTimeInterval:0.7f target:[NSBlockOperation blockOperationWithBlock:^{
        [_pacman removeActionForKey:@"PacmanDefault"];
        [_pacman removeActionForKey:@"PacmanAttack"];
    }] selector:@selector(main) userInfo:nil repeats:NO];
    
    [_ghost runAction:[SKAction actionNamed:@"GhostAttack"]];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self stopBGM: _bgmGhost];
        [self stopBGM: _bgmNormal];
    });
    
    //バイブレーション
    if(!isTutorial){
        NSTimer *vibeTimer = [NSTimer scheduledTimerWithTimeInterval:0.6f target:[NSBlockOperation blockOperationWithBlock:^{
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }] selector:@selector(main) userInfo:nil repeats:YES];
        [NSTimer scheduledTimerWithTimeInterval:6.0f target:[NSBlockOperation blockOperationWithBlock:^{
            [vibeTimer invalidate];
        }] selector:@selector(main) userInfo:nil repeats:NO];
    }
    
    //ステータスチェックのタイマーを停止
    [statusCheckTimer invalidate];
}

# pragma mark デバッグ用
- (void)statusLabelUpdate{
    //ステータスラベル更新
    if(_elapsedTime < 0){
        _elapsedTime = 0;
    }
    
    /*
     {seqNo = 64; accZ = -15; accY = 4; accX = -1; yaw = 349.29; pitch = 16.9; roll = -1.59; blinkStrength = 0; blinkSpeed = 0; eyeMoveRight = 0; eyeMoveLeft = 0; eyeMoveDown = 0; eyeMoveUp = 0; powerLeft = 5; isWalking = 0; fitError = 0; }
     */
    
    NSString *text = [NSString stringWithFormat:@"status:%@ 瞬き:%@ caution時間:%.1f \nstatusCheck回数:%d",
                      [appDelegete.blinkStatus objectForKey:@"status"],
                      [appDelegete.blinkStatus objectForKey:@"blinkcount"],
                      _elapsedTime,
                      checkCount                      ];
    [_statusLabel setText:text];
    
    //ラベル更新
    if (appDelegete.memeValue.blinkStrength != 0){
        [_statusBlinkStrengthLabel setText:[NSString stringWithFormat:@"瞬き強度:%d",appDelegete.memeValue.blinkStrength ]];
    }
    if (appDelegete.memeValue.blinkSpeed != 0){
        [_statusBlinkSpeedLabel setText:[NSString stringWithFormat:@"瞬き速度:%d",appDelegete.memeValue.blinkSpeed]];
    }
    [_statusFitErrorLabel setText:[NSString stringWithFormat:@"フィットエラー:%d",appDelegete.memeValue.fitError]];
}

- (void)closeDebugMenu{
    [_statusAreaNode setHidden:YES];
}

# pragma mark MEME関連
/**
 バッテリー残量表示
 */
- (void)batteryLeft{
    if(appDelegete.memeValue.powerLeft >5 || appDelegete.memeValue.powerLeft < 1){
        return;
    }
    NSString *textureName = [NSString stringWithFormat:@"battery%d.png",appDelegete.memeValue.powerLeft];
    [_battery setTexture:[SKTexture textureWithImageNamed:textureName]];
}

/**
 まばたき検出検出
 blinkStrengthが0でない かつ　前フレームと異なる値だったらまたば検出と判定
 （MEMEのデータ更新の頻度が1/5秒ごとで、瞬き検出が1/60秒のため連射されるからフレームごとでチェックする）
 */
- (void)blinkDetection:(NSTimer*)timer{
    //クッキー排出
    [self createCookieSmall];
    
    //背景の四角いやつ
    [self createTronBig];
    [self createTronSmall];
    
    //パックマン
    [self packmanEat];
    
    //瞬きの回数を更新
    NSNumber *number = [appDelegete.blinkStatus objectForKey:@"blinkcount"];
    int plus = ([number intValue] + 1);
    //plus = plus + 1;
    [appDelegete.blinkStatus setObject:[NSNumber numberWithInt: plus]forKey:@"blinkcount"];
}


# pragma mark パックマンアニメーション
- (void)packmanEat{
    // パックマンの食べるアニメーション
    [_pacman runAction:[SKAction actionNamed:@"eat"]];
}

# pragma mark ステータス遷移アニメーション
- (void)normalAnimation{
    //ゴーストの位置まで移動→しばらく止まって→左を向く→通常のアニメーションに戻す
    //[_pacman runAction:[SKAction rotateToAngle:0 duration:0]];
    [_pacman removeActionForKey:@"PacmanDefault"];
    [_pacman runAction:[SKAction actionNamed:@"PacmanAttack"] withKey:@"PacmanAttack"];
    [NSTimer scheduledTimerWithTimeInterval:1.5f target:[NSBlockOperation blockOperationWithBlock:^{
        [_pacman runAction:[SKAction actionNamed:@"PacmanDefault"] withKey:@"PacmanDefault"];
        _pacman.xScale = 1;
    }] selector:@selector(main) userInfo:nil repeats:NO];
    
    //ゴーストパックマンが衝突したらゴーストが死ぬアニメーションを再生する。
    [self ghostDead];
}

- (void)ghostDead{
    //ゴーストが食われる→目玉になる→逃げる→赤ゴーストに変身→帰ってくる
    [_ghost removeActionForKey:@"GhostDefault"];
    if(!isTutorial){
        [_ghost runAction:[SKAction actionNamed:@"GhostDead"]];
    }
    [NSTimer scheduledTimerWithTimeInterval:5.0f target:[NSBlockOperation blockOperationWithBlock:^{
        [_ghost runAction:[SKAction actionNamed:@"GhostDefault"] withKey:@"GhostDefault"];
        [_ghost runAction:[SKAction actionNamed:@"GhostNormalTexture"]];
    }] selector:@selector(main) userInfo:nil repeats:NO];
}

- (void)cautionAnimation{
    //食べれるゴーストに変身
    [_ghost runAction:[SKAction actionNamed:@"GhostCautionTexture"]];
    
    //パックマンを右向きにする
    //[_pacman runAction:[SKAction rotateToAngle:M_PI duration:0]];
    _pacman.xScale = -1;
}


# pragma mark クッキー関連
//クッキー（小）を配置する
- (void)createCookieSmall{
    SKSpriteNode *cookie = [_cookieSmall copy];
    //ステータスにより配置位置を逆にする
    if([[appDelegete.blinkStatus objectForKey:@"status"] isEqualToString:NORMAL]){
        cookie.position = CGPointMake(-160, 150);
        [cookie runAction:[SKAction actionNamed:@"cookieMove"] completion:^{
            [cookie removeFromParent];
        }];
        [self addChild:cookie];
    }else if([[appDelegete.blinkStatus objectForKey:@"status"] isEqualToString:CAUTION]){
        cookie.position = CGPointMake(160, 150);
        [cookie runAction:[SKAction actionNamed:@"cookieMove"] completion:^{
            [cookie removeFromParent];
        }];
        [self addChild:cookie];
    }else{
        //DANGERの時は排出しない
    }
}

//でかいクッキー登場
-(void) bigCookieArrival{
    SKSpriteNode *cookieBig = [_cookieBig copy];
    cookieBig.position = CGPointMake(-160, 150);
    [cookieBig runAction:[SKAction actionNamed:@"cookieMove"]];
    [self addChild:cookieBig];
}


#pragma mark - 背景アニメーション
//壁を動かす
-(void)wallScroll:(BOOL)reverse{
    //ステータスにより向きを逆にする
    int direction = 1;
    if(reverse){
        direction = 1;
    }else{
        direction = -1;
    }
    
    //TODO:壁のスクロールは要調整
    [_wall removeAllActions];
    _wall.position = CGPointMake((155 * direction), 150);
    SKAction *action1 = [SKAction moveTo:CGPointMake((-155 * direction), 150) duration:4.0f];
    SKAction *action2 = [SKAction moveTo:CGPointMake((155 * direction), 150) duration:0.0f];
    SKAction *sequence = [SKAction sequence:@[action1, action2]];
    SKAction *repeat = [SKAction repeatActionForever:sequence];
    [_wall runAction:repeat];
    
    
    //多き方のtron爆発。
    //いろいろ都合が悪いのでここはsks使わずにコードで。
    [self enumerateChildNodesWithName:@"tronBigCopy" usingBlock:^(SKNode *node, BOOL *stop) {
        //ポジション保持してノードを消して爆発エフェクト
        CGPoint position = CGPointMake(node.position.x, node.position.y);
        [node removeFromParent];
        SKEmitterNode *emitter = [NSKeyedUnarchiver unarchiveObjectWithFile:
                                  [[NSBundle mainBundle] pathForResource:@"explosion"
                                                                  ofType:@"sks"]];
        emitter.position = position;
        SKAction *seq = [SKAction sequence:@[[SKAction fadeOutWithDuration:1],
                                             [SKAction waitForDuration:0.5f],
                                             [SKAction removeFromParent]]];
        [self addChild:emitter];
        [emitter runAction:seq];
    }];
    //小さい方はフェード
    [self enumerateChildNodesWithName:@"tronSmallCopy" usingBlock:^(SKNode *node, BOOL *stop) {
        SKAction *seq = [SKAction sequence:@[[SKAction fadeOutWithDuration:1],
                                             [SKAction removeFromParent]]];
        [node runAction:seq];
    }];
}

//緑色の四角いやつ
//TODO:ステータスにより、移動の向きを逆方向にしたい。
- (void)createTronBig{
    //ステータスにより向きを逆にする
    int direction = 1;
    if([[appDelegete.blinkStatus objectForKey:@"status"] isEqualToString:NORMAL]){
        direction = -1;
    }else{
        direction = 1;
    }
    SKSpriteNode *tronBig = [_tronBig copy];
    [tronBig setName:@"tronBigCopy"];
    int rand = (int)arc4random_uniform(100);
    tronBig.position = CGPointMake((180 * direction), rand+100);
    SKAction *action = [SKAction moveBy:CGVectorMake((-400.0f * direction), 0) duration:15.0f];
    [tronBig runAction:action completion:^{
        [tronBig removeFromParent];
    }];
    [self addChild:tronBig];
}

- (void)createTronSmall{
    //ステータスにより向きを逆にする
    int direction = 1;
    if([[appDelegete.blinkStatus objectForKey:@"status"] isEqualToString:NORMAL]){
        direction = -1;
    }else{
        direction = 1;
    }
    SKSpriteNode *tronSmall = [_tronSmall copy];
    [tronSmall setName:@"tronSmallCopy"];
    int rand = (int)arc4random_uniform(70);
    tronSmall.position = CGPointMake((180 * direction), rand+115);
    SKAction *action = [SKAction moveBy:CGVectorMake((-400.0f * direction), 0) duration:30.0f];
    [tronSmall runAction:action completion:^{
        [tronSmall removeFromParent];
    }];
    [self addChild:tronSmall];
}

# pragma mark 衝突処理
- (void)didBeginContact:(SKPhysicsContact *)contact {
    NSLog(@"なんかぶつかった");
    //クッキー(小）とパックマンがぶつかったらクッキーを消す
    if ([contact.bodyA.node.name isEqualToString:@"cookieSmall"]){
        [self runAction:[SKAction actionNamed:@"SEeat"]];
        [contact.bodyA.node removeFromParent];
        [self packmanEat];
    }else if ([contact.bodyB.node.name isEqualToString:@"cookieSmall"]){
        [self runAction:[SKAction actionNamed:@"SEeat"]];
        [contact.bodyB.node removeFromParent];
        [self packmanEat];
    }
    
    //クッキー(大）とパックマンがぶつかったらクッキーを消す
    if ([contact.bodyA.node.name isEqualToString:@"cookieBig"]){
        [contact.bodyA.node removeFromParent];
        //BGM再生
        [self stopBGM:_bgmNormal];
        [self stopBGM:_bgmGhost];
        [self playBGM:_bgmGhost];
        [self runAction:[SKAction actionNamed:@"SEeat"]];
        [self cautionAnimation];
    }else if ([contact.bodyB.node.name isEqualToString:@"cookieBig"]){
        [contact.bodyB.node removeFromParent];
        //BGM再生
        [self stopBGM:_bgmNormal];
        [self stopBGM:_bgmGhost];
        [self playBGM:_bgmGhost];
        [self runAction:[SKAction actionNamed:@"SEeat"]];
        [self cautionAnimation];
    }
    
    //パックマンとゴーストが衝突（CAUTION->NORMALに遷移）したとき
    //    if ([contact.bodyA.node.name isEqualToString:@"ghost"] &&
    //        [contact.bodyB.node.name isEqualToString:@"pacman"]){
    //        [self ghostDead];
    //    }else if ([contact.bodyA.node.name isEqualToString:@"pacman"] &&
    //              [contact.bodyB.node.name isEqualToString:@"ghost"]){
    //        [self ghostDead];
    //    }
}

# pragma mark SE/BGM
//BGMストップ(nodeを消す)
- (void)stopBGM:(SKAudioNode*)node{
    [node removeFromParent];
}

//戻るときに呼ぶ。
- (void)stopAllBGM{
    [self stopBGM:_bgmGhost];
    [self stopBGM:_bgmNormal];
}

//現在のstatusのBGMを再生する
- (void)playStatusBGM{
    if([[appDelegete.blinkStatus objectForKey:@"status"] isEqualToString: NORMAL]){
        [self playBGM:_bgmNormal];
    }else if([[appDelegete.blinkStatus objectForKey:@"status"] isEqualToString: CAUTION]){
        [self playBGM:_bgmGhost];
    }else{
        return;
    }
}

//スタートBGM再生（SKAudioNodeをaddChildする）
- (void)playBGM:(SKAudioNode*)node{
    //BGMがOFFだったら何もしない
    NSUserDefaults *settingUD = [NSUserDefaults standardUserDefaults];
    bool bgm = [settingUD boolForKey:@"BGMMODE"];
    if(!bgm){
        return;
    }
    
    @try {
        /* 常に実行される */
        [self addChild:node];
    }
    @catch (NSException *exception) {
        return;
        @throw exception;
    }
    @finally {
        return;
    }
}


# pragma mark タイマー
- (void)invalidateTimer{
    //タイマーを破棄　GameViewControllerから他の画面に遷移するときに呼び出す。
    [statusCheckTimer invalidate];
    statusCheckTimer = nil;
    
    [tutorialLoopTimer invalidate];
    tutorialLoopTimer = nil;
    
    [tutorialEatTimer invalidate];
    tutorialEatTimer = nil;
    
    [tutorialTimer1 invalidate];
    tutorialTimer1 = nil;
    [tutorialTimer2 invalidate];
    tutorialTimer2 = nil;
    [tutorialTimer3 invalidate];
    tutorialTimer3 = nil;
    [tutorialTimer4 invalidate];
    tutorialTimer4 = nil;
    [tutorialTimer5 invalidate];
    tutorialTimer5 = nil;
    [tutorialTimer6 invalidate];
    tutorialTimer6 = nil;
    [tutorialTimer7 invalidate];
    tutorialTimer7 = nil;
    [tutorialTimer8 invalidate];
    tutorialTimer8 = nil;
}


# pragma mark タップ処理
- (void)touchDownAtPoint:(CGPoint)pos {
}
- (void)touchMovedToPoint:(CGPoint)pos {
}
- (void)touchUpAtPoint:(CGPoint)pos {
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {[self touchDownAtPoint:[t locationInNode:self]];}
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    for (UITouch *t in touches) {[self touchMovedToPoint:[t locationInNode:self]];}
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {[self touchUpAtPoint:[t locationInNode:self]];}
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {[self touchUpAtPoint:[t locationInNode:self]];}
}

@end

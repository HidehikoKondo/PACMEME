//
//  GameViewController.m
//  MEME
//
//  Created by HidehikoKondo on 2016/09/16.
//  Copyright © 2016年 UDONKOAPPS. All rights reserved.
//

#import "GameViewController.h"
#import "GameScene.h"
#import "AppDelegate.h"

@interface GameViewController ()
@property (weak, nonatomic) IBOutlet UIView *debugView;
@property (strong, nonatomic) IBOutlet SKView *skview;

@end

@implementation GameViewController
//デリゲート
AppDelegate *appDelegete;
//シーン
GameScene *scene;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //デリゲート
    appDelegete = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    // Load the SKScene from 'GameScene.sks'
    scene = (GameScene *)[SKScene nodeWithFileNamed:@"GameScene"];
    
    // Set the scale mode to scale to fit the window
    scene.scaleMode = SKSceneScaleModeAspectFill;
    SKView *skView = (SKView *)self.view;
    
    // Present the scene
    [skView presentScene:scene];
    
    //設定によりデバッグメニューの表示を切り替え
    NSUserDefaults *settingUD = [NSUserDefaults standardUserDefaults];
    if([settingUD boolForKey:@"DEBUGMODE"]){
        skView.showsFPS = YES;
        skView.showsNodeCount = YES;
    }else{
        skView.showsFPS = NO;
        skView.showsNodeCount = NO;
    }
    
    if([settingUD boolForKey:@"DEBUGMODE"]){
        [_debugView setHidden:NO];
        
    }else{
        [_debugView setHidden:YES];
    }
    
    //BGMボタンの状態チェック
    [self checkBGMSE];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark デバッグボタン
- (IBAction)changeStatusNormal:(id)sender {
    [appDelegete.blinkStatus setObject:NORMAL forKey:@"status"];
}
- (IBAction)changeStatusCaution:(id)sender {
    [appDelegete.blinkStatus setObject:CAUTION forKey:@"status"];
}
- (IBAction)changeStatusDANGER:(id)sender {
    [appDelegete.blinkStatus setObject:DANGER forKey:@"status"];
}
- (IBAction)blinkCountPlus:(id)sender {
    [scene blinkDetection:nil];
}
- (IBAction)blinkCountMinus:(id)sender {
    NSNumber *number = [appDelegete.blinkStatus objectForKey:@"blinkcount"];
    int plus = [number intValue];
    plus = plus - 1;
    [appDelegete.blinkStatus setObject:[NSNumber numberWithInt: plus]forKey:@"blinkcount"];
}
- (IBAction)executeCheckStatus:(id)sender {
    [scene statusCheck:NULL];
}
- (IBAction)closeDebugMenu:(id)sender {
    [_debugView removeFromSuperview];
    [scene closeDebugMenu];
}


# pragma mark ViewController関連
/**
 トップページに戻る時の処理。
 BGM停止、タイマー停止、シーン削除、MEME接続解除
 */
- (IBAction)back:(id)sender {
    [scene stopAllBGM];
    [scene invalidateTimer];
    [scene removeFromParent];
    scene = nil;
    [[MEMELib sharedInstance] disconnectPeripheral];
    [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark SE/BGM関連
/**
 起動時に前回のスイッチの設定値を呼び出してON/OFFを適用する
 */
- (void)checkBGMSE{
    NSUserDefaults *settingUD = [NSUserDefaults standardUserDefaults];
    BOOL bgm = [settingUD boolForKey:@"BGMMODE"];
    //BOOL se = [settingUD boolForKey:@"SEMODE"];

    //BGMボタンの画像
    if(bgm){
        UIImage *image = [UIImage imageNamed:@"bgm_on.png"];
        [_bgmButton setImage:image forState:UIControlStateNormal];
    }else{
        UIImage *image = [UIImage imageNamed:@"bgm_off.png"];
        [_bgmButton setImage:image forState:UIControlStateNormal];
    }
}


/**
 BGMのON/OFFの切り替え
 @warning SEは非対応（端末のボリューム設定で調整してねっていう仕様）
 */
- (IBAction)bgmChange:(id)sender {
    //デバッグモードの読み込み
    NSUserDefaults *settingUD = [NSUserDefaults standardUserDefaults];
    BOOL sw = [settingUD boolForKey:@"BGMMODE"];
    if(sw){
        //YESだったらNOにUserDefaultsを変更
        [settingUD setObject:@"NO" forKey:@"BGMMODE"];
        //画像をOFFに変更
        UIImage *image = [UIImage imageNamed:@"bgm_off.png"];
        [_bgmButton setImage:image forState:UIControlStateNormal];
        //BGMOFF
        [scene stopAllBGM];
    }else{
        //YESだったらNOにUserDefaultsを変更
        [settingUD setObject:@"YES" forKey:@"BGMMODE"];
        //画像をONに変更
        UIImage *image = [UIImage imageNamed:@"bgm_on.png"];
        [_bgmButton setImage:image forState:UIControlStateNormal];
        //BGM再生
        [scene playStatusBGM];
    }
}

@end

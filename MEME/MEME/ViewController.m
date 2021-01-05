//
//  ViewController.m
//  MEME
//
//  Created by HidehikoKondo on 2016/08/14.
//  Copyright © 2016年 UDONKOAPPS. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <MEMELib/MEMELib.h>
#import <AudioToolbox/AudioToolbox.h>
#include <AVFoundation/AVFoundation.h>
#import "GameViewController.h"
#import "message.h"

@interface ViewController ()
//周辺のbluetooth機器を見つけたらこの配列に格納する
@property (nonatomic, strong) NSMutableArray *peripherals;
//リアルタイムで取得できるデータ
@property (nonatomic, retain) NSUserDefaults *settingUD;

//Outlet
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UITableView *memeSelectTableView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView *memeSelectView;
@property (weak, nonatomic) IBOutlet UIImageView *memeImageView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *goButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@end

@implementation ViewController
SystemSoundID sound_1;

//ステータスバーの文字を白くする
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


- (void)viewWillAppear:(BOOL)animated{
    //スタートBGM再生
    [self playBGM:@"pac_music_gamestart"];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    //iTunesの音楽再生を止めないようにする
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];

    //delegate
    //これを実行するとmemeAppAuthorizedが呼ばれる
    [MEMELib sharedInstance].delegate = self;
    
    //変数初期化
    self.peripherals = @[].mutableCopy;
    _settingUD = [NSUserDefaults standardUserDefaults];
    
    //ビューの設定
    [self viewSetup];
    [self debugModeSetup];
}


//起動時のビューの設定
- (void)viewSetup{
    //端末のスリープを無効にする
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    //一覧のViewの角丸
    _memeSelectView.layer.cornerRadius = 10;
    
    //電源ボタンのぱらぱらアニメ
    NSArray *array = [ NSArray arrayWithObjects:
                      [UIImage imageNamed:@"meme_on"]
                      ,[UIImage imageNamed:@"meme_off"]
                      ,nil];
    _memeImageView.animationImages = array;
    _memeImageView.animationDuration = 0.2;
    [_memeImageView startAnimating];
}


//UserDefaultsの設定
- (void)debugModeSetup{
    //UserDefaultsの設定
    NSMutableDictionary* keyValues = [NSMutableDictionary dictionary];
    [keyValues setObject:@"NO" forKey:@"DEBUGMODE"];
    [keyValues setObject:@"YES" forKey:@"BGMMODE"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:keyValues];
    
    //デバッグモードの読み込み
    BOOL sw = [_settingUD boolForKey:@"DEBUGMODE"];
    if(sw){
        _debugSwitch.on = YES;
    }else{
        _debugSwitch.on = NO;
    }
}


# pragma mark BGM関連
- (void)playBGM:(NSString*)filename{
    //BGMがOFFだったら何もしない
    bool bgm = [_settingUD boolForKey:@"BGMMODE"];
    if(!bgm){
        return;
    }
    
    //スタートBGM再生
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:path];
    _audio = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    _audio.volume = 0.7f;
    [_audio prepareToPlay];
    [_audio play];
}

# pragma mark 画面遷移
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [self memeSelectViewVisible:NO];
    if ( [segue.identifier isEqualToString:@"tutorial"] ) {
        AppDelegate *appDelegete =  (AppDelegate*)[[UIApplication sharedApplication] delegate];
        appDelegete.isTutorial = YES;
    }else{
        AppDelegate *appDelegete =  (AppDelegate*)[[UIApplication sharedApplication] delegate];
        appDelegete.isTutorial = NO;
    }
}

- (void)presentGameViewController{
    //画面遷移
    GameViewController *gameViewController = [[GameViewController alloc] init];
    gameViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:gameViewController animated:YES completion:nil];
}

# pragma mark デバッグモード関連
- (IBAction)changeDebugMode:(id)sender {
    UISwitch *sw = (UISwitch*)sender;
    
    if(sw.on){
        [_settingUD setBool:YES forKey:@"DEBUGMODE"];
        NSLog(@"%d",sw.on);
        [_settingUD synchronize];
        
        //スタートボタン強制的に有効
        //[_startButton setEnabled:YES];
    }else{
        [_settingUD setBool:NO forKey:@"DEBUGMODE"];
        NSLog(@"%@",_settingUD);
        NSLog(@"%d",sw.on);
        [_settingUD synchronize];
    }
}


# pragma mark MEME接続関連
//MEMEのスキャン開始（点滅状態のMEMEを探す）
- (IBAction)scanButtonPressed:(id)sender {
    //デバッグモード時は強制的に画面遷移
    BOOL sw = [_settingUD boolForKey:@"DEBUGMODE"];
    if(sw){
        //goボタン有効
        [_goButton setEnabled:YES];
    }
    
    //くるくる隠してテーブルビューを触れるようにする
    [_indicator setHidden:YES];
    [_memeSelectTableView setUserInteractionEnabled:YES];
    
    //いったん接続を解除する
    //FIXES: なぜか再接続でデータ取得ができないので・・・
    [[MEMELib sharedInstance] disconnectPeripheral];
    
    //一覧初期化＆リロード
    self.peripherals = @[].mutableCopy;
    [_memeSelectTableView reloadData];
    
    //スキャン開始
    MEMEStatus status = [[MEMELib sharedInstance] startScanningPeripherals];
    [self checkMEMEStatus: status];
    
    //一覧表示
    [self memeSelectViewVisible: true];
}


#pragma mark
#pragma mark MEMELib Delegates
//点滅状態のMEMEを発見したときに呼ばれる
- (void) memePeripheralFound: (CBPeripheral *) peripheral withDeviceAddress:(NSString *)address
{
    //最初にperipheralsの中身が接続済みの端末かどうかのチェックをしているようだ。
    BOOL alreadyFound = NO;
    for (CBPeripheral *p in self.peripherals){
        if ([p.identifier isEqual: peripheral.identifier]){
            alreadyFound = YES;
            break;
        }
    }
    
    //接続済みじゃない端末だけperipheralsに追加する
    if (!alreadyFound)  {
        NSLog(@"New peripheral found %@ %@", [peripheral.identifier UUIDString], address);
        [self.peripherals addObject: peripheral];
        
        //リストを更新
        [_memeSelectTableView reloadData];
    }
}

//接続確立 -> データ取得開始
- (void) memePeripheralConnected: (CBPeripheral *)peripheral
{
    NSLog(@"MEME Device Connected!");
    NSLog(@"getConnectedDeviceType:%d",[MEMELib sharedInstance].getConnectedDeviceType );
    
    //モデルチェック　MTは弾く
    if([MEMELib sharedInstance].getConnectedDeviceType == 2){
        [self showAlert:TITLE_MEME message:MES_NOT_ES];
        [self cancelConnect:nil];
        return;
    }
    
    //データ取得開始
    [[MEMELib sharedInstance] startDataReport];
    
    //GOボタン有効
    [_goButton setEnabled:YES];
    
    //くるくる隠す
    [_indicator setHidden:YES];
    return;
}


//切断
- (void) memePeripheralDisconnected: (CBPeripheral *)peripheral
{
    NSLog(@"MEME Device Disconnected");
    //こいつのせいか！勝手に戻る原因...でも挙動としてはこれでいいかもしれんけど、
    //GameViewControllerが表示されている時にこれが呼び出されるのはいいのかこれ？？？
    //TODO: NSNotificationCenterつかってGameViewController側でdissmissさせるとか、そんな感じの方がよさそう

    //->GameViewController側でback呼び出してタイマーの停止をするように変更した。
    //切断後の再会でタイマー重複動作のためパックマンが暴走するやつの修正
    
    GameViewController *gameViewController = [[GameViewController alloc] init];
    [gameViewController back:nil];
    
    
    [self dismissViewControllerAnimated: YES completion: ^{
        NSLog(@"MEME Device Disconnected & dissmiss ViewcController");
    }];
    
    //テーブルリロードとメッセージ表示とスタートボタン無効
    [_memeSelectTableView reloadData];
    [self showStatusLabel:MES_MEME_DISCONNECT];
    
    [_goButton setEnabled:NO];
}


//MEMEから受信したデータ
- (void) memeRealTimeModeDataReceived: (MEMERealTimeData *)data
{
    //NSLog(@"RealTime Data Received %@", [data description]);
    //瞬き検出（テストコード）
    //self.latestRealTimeData = data;
    //NSLog(@"%@", data);
    //    NSLog(@"blinkSpeed / blinkStrength: %d / %d", [self.latestRealTimeData blinkSpeed] , [self.latestRealTimeData blinkStrength]);
    
    /*
     {seqNo = 64; accZ = -15; accY = 4; accX = -1; yaw = 349.29; pitch = 16.9; roll = -1.59; blinkStrength = 0; blinkSpeed = 0; eyeMoveRight = 0; eyeMoveLeft = 0; eyeMoveDown = 0; eyeMoveUp = 0; powerLeft = 5; isWalking = 0; fitError = 0; }
     */
    
    //delegateの変数の値を取得してlabelに表示
    AppDelegate *appDelegete =  (AppDelegate*)[[UIApplication sharedApplication] delegate];
    appDelegete.memeValue = data;
    
    //瞬きの強さ
    //appDelegete.blinkValue = [NSString stringWithFormat:@"%d",[self.latestRealTimeData blinkStrength]];
    //NSLog(@"MEMEデータ取得");
}


//APPIDの認証認証
- (void) memeAppAuthorized:(MEMEStatus)status
{
    [self checkMEMEStatus: status];
}

- (void) memeCommandResponse:(MEMEResponse)response
{
    NSLog(@"Command Response - eventCode: 0x%02x - commandResult: %d", response.eventCode, response.commandResult);
    switch (response.eventCode) {
        case 0x02:
            NSLog(@"-------");
            NSLog(@"Data Report Started");
            NSLog(@"isCalibrated:%d",[MEMELib sharedInstance].isCalibrated );
            NSLog(@"isDataReceiving:%d",[MEMELib sharedInstance].isDataReceiving);
            NSLog(@"getConnectedDeviceType:%d",[MEMELib sharedInstance].getConnectedDeviceType );
            NSLog(@"getConnectedDeviceSubType:%d",[MEMELib sharedInstance].getConnectedDeviceSubType );
            NSLog(@"getHWVersion:%d",[MEMELib sharedInstance].getHWVersion );
            NSLog(@"getFWVersion:%@",[MEMELib sharedInstance].getFWVersion );
            NSLog(@"getSDKVersion:%@",[MEMELib sharedInstance].getSDKVersion );
            NSLog(@"getConnectedByOthers:%@",[MEMELib sharedInstance].getConnectedByOthers );
            NSLog(@"-------");
            
            //[self showStatusLabel:MES_MEME_CONNECT_OK];
            [_goButton setEnabled:YES];
            break;
        case 0x04:
            NSLog(@"Data Report Stopped");
            //[self showAlert:TITLE_MEME message:MES_DATA_FAIL];
            [_goButton setEnabled:NO];
            break;
        default:
            break;
    }
}

//ファームウェア認証（なんに使うんだろう？）
- (void) memeFirmwareAuthorized: (MEMEStatus)status{
    
}


#pragma mark MEMEの状態
- (void) checkMEMEStatus: (MEMEStatus) status
{
    if (status == MEME_OK){
        //アプリ側のステータスの確認をここで行う。
        //アプリ側でなにかエラーがある時のみダイアログを出して、OKのときはここでは特に何もしない。
        //MEME_OKのステータスになると、memePeripheralFoundが呼ばれる
        NSLog(@"Status: MEME_OK");
    }else if (status == MEME_ERROR){
        //不明なエラー
        [self showAlert:TITLE_ERROR message:MES_ERROR];
    } else if (status == MEME_ERROR_SDK_AUTH){
        //SDKの認証エラー
        [self showAlert:TITLE_AUTH_FAIL message:MES_SDK_INVALID];
    }else if (status == MEME_ERROR_APP_AUTH){
        //MEMEの認証エラー
        [self showAlert:TITLE_AUTH_FAIL message:MES_APP_INVALID];
    }else if (status == MEME_ERROR_CONNECTION){
        //接続エラー
        [self showAlert:TITLE_ERROR_CONNECTION message:MES_ERROR_CONNECTION];
    }else if (status == MEME_DEVICE_INVALID){
        //デバイスが無効
        [self showAlert:TITLE_DEVICE_INVALID message:MES_DEVICE_INVALID];
    } else if (status == MEME_CMD_INVALID){
        //SDKエラー　無効なコマンド
        [self showAlert:TITLE_SDK_ERROR message:MES_SDK_ERROR];
    }else if (status == MEME_ERROR_FW_CHECK){
        //ファームウェアのバージョンのエラー
        [self showAlert:TITLE_FW_ERROR message:MES_FW_ERROR];
    } else if (status == MEME_ERROR_BL_OFF){
        //BluetoothがOFF
        [self showAlert:TITLE_BT_ERROR message: MES_BT_ERROR];
    }
}


//接続済みチェック
-(BOOL)connectionCheck{
    if([MEMELib sharedInstance].isConnected == 0){
        //未接続
        return NO;
    }else{
        //接続済み
        return YES;
    }
    
}


#pragma mark - MEME選択のテーブルビュー
//セクション数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


//セクション内の行数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.peripherals count];
}


//テーブルにセルを返す
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    // 再利用できるセルがあれば再利用する
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.layer.cornerRadius = 5;
    
    if (!cell) {
        // 再利用できない場合は新規で作成
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
    }
    
    CBPeripheral *peripheral = [self.peripherals objectAtIndex: indexPath.row];
    cell.textLabel.text = [peripheral.identifier UUIDString];
    
    return cell;
}

//接続するMEMEを一覧から選択
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBPeripheral *peripheral = [self.peripherals objectAtIndex: indexPath.row];
    MEMEStatus status = [[MEMELib sharedInstance] connectPeripheral: peripheral ];
    [self checkMEMEStatus: status];
    
    NSLog(@"Start connecting to MEME Device...");
    
    // 選択状態の解除
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //くるくる表示
    [_indicator setHidden:NO];
    [_memeSelectTableView setUserInteractionEnabled:NO];
}


//セクション名（空白）
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section) {
        case 0:
            return @"";
            break;
    }
    return nil;
}

//テーブルビューを表示
-(void)memeSelectViewVisible:(BOOL)visible{
    CGRect screen = [[UIScreen mainScreen] bounds];

    
    if(visible){
         [UIView animateWithDuration:0.4f
                               delay:0.0f
                             options:UIViewAnimationOptionCurveLinear
                          animations:^ {
                             //アニメの終了点の指定
                              [_memeSelectView setHidden:NO];
                              [_memeSelectView setFrame:CGRectMake(_memeSelectView.frame.origin.x,
                                                                   screen.size.height - _memeSelectView.frame.size.height - 10,
                                                                   _memeSelectView.frame.size.width,
                                                                   _memeSelectView.frame.size.height)];
                         }
                         completion:^(BOOL finished){
                             //アニメーションが終了したときの処理
                         }];
        
    }else{
        [UIView animateWithDuration:0.4f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^ {
                             //アニメの終了点の指定
                             [_memeSelectView setFrame:CGRectMake(_memeSelectView.frame.origin.x,
                                                                  screen.size.height,
                                                                  _memeSelectView.frame.size.width,
                                                                  _memeSelectView.frame.size.height)];
                         }
                         completion:^(BOOL finished){
                             //アニメーションが終了したときの処理
                             [_memeSelectView setHidden:YES];
                         }];
    }
}

- (IBAction)cancelConnect:(id)sender {
    //スキャン停止
    MEMEStatus status = [[MEMELib sharedInstance] stopScanningPeripherals];
    NSLog(@"CancelConnect -> STATUS:%d", status);
    [self memeSelectViewVisible:NO];
}


# pragma mark - アラート
//アラートを表示するだけ
- (void)showAlert:(NSString*)title message:(NSString*)message{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                      }]];
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

//ラベルを更新
- (void)showStatusLabel:(NSString*)message{
    [_statusLabel setText:message];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

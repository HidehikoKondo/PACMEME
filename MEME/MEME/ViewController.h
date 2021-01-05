//
//  ViewController.h
//  MEME
//
//  Created by HidehikoKondo on 2016/08/14.
//  Copyright © 2016年 UDONKOAPPS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

//MEME
#import <MEMELib/MEMELib.h>

@interface ViewController : UIViewController<MEMELibDelegate, UIApplicationDelegate, AVAudioPlayerDelegate, UITableViewDataSource, UITableViewDelegate>
@property(nonatomic) AVAudioPlayer *audio;
@property (weak, nonatomic) IBOutlet UISwitch *debugSwitch;


@end


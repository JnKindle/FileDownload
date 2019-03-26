//
//  ViewController.m
//  FileDownload
//
//  Created by Jn_Kindle on 2019/3/26.
//  Copyright © 2019年 JnKindle. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "JNFileDownload.h"

@interface ViewController ()<JNFileDownloadDelegate>
@property (weak, nonatomic) IBOutlet UILabel *downloadProgressLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (nonatomic, strong) JNFileDownload *fileDownload;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
}

- (IBAction)startDownload:(id)sender {
    NSString *fileUrl = @"https://pic.ibaotu.com/00/48/71/79a888piCk9g.mp4";
    if(self.fileDownload == nil){
        self.fileDownload = [[JNFileDownload alloc] init];
        self.fileDownload.tag = 1; // 区别 不同下载
        self.fileDownload.delegate = self;
    }
    [self.fileDownload downloadFileWithFileUrl:fileUrl isBreakpoint:NO];
}

- (IBAction)suspendOrContinueDownload:(id)sender {
    [self.fileDownload suspendDownloadFile];
}

- (IBAction)breakpointContinueDownload:(id)sender {
    NSString *fileUrl = @"https://pic.ibaotu.com/00/48/71/79a888piCk9g.mp4";
    if(self.fileDownload == nil){
        self.fileDownload = [[JNFileDownload alloc] init];
        self.fileDownload.tag = 1; // 区别 不同下载
        self.fileDownload.delegate = self;
    }
    [self.fileDownload downloadFileWithFileUrl:fileUrl isBreakpoint:YES];
}

- (IBAction)cancelDownload:(id)sender {
    [self.fileDownload cancelDownloadFile];
    self.progressView.progress = 0;
    self.downloadProgressLabel.text = @"0.0%";
    self.fileDownload = nil;
}

#pragma mark - JNFileDownloadDelegate
- (void)backDownloadProgress:(float)progress tag:(NSInteger)tag
{
    self.progressView.progress = progress;
     self.downloadProgressLabel.text = [NSString stringWithFormat:@"%0.1f%@",progress*100,@"%"];
}

-(void)downloadSuccess:(NSURL *)url tag:(NSInteger)tag
{
    NSLog(@"下载成功");
    [self playWithUrl:url];
    self.progressView.progress = 0;
    self.downloadProgressLabel.text = @"0.0%";
    self.fileDownload = nil;
    
}

-(void)downloadError:(NSError *)error tag:(NSInteger)tag
{
    NSLog(@"下载失败,请再次下载 :%@",error);
    self.progressView.progress = 0;
    self.downloadProgressLabel.text = @"0.0%";
    self.fileDownload = nil;
    
}

//传入本地url 进行视频播放
-(void)playWithUrl:(NSURL *)url
{
    //系统的视频播放器
    AVPlayerViewController *vc = [[AVPlayerViewController alloc] init];
    //播放器的播放类
    AVPlayer *player = [[AVPlayer alloc] initWithURL:url];
    vc.player = player;
    //自动开始播放
    [vc.player play];
    //推出视屏播放器
    [self  presentViewController:vc animated:YES completion:nil];
}


@end

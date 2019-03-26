//
//  JNFileDownload.m
//  FileDownload
//
//  Created by Jn_Kindle on 2019/3/26.
//  Copyright © 2019年 JnKindle. All rights reserved.
//

#import "JNFileDownload.h"
#import <CommonCrypto/CommonDigest.h>

@interface JNFileDownload ()<NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, assign) BOOL isSuspend;


@end

@implementation JNFileDownload

- (void)downloadFileWithFileUrl:(NSString *)fileUrl isBreakpoint:(BOOL)isBreakpoint
{
    if (!fileUrl || fileUrl.length == 0 || ![self checkUrlIsString:fileUrl]) {
        NSLog(@"fileUrl 无效");
        return ;
    }
    NSURL *url = [NSURL URLWithString:fileUrl];
    if (!self.session) {
        self.fileName = [self md5:fileUrl];
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[self getCurrentDateString]];
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self getTmpFileUrl]]) {
        [self downloadWithResumeData];
        return;
    }
    
    self.downloadTask = [self.session downloadTaskWithURL:url];
    [self.downloadTask resume];
    
    [self saveTmpFile];
}

//暂停下载
- (void)suspendDownloadFile
{
    if (self.isSuspend) {
        [self.downloadTask resume];
    }else {
        [self.downloadTask suspend];
    }
    self.isSuspend = !self.isSuspend;
}

//取消下载
-(void)cancelDownloadFile
{
    __weak typeof(self) weakSelf = self;
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        weakSelf.resumeData = resumeData; //内存
        [resumeData writeToFile:[weakSelf getTmpFileUrl] atomically:NO]; //沙盒
    }];
}

//断点下载
-(void)downloadWithResumeData
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSData *data = [fm contentsAtPath:[self getTmpFileUrl]];
    self.downloadTask = [self.session downloadTaskWithResumeData:data];
    [self.downloadTask resume];
}

//断点下载-重新下载，下载的文件做为临时文件
- (void)downloadTmpFile
{
    __weak typeof(self) weakSelf = self;
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        weakSelf.resumeData = resumeData;
        [resumeData writeToFile:[weakSelf getTmpFileUrl] atomically:NO];
        weakSelf.downloadTask = [weakSelf.session downloadTaskWithResumeData:resumeData];
        [weakSelf.downloadTask resume];
    }];
}
#pragma mark - NSURLSessionDelegate
//每传一次，调用一次
- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    float downProgress = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(backDownloadProgress:tag:)]) {
        [self.delegate backDownloadProgress:downProgress tag:self.tag];
    }
}

- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location
{
    //拼接Doc 更换的路径
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) lastObject];
    NSString *file = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",self.fileName]];
    //创建文件管理器
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:file]) {
        //如果文件夹下有同名文件  则将其删除
        [manager removeItemAtPath:file error:nil];
    }
    NSError *saveError;
    [manager moveItemAtURL:location toURL:[NSURL URLWithString:file] error:&saveError];
    //将视频资源从原有路径移动到自己指定的路径
    BOOL success = [manager copyItemAtPath:location.path toPath:file error:nil];
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *url = [[NSURL alloc] initFileURLWithPath:file];
            if(self.delegate && [self.delegate respondsToSelector:@selector(downloadSuccess:tag:)])
                [self.delegate downloadSuccess:url tag:self.tag];
        });
    }
    //已经拷贝 删除缓存文件
    [manager removeItemAtPath:location.path error:nil];
    [manager removeItemAtPath:[self getTmpFileUrl] error:nil];
}

#pragma mark - others
- (BOOL)checkUrlIsString:(NSString *)url
{
    NSString *pattern = @"http(s)?://([\\w-]+\\.)+[\\w-]+(/[\\w- ./?%&=]*)?";
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:pattern options:0 error:nil];
    NSArray *regexArray = [regex matchesInString:url options:0 range:NSMakeRange(0, url.length)];
    if (regexArray.count > 0) {
        return YES;
    }else {
        return NO;
    }
}

//MD5加密
- (NSString *)md5:(NSString *)string
{
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02X", digest[i]];
    }
    return result;
}


//获取当前时间
- (NSString *)getCurrentDateString
{
    NSDate *currentDate = [NSDate date];//获取当前时间，日期
    NSTimeInterval timeInterval = [currentDate timeIntervalSince1970];
    return [NSString stringWithFormat:@"%.f",timeInterval];
}


//未下载完的临时文件url地址
- (NSString*)getTmpFileUrl
{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"download.tmp"];
    //NSLog(@"%@",filePath);
    return filePath;
}


//提前保存临时文件 预防下载中杀掉app 开启定时器
- (void)saveTmpFile
{
    __weak typeof(self) weakSelf = self;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        [weakSelf downloadTmpFile];
    }];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}


- (void)dealloc
{
    [self.session invalidateAndCancel];
    self.session = nil;
    [self.downloadTask cancel];
    self.downloadTask = nil;
}






@end

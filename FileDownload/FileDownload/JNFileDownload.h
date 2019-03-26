//
//  JNFileDownload.h
//  FileDownload
//
//  Created by Jn_Kindle on 2019/3/26.
//  Copyright © 2019年 JnKindle. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol JNFileDownloadDelegate <NSObject>
@optional
- (void)backDownloadProgress:(float)progress tag:(NSInteger)tag;
- (void)downloadSuccess:(NSURL*)url tag:(NSInteger)tag;
- (void)downloadError:(NSError*)error tag:(NSInteger)tag;
@end

@interface JNFileDownload : NSObject

@property (nonatomic, assign) NSInteger tag;//文件下载的的标记
@property (nonatomic, weak) id<JNFileDownloadDelegate> delegate;

- (void)downloadFileWithFileUrl:(NSString *)fileUrl isBreakpoint:(BOOL)isBreakpoint;
//暂停下载
- (void)suspendDownloadFile;
//取消下载
-(void)cancelDownloadFile;

@end

NS_ASSUME_NONNULL_END

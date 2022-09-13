//
//  YDFileMonitor.h
//  YDMemoryLeakFinder
//
//  Created by 徐亚东 on 2022/6/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YDFileMonitor : NSObject

+(instancetype)shared;

/// 文件或文件夹是否存在
/// @param path filePath
+(BOOL)isFileExist:(NSString *)path;

/// 是否是文件目录
/// @param path filePath
+(BOOL)isDirectory:(NSString *)path;

/// 是否是文件
/// @param path filePath
+(BOOL)isFile:(NSString *)path;

+(void)monitorFile:(NSString *)filePath changed:(void(^)(void))execute;
+(void)monitorDirectory:(NSString *)DirectoryPath changed:(void(^)(void))execute;
@end

NS_ASSUME_NONNULL_END

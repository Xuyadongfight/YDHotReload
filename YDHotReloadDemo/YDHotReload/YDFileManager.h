//
//  YDFileManager.h
//  YDHotReload
//
//  Created by 徐亚东 on 2022/11/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YDFileManager : NSObject
@property(nonatomic,strong)NSString *dylib_current_name;

+(instancetype)shared;
+(void)setup;
+(void)startFileWatchLibraryChange:(void(^)(NSString*,NSString*))block;

-(NSString*)getProjectName;
-(NSArray<NSString*>*)getChangeClasses;
@end

NS_ASSUME_NONNULL_END

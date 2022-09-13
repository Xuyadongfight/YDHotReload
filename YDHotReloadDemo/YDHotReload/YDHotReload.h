//
//  YDHotReload.h
//  YDHotReload
//
//  Created by 徐亚东 on 2021/12/10.
//

#import <Foundation/Foundation.h>

@interface YDHotReload : NSObject
@property (strong,nonatomic)NSString *project_path;
+(instancetype)shared;
+(void)start;
@end

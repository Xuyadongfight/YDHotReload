//
//  YDFileMonitor.m
//  YDMemoryLeakFinder
//
//  Created by 徐亚东 on 2022/6/14.
//

#import "YDFileMonitor.h"
#import "YDHotReload.h"
@interface YDFileMonitor()
@end

@implementation YDFileMonitor

+(instancetype)shared{
    static dispatch_once_t once;
    static YDFileMonitor *shared;
    dispatch_once(&once, ^{
        shared = [[YDFileMonitor alloc] init];
    });
    return shared;
}

+(void)isFileOrDirectory:(NSString *)path isDirectory:(BOOL *)isDirectory isFile:(BOOL *)isFile{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL file = false;
    file = [fileManager fileExistsAtPath:path isDirectory:isDirectory];
    *isFile = file;
}

+(BOOL)isFileExist:(NSString *)path{
    BOOL isFile = false,isDirectory = false;
    [self isFileOrDirectory:path isDirectory:&isDirectory isFile:&isFile];
    if (isDirectory || isFile) {
        return true;
    }
    return false;
}
+(BOOL)isFile:(NSString *)path{
    BOOL isFile = false,isDirectory = false;
    [self isFileOrDirectory:path isDirectory:&isDirectory isFile:&isFile];
    return isFile;
}

+(BOOL)isDirectory:(NSString *)path{
    BOOL isFile = false,isDirectory = false;
    [self isFileOrDirectory:path isDirectory:&isDirectory isFile:&isFile];
    return isDirectory;
}

+(void)monitorFile:(NSString *)filePath changed:(nonnull void (^)(void))execute{
    if (![self isFile:filePath]) {
        return;
    }
    
}

+ (void)monitorDirectory:(NSString *)DirectoryPath changed:(void (^)(void))execute{
    if (![self isDirectory:DirectoryPath]) {
        return;
    }

    int fd = open([DirectoryPath UTF8String], O_EVTONLY);
    if (fd == -1) {
        return;
    }

    long mask = DISPATCH_VNODE_DELETE | DISPATCH_VNODE_WRITE | DISPATCH_VNODE_EXTEND | DISPATCH_VNODE_ATTRIB | DISPATCH_VNODE_LINK | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_REVOKE | DISPATCH_VNODE_FUNLOCK;
//    long mask = DISPATCH_VNODE_WRITE;
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    __block dispatch_source_t  source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, mask, globalQueue);
    void(^eventHandler)(void),(^cancelHandler)(void);
    eventHandler = ^{
        unsigned long l = dispatch_source_get_data(source);
        unsigned long tempMask = dispatch_source_get_mask(source);
        NSLog(@"l = %x , tempMask = %x",l,tempMask);
        
//        if (l & (DISPATCH_VNODE_WRITE)) {
//            if (execute != NULL) {
//                execute();
//            }
//            dispatch_source_cancel(source);
//        }
    };
    cancelHandler = ^{
        unsigned long fd = dispatch_source_get_handle(source);
        close((int)fd);
        [self monitorDirectory:DirectoryPath changed:execute];
    };
    dispatch_source_set_event_handler(source, eventHandler);
    dispatch_source_set_cancel_handler(source, cancelHandler);
    dispatch_resume(source);
}

-(void)funcTest{
    
}


@end

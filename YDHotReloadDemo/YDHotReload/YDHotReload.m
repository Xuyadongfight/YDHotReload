//
//  YDHotReload.m
//  YDHotReload
//
//  Created by 徐亚东 on 2021/12/10.
//

#import "YDHotReload.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "YDFileManager.h"

#define HOTSUCCESS \
@\
"\n\
**********************************************\
\n\
*-------------hot reload success-------------*\
\n\
**********************************************\
\n"

@interface YDHotReload ()

@end

@implementation YDHotReload
+ (void)start{
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        YDHotReload *shared = [self shared];
        NSLog(@"YDHotReload start");
        [shared setUp];
//    });
}
+ (void)load{

}


+(id)shared{
    static YDHotReload *_shard;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _shard = [[YDHotReload alloc] init];
    });
    return _shard;
}

-(void)setUp{
    [YDFileManager setup];
    [YDFileManager startFileWatchLibraryChange:^(NSString* dylibName,NSString* dylibPath) {
        [self loadDylib:dylibPath];
    }];
}

-(void)loadDylib:(NSString *)libName{
    if (libName != nil){
        void *lib = dlopen([libName UTF8String],RTLD_NOW);
        if (lib == NULL) {
            NSLog(@"ERROR:load dylib %@ 失败",libName);
            return;
        }
        [self changeClasses];
    }
}

-(void)changeClasses{
    YDFileManager *shared = [YDFileManager shared];
    
    NSMutableArray *originalClassNames = [[NSMutableArray alloc] init];
    NSMutableArray *newClassNames = [[NSMutableArray alloc] init];
    
    NSString *tempProjectName = shared.getProjectName;
    NSString *tempDylibName = shared.dylib_current_name;
    
    NSUInteger lengthProjectName = tempProjectName.length;
    NSUInteger lengthDylib = tempDylibName.length;
    
    NSArray<NSString*>* changeClasses = [shared getChangeClasses];
    
    [changeClasses enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *tempRes = [obj componentsSeparatedByString:@"."];
        NSString *className = tempRes.firstObject;
        NSString *suffix = tempRes.lastObject;
        if ([suffix isEqualToString:@"swift"]) {
            [originalClassNames addObject:[NSString stringWithFormat:@"_TtC%lu%@%lu%@",lengthProjectName,tempProjectName,className.length,className]];
            [newClassNames addObject:[NSString stringWithFormat:@"_TtC%lu%@%lu%@",lengthDylib,tempDylibName,className.length,className]];
        }
    }];
    
    for (int i = 0; i < originalClassNames.count; i++) {
        NSString *clsName = originalClassNames[i];
        NSString *newClsName = newClassNames[i];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self changeClass:clsName newClassName:newClsName];
        });
    }
}
-(void)changeClass:(NSString *)clsName newClassName:(NSString *)newClsName{
    Class originalCls = NSClassFromString(clsName);
    Class newCls = NSClassFromString(newClsName);
    if (originalCls == Nil || newCls == Nil) {
        NSLog(@"ERROR:change class %@ to %@",clsName,newClsName);
    }
    if ([originalCls isKindOfClass:object_getClass([UIViewController class])] && [newCls isKindOfClass:object_getClass([UIViewController class])]) {
        UIViewController *current = [self findVisibleViewController];
        NSArray* currentNames = [[NSString stringWithUTF8String:object_getClassName(current)] componentsSeparatedByString:@"."];
        NSArray* newClsNames = [[NSString stringWithUTF8String:class_getName(newCls)] componentsSeparatedByString:@"."];
        if ([currentNames.lastObject isEqualToString:newClsNames.lastObject]) {
            object_setClass(current, newCls);
            current.view = [UIView new];
            [current viewDidLoad];
            NSLog(HOTSUCCESS);
            return;
        }
    }
}

-(UIViewController *)getRootViewController{
    UIWindow* window = [[[UIApplication sharedApplication] windows] lastObject];
    NSAssert(window, @"The window is empty");
    return window.rootViewController;
}
-(UIViewController *)findVisibleViewController {
    UIViewController* currentViewController = [self getRootViewController];
    BOOL runLoopFind = YES;
    while (runLoopFind) {
        if (currentViewController.presentedViewController) {
            currentViewController = currentViewController.presentedViewController;
        } else {
            if ([currentViewController isKindOfClass:[UINavigationController class]]) {
                currentViewController = ((UINavigationController *)currentViewController).visibleViewController;
            } else if ([currentViewController isKindOfClass:[UITabBarController class]]) {
                currentViewController = ((UITabBarController* )currentViewController).selectedViewController;
            } else {
                break;
            }
        }
    }
    return currentViewController;
}

@end

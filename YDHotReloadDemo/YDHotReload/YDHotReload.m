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

#define YD_ERROR(x) NSLog(@"ERROR: %@",x)
#define YD_SUCCESS(x) NSLog(@"SUCCESS: %@",x)

#define YD_SHELLS_PATH @"/shells"
#define YD_CLASSES_PATH @"/classes"
#define YD_LIBRARY_PATH @"/libary"
#define YD_OTHERS_PATH @"/others"

#define YD_INJECT_COUNT @"injectcount"
#define YD_CONFIG_NAME @"hotreload_config"

#define YD_INJECTSHELL @"zshconfigfile_path=\"${HOME}/.zshrc\"\n\
source $zshconfigfile_path\n\
grep -q \"injectcount\" $zshconfigfile_path\n\
if [ $? -eq 0 ];then\n\
    :\n\
else\n\
    echo \"export injectcount=0\" >> $zshconfigfile_path\n\
    source $zshconfigfile_path\n\
fi\n\
newcount=$(($injectcount+1))\n\
sed -i \"\" \"s/export injectcount=${injectcount}/export injectcount=${newcount}/\" $zshconfigfile_path";

@interface YDHotReload ()
@property (strong,nonatomic)dispatch_source_t sourceConfig;
@property (strong,nonatomic)dispatch_source_t sourceLibrary;

@property (strong,nonatomic)NSString *project_path;
@property (strong,nonatomic)NSString *hotreload_root_path;
@property (strong,nonatomic)NSArray<NSString *> *hotreload_filenames;
@property (strong,nonatomic)NSArray<NSString *> *hotreload_filenames_check_dir;//用来快速查看文件是否存在的相对地址
@property (strong,nonatomic)NSMutableDictionary *symbol_to_filesuffix;

@property (strong,nonatomic)NSString *dylib_name;
@property (strong,nonatomic)NSString *dylib_name_real;
@property (strong,nonatomic)NSString *inject_count;

@property (strong,nonatomic)NSString *pathOfShells;
@property (strong,nonatomic)NSString *pathOfClasses;
@property (strong,nonatomic)NSString *pathOfLibrary;
@property (strong,nonatomic)NSString *pathOfOthers;

@property (strong,nonatomic)NSString *projectName;

@property (strong,nonatomic)NSDate *lastTime;
@end

@implementation YDHotReload
+ (void)start{
    
}
+ (void)load{
    NSLog(@"YDHotReload load");
    NSString *projectName = [NSBundle mainBundle].infoDictionary[@"CFBundleExecutable"];
    YDHotReload *shared = [self shared];
    [shared setProjectName:projectName];
    [shared loadProjectConfig];
    [shared fileSetUp];
    [shared createShells];//创建shells
    [@"" writeToFile:[NSString stringWithFormat:@"%@/%@",shared.pathOfOthers,YD_CONFIG_NAME] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [shared startFileWatch];
    [shared debug_log];
}


+(id)shared{
    static YDHotReload *_shard;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _shard = [[YDHotReload alloc] init];
    });
    return _shard;
}
-(void)startHotReload{
    //获取新编译的动态库名称
    NSData *data = [[NSData alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",self.pathOfOthers,YD_INJECT_COUNT]];
    NSString *strCount = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    self.inject_count = [strCount stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    self.dylib_name_real = [NSString stringWithFormat:@"%@_%@",self.dylib_name,self.inject_count];
    if (![self.dylib_name_real isEqualToString:@""]){
        NSString *dylibPath = [self.pathOfLibrary stringByAppendingFormat:@"/%@",self.dylib_name_real];
        //加载动态库
        [self loadDylib:dylibPath];
    }
}
#pragma mark create file
-(void)fileSetUp{
    NSFileManager *filem = [NSFileManager defaultManager];
    [self fileCreateDir:filem];//创建文件夹并清空
}
-(void)fileCreateDir:(NSFileManager *)fileManage{
    NSArray<NSString *> *paths = @[self.pathOfShells,self.pathOfClasses,self.pathOfLibrary,self.pathOfOthers];
    [paths enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isdir = false;
        if (![fileManage fileExistsAtPath:path isDirectory:&isdir] && !isdir){
            BOOL res = [fileManage createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
            if (!res){
                NSString *errorStr = [NSString stringWithFormat:@"create directory in %@",paths];
                YD_ERROR(errorStr);
                return;
            }
        }
    }];
    
    //清空文件夹
    [paths enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray<NSString *> *fileList = [fileManage contentsOfDirectoryAtPath:path error:nil];
        [fileList enumerateObjectsUsingBlock:^(NSString * _Nonnull filename, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *first = [filename substringToIndex:1];
            if (![first isEqualToString:@"."]) {
                [fileManage removeItemAtPath:[NSString stringWithFormat:@"%@/%@",path,filename] error:nil];
            }
        }];
    }];
}
-(void)createShells{
    //cp.sh
//    NSMutableString *cpShell = [NSMutableString stringWithFormat:@"%@ %@/**/%@ %@\n",@"cp",self.project_path,@"inject_count.sh",self.pathOfShells];
//    NSMutableString *cpShell = [NSMutableString stringWithString:@""];
    NSString *cpConfigShell = [NSMutableString stringWithFormat:@"%@ %@/**/%@ %@/\n sleep 0.1",@"cp",self.project_path,YD_CONFIG_NAME,self.pathOfOthers];
    NSMutableString *cpShell = [NSMutableString stringWithString:@""];
    //inject_count.sh
    NSString *injectcountShell = YD_INJECTSHELL;
    
    //change.sh
    NSMutableString *changeShell = [[NSMutableString alloc] initWithString:@""];
    
    //compile_swift.sh
    NSMutableString *compileSwiftShell = [NSMutableString stringWithString:@""];
    
    [compileSwiftShell appendFormat:@"swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target x86_64-apple-ios12.0-simulator -emit-library -o %@/%@_${%@} ",self.pathOfLibrary,self.dylib_name,YD_INJECT_COUNT];
    
    //finish.sh
    NSMutableString *finishShell = [NSMutableString stringWithFormat:@"%@ \"${%@}\" > %@/injectcount",@"echo",YD_INJECT_COUNT,self.pathOfOthers];
    
    //hotreload.sh
    NSArray *shellList = @[@"inject_count.sh",@"cpconfig.sh",@"cp.sh",@"compile_swift.sh",@"finish.sh"];
    NSMutableString *hotreloadShell = [NSMutableString stringWithString:@""];
    [shellList enumerateObjectsUsingBlock:^(id  _Nonnull shellname, NSUInteger idx, BOOL * _Nonnull stop) {
        [hotreloadShell appendFormat:@"source %@/%@\n",self.pathOfShells,shellname];
    }];
    
    [self.symbol_to_filesuffix enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull symbol, NSString *  _Nonnull suffix, BOOL * _Nonnull stop) {
        NSString *newSymbol = [symbol stringByAppendingFormat:@"_${%@}",YD_INJECT_COUNT];
        NSString *filename = [symbol stringByAppendingFormat:@".%@",suffix];
        NSString *newFileName = [symbol stringByAppendingFormat:@"_${%@}.%@",YD_INJECT_COUNT,suffix];
        //cp.sh
        [cpShell appendFormat:@"%@ %@/**/%@ %@\n",@"cp",self.project_path,filename,self.pathOfClasses];
        [compileSwiftShell appendFormat:@"%@/%@ ",self.pathOfClasses,filename];
    }];
    [cpConfigShell writeToFile:[NSString stringWithFormat:@"%@/cpconfig.sh",self.pathOfShells] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [cpShell writeToFile:[NSString stringWithFormat:@"%@/cp.sh",self.pathOfShells] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [injectcountShell writeToFile:[NSString stringWithFormat:@"%@/inject_count.sh",self.pathOfShells] atomically:YES encoding:NSUTF8StringEncoding error:nil];
//    [changeShell writeToFile:[NSString stringWithFormat:@"%@/change.sh",self.pathOfShells] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [compileSwiftShell writeToFile:[NSString stringWithFormat:@"%@/compile_swift.sh",self.pathOfShells] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [finishShell writeToFile:[NSString stringWithFormat:@"%@/finish.sh",self.pathOfShells] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [hotreloadShell writeToFile:[NSString stringWithFormat:@"%@/hot",@"/usr/local/bin"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(void)loadProjectConfig{
    NSString *configPath = [[NSBundle mainBundle] pathForResource:YD_CONFIG_NAME ofType:@""];
    NSData *data = [[NSData alloc] initWithContentsOfFile:configPath];
    if (data == nil) {
        YD_ERROR(@"load config in project");
    };
    [self serializationConfig:data];
}
-(void)loadOthersConfig{
    NSString *configPath = [self.pathOfOthers stringByAppendingFormat:@"/%@",YD_CONFIG_NAME];
    NSData *data = [[NSData alloc] initWithContentsOfFile:configPath];
    if (data == nil) {
        YD_ERROR(@"load config in hortreload directory");
    }
    [self serializationConfig:data];
}

-(void)serializationConfig:(NSData *)configData{
    NSError *jsonError;
    NSDictionary *jsonConfig = [NSJSONSerialization JSONObjectWithData:configData options:NSJSONReadingMutableLeaves error:&jsonError];
    if (jsonConfig == nil) {
        YD_ERROR(@"serialization config data");
    }
    NSDictionary *requiredDic = jsonConfig[@"required"];
//    NSDictionary *optionalDic = jsonConfig[@"optional"];
    if (requiredDic == nil) {
        YD_ERROR(@"load config key required");
    }
    self.project_path = requiredDic[@"project_path"];
    self.hotreload_root_path = requiredDic[@"hotreload_root_path"];
    self.hotreload_filenames = requiredDic[@"hotreload_filenames"];
    self.dylib_name = requiredDic[@"dylib_name"];
    NSArray *keys = @[@"project_path",@"hotreload_root_path",@"hotreload_filenames",@"dylib_name"];
    if (self.project_path == nil || self.hotreload_root_path == nil || self.hotreload_filenames == nil || self.dylib_name == nil) {
        NSString *errStr = [NSString stringWithFormat:@"load file hotreload_config required keys -> %@",keys];
        YD_ERROR(errStr);
    }
    self.pathOfShells = [self.hotreload_root_path stringByAppendingString:YD_SHELLS_PATH];
    self.pathOfClasses = [self.hotreload_root_path stringByAppendingString:YD_CLASSES_PATH];
    self.pathOfLibrary = [self.hotreload_root_path stringByAppendingString:YD_LIBRARY_PATH];
    self.pathOfOthers = [self.hotreload_root_path stringByAppendingString:YD_OTHERS_PATH];
    [self fileNamesSupportCheck];
    [self fileExistCheck];
}

-(BOOL)fileExistCheck{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [self.hotreload_filenames enumerateObjectsUsingBlock:^(NSString * _Nonnull filename, NSUInteger idx, BOOL * _Nonnull stop) {
        dic[filename] = @(0);
    }];
    int count = 0;
    BOOL temp = [self checkDir:self.project_path resultDic:dic resultCount:&count];
    if (!temp) {
        [dic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber*  _Nonnull value, BOOL * _Nonnull stop) {
            if ([value isEqualToNumber:@(0)]){
                NSString *errorStr = [NSString stringWithFormat:@"file %@ does not exist",key];
                YD_ERROR(errorStr);
            }
        }];
    }
    return temp;
}
-(BOOL)checkDir:(NSString *)dirPath resultDic:(NSMutableDictionary *)dic resultCount:(int*)count{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray<NSString *>*fileList = [fileManager contentsOfDirectoryAtPath:dirPath error:nil];
    [fileList enumerateObjectsUsingBlock:^(NSString * _Nonnull filename, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *tempPath = [dirPath stringByAppendingFormat:@"/%@",filename];
        BOOL isdir;
        [fileManager fileExistsAtPath:tempPath isDirectory:&isdir];
        if (isdir) {
            [self checkDir:tempPath resultDic:dic resultCount:count];
        }else{
            if (dic[filename] != nil) {
                dic[filename] = @(1);
                *count += 1;
                if (*count == dic.count) {
                    return;
                }
            }
        }
    }];
    return *count == dic.count;
}

-(void)fileNamesSupportCheck{
    NSMutableDictionary *tempDic = [[NSMutableDictionary alloc] init];
    [self.hotreload_filenames enumerateObjectsUsingBlock:^(NSString * _Nonnull filename, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *componts = [filename componentsSeparatedByString:@"."];
        if (componts.count == 2) {
            NSString *symbol = componts[0];
            NSString *suffix = componts[1];
            if ([suffix isEqualToString:@"swift"]) {
                tempDic[symbol] = suffix;
            }else{
                NSString *error = [NSString stringWithFormat:@"does not support %@",filename];
                YD_ERROR(error);
            }
        }else{
            NSString *error = [NSString stringWithFormat:@"does not support %@",filename];
            YD_ERROR(error);
        }
    }];
    self.symbol_to_filesuffix = tempDic;
}


-(void)loadDylib:(NSString *)libName{
    if (libName != nil){
        void *lib = dlopen([libName UTF8String],RTLD_NOW);
        NSString * result= [NSString stringWithFormat:@"load lib %@",libName];
        if (lib != NULL){
            YD_SUCCESS(result);
            [self changeClasses];
        }else{
            YD_ERROR(result);
        }
    }
}

-(void)changeClasses{
    NSMutableArray *originalClassNames = [[NSMutableArray alloc] init];
    NSMutableArray *newClassNames = [[NSMutableArray alloc] init];
    NSUInteger lengthDylib = self.dylib_name_real.length;
    NSUInteger lengthProjectName = self.projectName.length;
    [self.symbol_to_filesuffix enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull symbol, NSString*  _Nonnull suffix, BOOL * _Nonnull stop) {
        if ([suffix isEqualToString:@"swift"]) {
            [originalClassNames addObject:[NSString stringWithFormat:@"_TtC%lu%@%lu%@",lengthProjectName,self.projectName,symbol.length,symbol]];
//            NSString *temp = [NSString stringWithFormat:@"%@_%@",symbol,self.inject_count];
            NSString *temp = symbol;
            [newClassNames addObject:[NSString stringWithFormat:@"_TtC%lu%@%lu%@",lengthDylib,self.dylib_name_real,temp.length,temp]];
        }else if ([@[@"h",@"m"] containsObject:suffix]){
//            [newClassNames addObject:[NSString stringWithFormat:@"_%@",self.inject_count]];
        }else{
//            [newClassNames addObject:symbol];
        }
    }];
    
    for (int i = 0; i < originalClassNames.count; i++) {
        NSString *clsName = originalClassNames[i];
//        NSString *clsName = @"ViewController";
        NSString *newClsName = newClassNames[i];
        [self changeClass:clsName newClassName:newClsName];
    }
}
-(void)changeClass:(NSString *)clsName newClassName:(NSString *)newClsName{
    Class originalCls = NSClassFromString(clsName);
    Class newCls = NSClassFromString(newClsName);
    if (originalCls == Nil || newCls == Nil) {
        NSString *error = [NSString stringWithFormat:@"change class %@",clsName];
        YD_ERROR(error);
    }
    if ([originalCls isKindOfClass:object_getClass([UIViewController class])] && [newCls isKindOfClass:object_getClass([UIViewController class])]) {
        UIViewController *current = [self findVisibleViewController];
        if ([current class] == newCls) {
            return;
        }
            object_setClass(current, newCls);
        current.view = [UIView new];
        [current viewDidLoad];
    }else if ([originalCls isKindOfClass:object_getClass([UIView class])]){
        object_setClass(originalCls, object_getClass(newCls));
    }else{
//        object_setClass(originalCls, object_getClass(newCls));
    }
    
}

-(NSDictionary*)getOriginalClassNames{
    NSMutableDictionary *symbols = [[NSMutableDictionary alloc] init];
    [self.hotreload_filenames enumerateObjectsUsingBlock:^(NSString * _Nonnull filename, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *components = [filename componentsSeparatedByString:@"."];
        if (components.count == 2) {
            if ([components[1] isEqualToString:@"swift"]) {
                symbols[components[0]] = components[1];
            }else{
                NSString *error = [NSString stringWithFormat:@"does not support %@",filename];
                YD_ERROR(error);
            }
        }
    }];
    return  symbols;
}

-(dispatch_source_t)startFileWatchPath:(NSString *)path fileChange:(void(^)(void))block{
    NSURL *url = [NSURL URLWithString:path];
    int const fd = open([[url path] fileSystemRepresentation], O_EVTONLY);
    if (fd < 0) {
        NSString *errorStr = [NSString stringWithFormat:@"Unable to open the path = %@",path];
        YD_ERROR(errorStr);
    }
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_WRITE, DISPATCH_TARGET_QUEUE_DEFAULT);
    
    dispatch_source_set_event_handler(source, ^{
        unsigned long const type = dispatch_source_get_data(source);
        switch (type) {
            case DISPATCH_VNODE_WRITE:
                if (block != nil){block();};
                break;
            default:
                break;
        }
    });
    dispatch_source_set_cancel_handler(source, ^{
    close(fd);
    });
    dispatch_resume(source);
    return  source;
}
-(void)startFileWatch{
    __weak typeof(self)weakSelf = self;
    NSString *configPath = [NSString stringWithFormat:@"%@/%@",self.pathOfOthers,YD_CONFIG_NAME];
    self.sourceConfig = [self startFileWatchPath:configPath fileChange:^{
        [weakSelf loadOthersConfig];
        [weakSelf createShells];
    }];
    NSString *libraryPath = [NSString stringWithFormat:@"%@",self.pathOfLibrary];

    self.sourceLibrary = [self startFileWatchPath:libraryPath fileChange:^{
        [weakSelf loadDylib];
    }];
}

-(void)loadDylib{
    NSDate *current = [[NSDate alloc] init];
    if (self.lastTime == nil) {
        self.lastTime = current;
    }else{
        if ((current.timeIntervalSince1970 - self.lastTime.timeIntervalSince1970) < 1) {
            return;
        }
    }
    self.lastTime = current;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self startHotReload];
    });
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

-(void)debug_log{
    NSLog(@"1",@"2");
}

@end

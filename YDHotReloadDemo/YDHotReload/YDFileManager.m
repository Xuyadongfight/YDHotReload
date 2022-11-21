//
//  YDFileManager.m
//  YDHotReload
//
//  Created by 徐亚东 on 2022/11/16.
//

#import "YDFileManager.h"
#import <dirent.h>

#define FILE_NAME_HOTRELOAD @"file_name_hotreload"
#define FILE_NAME_PROJECT @"file_name_project"
#define FILE_NAME_DYLIB @"file_name_dylib_base"

#define HOT_PATH_CLASS @"class"
#define HOT_PATH_SHELL @"shell"
#define HOT_PATH_LIBRARY @"library"
#define HOT_PATH_OTHER @"other"

#define FILE_NAME_CONFIG @"file_name_config"

@interface YDFileManager()
@property(nonatomic,strong)NSString *path_base_hotreload;
@property(nonatomic,strong)NSString *path_project;
@property(nonatomic,strong)NSString *dylib_base_name;


@property(nonatomic,strong)NSString *path_class;
@property(nonatomic,strong)NSString *path_shell;
@property(nonatomic,strong)NSString *path_library;
@property(nonatomic,strong)NSString *path_other;

@property(nonatomic,strong)NSArray *allHotFiles;
@property(nonatomic,strong)NSMutableArray *allProjectFiles;
@property(nonatomic,strong)NSMutableDictionary *allProjectDics;




@property (strong,nonatomic)dispatch_source_t sourceLibrary;

@end

@implementation YDFileManager
/*
 1.在桌面创建需要的文件夹ydhotreload
 2.程序中需要能够获取桌面动态文件夹的路径（通过脚本修改工程中的资源文件 来通信）突破沙盒限制
 */

+(instancetype)shared{
    static dispatch_once_t once;
    static YDFileManager *__shared;
    dispatch_once(&once, ^{
        __shared = [[YDFileManager alloc] init];
    });
    return __shared;
}

+ (void)setup{
    YDFileManager *shared = [self shared];
    [shared checkFiles];
    [shared makeDirs];
    [shared createShells];
}

-(void)checkFiles{
    NSString *project_path = [self loadBundleFile:FILE_NAME_PROJECT];
    if (project_path == nil || [project_path isEqual: @""]) {
        NSLog(@"ERROR:工程路径%@ 无内容",project_path);
        return;
    }
    self.path_project = project_path;
    self.dylib_base_name = @"dylib_test";
    
    NSDictionary *dicConfig = [NSJSONSerialization JSONObjectWithData:[self loadBundleData:FILE_NAME_CONFIG] options:NSJSONReadingMutableLeaves error:nil];
    NSArray<NSString*> *reload_files = [[dicConfig allValues] firstObject];
    if (reload_files == nil || reload_files.count == 0) {
        NSLog(@"ERROR:需更新文件为空 %@",FILE_NAME_CONFIG);
        return;
    }
    
    DIR *dir = opendir(self.path_project.UTF8String);
    if (dir != NULL) {
        struct dirent *stdinfo;
        while (1) {
            if ((stdinfo = readdir(dir))==0) {
                break;
            }
            if (strncmp(stdinfo->d_name, ".", 1)==0) {
                continue;
            }

        }
    }
    NSMutableArray *allfiles = [[NSMutableArray alloc] init];
    NSMutableDictionary *allDic = [[NSMutableDictionary alloc] init];
    ReadDir(self.path_project.UTF8String,(__bridge void*)allfiles,(__bridge void*)allDic);

    NSArray<NSString*> *files = reload_files;
    for (int i = 0; i < files.count; i++) {
        NSString *filename = files[i];
        NSString *fullpath = [allDic valueForKey:filename];
        if (fullpath == nil) {
            NSLog(@"ERROR:%@ 文件 不存在",filename);
            return;
        }
    }
    self.allHotFiles = files;
    self.allProjectFiles = allfiles;
    self.allProjectDics = allDic;
    
}

-(void)makeDirs{

    NSString *homePath = NSHomeDirectory();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *hotreloadPath = [NSString stringWithFormat:@"%@/ydhotreload",homePath];
    bool res = [fileManager createDirectoryAtPath:hotreloadPath withIntermediateDirectories:YES attributes:nil error:nil];
    if (!res) {
        NSLog(@"ERROR:%@创建失败",hotreloadPath);
        return;
    }
    self.path_base_hotreload = hotreloadPath;
    
    [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/%@",self.path_base_hotreload,HOT_PATH_LIBRARY] error:nil];
    
    NSArray<NSString *> *paths = @[HOT_PATH_CLASS,HOT_PATH_SHELL,HOT_PATH_LIBRARY,HOT_PATH_OTHER];
    NSArray<void(^)(NSString *)> *blocks = @[^(NSString *tempPath){self.path_class = tempPath;},
                         ^(NSString *tempPath){self.path_shell = tempPath;},
                         ^(NSString *tempPath){self.path_library = tempPath;},
                         ^(NSString *tempPath){self.path_other = tempPath;}];

    for (int i = 0; i < paths.count; i++) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@",self.path_base_hotreload,paths[i]];
        bool tempRes = [fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
        if (!tempRes) {
            NSLog(@"ERROR:%@创建失败",fullPath);
            return;
        }
        blocks[i](fullPath);
    }
    
   
}


+(void)createShells{
    YDFileManager *shared = [self shared];
    [shared createShells];
}

-(NSString *)getProjectName{
    return [[self.path_project componentsSeparatedByString:@"/"] lastObject];
}

-(NSArray<NSString*>*)getChangeClasses{
    return self.allHotFiles;
}

-(NSString *)getdylibName{
    static int injectCount = 0;
    self.dylib_current_name = [NSString stringWithFormat:@"%@_%d",self.dylib_base_name,injectCount++];
    return self.dylib_current_name;
}

int ReadDir(const char* pathname,void *array,void*dic){
    DIR *dir;
    char strchdpath[256];
    if ((dir = opendir(pathname))==0) {
        fprintf(stderr, "Error failed to open input directory -%s\n",strerror(errno));
        NSLog(@"ERROR:%s 打开失败",pathname);
        return -1;
    }
    struct dirent *stdinfo;
    
    while (1) {
        if ((stdinfo = readdir(dir)) == 0) {
            break;
        }
        if (strncmp(stdinfo->d_name, ".", 1) == 0) {
            continue;
        }
        if (stdinfo->d_type == 8) {
            sprintf(strchdpath,"%s/%s",pathname,stdinfo->d_name);
            NSString *fileName = [[NSString alloc] initWithUTF8String:stdinfo->d_name];
            NSString *fullPath = [[NSString alloc] initWithUTF8String:strchdpath];
            [(__bridge NSMutableArray *)array addObject:[[NSString alloc] initWithUTF8String:strchdpath]];
            [(__bridge  NSMutableDictionary*)dic setValue:fullPath forKey:fileName];
        }
        if (stdinfo->d_type == 4) {
            sprintf(strchdpath,"%s/%s",pathname,stdinfo->d_name);
            ReadDir(strchdpath,array,dic);
        }
    }
    closedir(dir);
    return 0;
}


-(NSData *)loadBundleData:(NSString *)filename{
    NSString *bundle_path = [[NSBundle mainBundle] pathForResource:filename ofType:@""];
    NSData *data = [[NSData alloc] initWithContentsOfFile:bundle_path];
    return data;
}

-(NSString *)loadBundleFile:(NSString *)filename{
    NSData *data = [self loadBundleData:filename];
    NSString *filecontent = [[[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return filecontent;
}


-(void)createShells{
    NSString *dylib_name = [self getdylibName];
    NSMutableString *shellCompile = [NSMutableString stringWithFormat:@"swiftc -sdk /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk -target x86_64-apple-ios12.0-simulator -emit-library -o %@/%@ ",self.path_library,dylib_name];
    [self.allHotFiles enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [shellCompile appendFormat:@"%@ ",self.allProjectDics[obj]];
    }];

    bool res = [shellCompile writeToFile:[NSString stringWithFormat:@"%@/shell_compile.sh",self.path_shell] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    bool res1 = [shellCompile writeToFile:@"/usr/local/bin/hot" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    if (!res && !res1) {
        NSLog(@"ERROR:%@",@"shellCompile 创建失败");
        return;
    }
}

+ (void)startFileWatchLibraryChange:(void (^)(NSString * _Nonnull,NSString * _Nonnull))block{
    YDFileManager*shared = [self shared];
    shared.sourceLibrary = [shared startFileWatchPath:shared.path_library fileChange:block];
}
-(dispatch_source_t)startFileWatchPath:(NSString *)path fileChange:(void(^)(NSString*,NSString*))block{
    
    int const fd = open(path.UTF8String, O_RDONLY);
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    ReadDir(path.UTF8String, (__bridge void*)arr, (__bridge void*)dic);
    
    if (fd < 0) {
        NSString *errorStr = [NSString stringWithFormat:@"Unable to open the path = %@",path];
        NSLog(@"ERROR:%@",errorStr);
    }
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_WRITE, DISPATCH_TARGET_QUEUE_DEFAULT);
    
    dispatch_source_set_event_handler(source, ^{
//        unsigned long const type = dispatch_source_get_data(source);
        NSMutableArray *arrTemp = [[NSMutableArray alloc] init];
        NSMutableDictionary *dicTemp = [[NSMutableDictionary alloc] init];
        ReadDir([self.path_library UTF8String], (__bridge void*)arrTemp, (__bridge void*)dicTemp);
        [arrTemp enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([[[obj componentsSeparatedByString:@"/"] lastObject] isEqualToString:self.dylib_current_name]) {
                if (block != nil){block(self.dylib_current_name,obj);};
                [self createShells];
            }
        }];
    });
    dispatch_source_set_cancel_handler(source, ^{
    close(fd);
    });
    dispatch_resume(source);
    return  source;
}

@end

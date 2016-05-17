//   ___                _
//  / __|___  ___  __ _| |___
// | (_ / _ \/ _ \/ _` |   -_)
//  \___\___/\___/\__, |_\___|
//                |___/
//
//  Created by 李小争 on 16/5/16.
//  Copyright © 2016年 李小争. All rights reserved.
//

#import "MKRequestManager.h"
#import <CommonCrypto/CommonDigest.h>

/*
 所有 HTTP 状态代码及其定义。
 代码  指示
 2xx  成功
 200  正常；请求已完成。
 201  正常；紧接 POST 命令。
 202  正常；已接受用于处理，但处理尚未完成。
 203  正常；部分信息 — 返回的信息只是一部分。
 204  正常；无响应 — 已接收请求，但不存在要回送的信息。
 3xx  重定向
 301  已移动 — 请求的数据具有新的位置且更改是永久的。
 302  已找到 — 请求的数据临时具有不同 URI。
 303  请参阅其它 — 可在另一 URI 下找到对请求的响应，且应使用 GET
 方法检索此响应。
 304  未修改 — 未按预期修改文档。
 305  使用代理 — 必须通过位置字段中提供的代理来访问请求的资源。
 306  未使用 — 不再使用；保留此代码以便将来使用。
 4xx  客户机中出现的错误
 400  错误请求 — 请求中有语法问题，或不能满足请求。
 401  未授权 — 未授权客户机访问数据。
 402  需要付款 — 表示计费系统已有效。
 403  禁止 — 即使有授权也不需要访问。
 404  找不到 — 服务器找不到给定的资源；文档不存在。
 407  代理认证请求 — 客户机首先必须使用代理认证自身。
 415  介质类型不受支持 — 服务器拒绝服务请求，因为不支持请求实体的格式。
 5xx  服务器中出现的错误
 500  内部错误 — 因为意外情况，服务器不能完成请求。
 501  未执行 — 服务器不支持请求的工具。
 502  错误网关 — 服务器接收到来自上游服务器的无效响应。
 503  无法获得服务 — 由于临时过载或维护，服务器无法处理请求。
 */

@interface MKRequestManager ()

@end

@implementation MKRequestManager


#ifdef ONLINE_VERSION
static NSString *encryptionStr = @"5w1d8abf75al954t608e48r3";
#else
#ifdef DEMO_VERSION
static NSString *encryptionStr = @"5w1d8abf75al954t608e48r3";
#else
static NSString *encryptionStr = @"wzshop";
#endif
#endif



+ (instancetype)sharedInstance
{
    static MKRequestManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.networkStatus = AFNetworkReachabilityStatusUnknown;
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
    }
    return self;
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    self.networkStatus = [notification.userInfo[AFNetworkingReachabilityNotificationStatusItem] integerValue];
}



#pragma mark - Public
-(void)GET:(NSString *)url params:(NSDictionary *)params
   success:(MKResponseSuccess)success fail:(MKResponseFail)fail{
    
    AFHTTPSessionManager *manager = [self managerWithBaseURL:nil sessionConfiguration:NO];
    [manager GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (success) {
            success(task,responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (self.networkStatus == AFNetworkReachabilityStatusUnknown || self.networkStatus == AFNetworkReachabilityStatusNotReachable) {
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"网络连接异常"
                                      message:@"请检查您手机的网络设置"
                                      delegate:nil
                                      cancelButtonTitle:nil
                                      otherButtonTitles:@"确定", nil];
            [alertView show];
        }
        if (fail) {
            fail(task,error);
        }
    }];
}


-(void)POST:(NSString *)url params:(NSDictionary *)params
    success:(MKResponseSuccess)success fail:(MKResponseFail)fail{
    
    // 2.加密参数
    /**
     *  设置时间戳
     */
    NSMutableDictionary *dictionary =
    [NSMutableDictionary dictionaryWithDictionary:params];
    UInt64 recodeTime = [[NSDate date] timeIntervalSince1970];
    NSString *timeStamp = [NSString stringWithFormat:@"%llu", recodeTime];
    
    [dictionary setValue:timeStamp forKey:@"timestamp"];
    
    /**
     *  对根据key对字典排序
     */
    NSMutableArray *postData = [NSMutableArray array];
    for (id key in dictionary.allKeys) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:[dictionary objectForKey:key] forKey:@"value"];
        [dict setValue:key forKey:@"key"];
        [postData addObject:dict];
    }
    
    [postData sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDictionary *dic1 = (NSDictionary *)obj1;
        NSDictionary *dic2 = (NSDictionary *)obj2;
        NSString *value1 = (NSString *)[dic1 objectForKey:@"key"];
        NSString *value2 = (NSString *)[dic2 objectForKey:@"key"];
        return [value1 compare:value2];
    }];
    
    NSMutableString *strParameter = [NSMutableString
                                     stringWithFormat:@"%@", encryptionStr]; // 5w1d8abf75al954t608e48r3
    NSString *value = nil;
    for (NSDictionary *val in postData) {
        [strParameter appendString:(NSString *)[val objectForKey:@"key"]];
        value = (NSString *)[val objectForKey:@"value"];
        if (value) {
            [strParameter appendString:value];
            value = nil;
        }
    }
    NSString *signature = [self md5HexDigest:strParameter];
    [dictionary setValue:signature forKey:@"signature"];
    
    NSLog(@"%@", [self httpRequestString:url parameters:dictionary]);
    
    AFHTTPSessionManager *manager = [self managerWithBaseURL:nil sessionConfiguration:NO];
    
    [manager POST:url parameters:dictionary progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSInteger code = [responseObject[@"code"] integerValue];
        if (code == -11) { //登录过期
            if (fail) {
                NSDictionary *userInfo = [NSDictionary
                                          dictionaryWithObject:@"发生未知错误，请稍后再试。"
                                          forKey:NSLocalizedDescriptionKey];
                
                NSError *failureError =
                [NSError errorWithDomain:WZNetWorkError
                                    code:[(NSHTTPURLResponse*)task.response statusCode]
                                userInfo:userInfo];
                fail(task, failureError);
            }
            [self autoLoginIfLoginOverdue];
        }else {
            if (success && [(NSHTTPURLResponse*)task.response statusCode] == 200) {
                success(task, responseObject);
            } else if (fail) {
                NSDictionary *userInfo = [NSDictionary
                                          dictionaryWithObject:@"服务器繁忙，请稍后再试"
                                          forKey:NSLocalizedDescriptionKey];
                NSError *failureError =
                [NSError errorWithDomain:WZNetWorkError
                                    code:[(NSHTTPURLResponse*)task.response statusCode]
                                userInfo:userInfo];
                fail(task, failureError);
            }
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (fail) {
            fail(task,error);
        }
    }];
}



-(void)uploadWithURL:(NSString *)url
              params:(NSDictionary *)params
               files:(NSArray *)files
            progress:(MKProgress)progress
             success:(MKResponseSuccess)success
                fail:(MKResponseFail)fail{
    
    
    // 2.加密参数
    /**
     *  设置时间戳
     */
    NSMutableDictionary *dictionary =
    [NSMutableDictionary dictionaryWithDictionary:params];
    UInt64 recodeTime = [[NSDate date] timeIntervalSince1970];
    NSString *timeStamp = [NSString stringWithFormat:@"%llu", recodeTime];
    
    [dictionary setValue:timeStamp forKey:@"timestamp"];
    
    /**
     *  对根据key对字典排序
     */
    NSMutableArray *postData = [NSMutableArray array];
    for (id key in dictionary.allKeys) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:[dictionary objectForKey:key] forKey:@"value"];
        [dict setValue:key forKey:@"key"];
        [postData addObject:dict];
    }
    
    [postData sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSDictionary *dic1 = (NSDictionary *)obj1;
        NSDictionary *dic2 = (NSDictionary *)obj2;
        NSString *value1 = (NSString *)[dic1 objectForKey:@"key"];
        NSString *value2 = (NSString *)[dic2 objectForKey:@"key"];
        return [value1 compare:value2];
    }];
    
    NSMutableString *strParameter = [NSMutableString
                                     stringWithFormat:@"%@", encryptionStr]; // 5w1d8abf75al954t608e48r3
    NSString *value = nil;
    for (NSDictionary *val in postData) {
        [strParameter appendString:(NSString *)[val objectForKey:@"key"]];
        value = (NSString *)[val objectForKey:@"value"];
        if (value) {
            [strParameter appendString:value];
            value = nil;
        }
    }
    NSString *signature = [self md5HexDigest:strParameter];
    [dictionary setValue:signature forKey:@"signature"];
    
    
    
    AFHTTPSessionManager *manager = [self managerWithBaseURL:nil sessionConfiguration:NO];
    
    [manager POST:url parameters:dictionary constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        for (MKHttpFile *file in files) {
            [formData appendPartWithFileData:file.data name:file.name fileName:file.filename mimeType:file.mimeType];
        }
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        if(progress){
            progress(uploadProgress);
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if ([responseObject[@"code"] integerValue] == -11) { //登录过期
            if (fail) {
                NSDictionary *userInfo = [NSDictionary
                                          dictionaryWithObject:@"发生未知错误，请稍后重试。"
                                          forKey:NSLocalizedDescriptionKey];
                NSError *failureError =
                [NSError errorWithDomain:WZNetWorkError
                                    code:[(NSHTTPURLResponse*)task.response statusCode]
                                userInfo:userInfo];
                fail(task, failureError);
            }
            [self autoLoginIfLoginOverdue];
        } else {
            if (success && [(NSHTTPURLResponse*)task.response statusCode] == 200) {
                success(task, responseObject);
            } else if (fail) {
                NSDictionary *userInfo = [NSDictionary
                                          dictionaryWithObject:@"服务器繁忙，请稍后再试"
                                          forKey:NSLocalizedDescriptionKey];
                NSError *failureError =
                [NSError errorWithDomain:WZNetWorkError
                                    code:[(NSHTTPURLResponse*)task.response statusCode]
                                userInfo:userInfo];
                fail(task, failureError);
            }
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(fail){
            fail(task,error);
        }
    }];
}

-(NSURLSessionDownloadTask *)downloadWithURL:(NSString *)url
                                 savePathURL:(NSURL *)fileURL
                                    progress:(MKProgress )progress
                                     success:(void (^)(NSURLResponse *, NSURL *))success
                                        fail:(void (^)(NSError *))fail{
    AFHTTPSessionManager *manager = [self managerWithBaseURL:nil sessionConfiguration:YES];
    
    NSURL *urlpath = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:urlpath];
    
    NSURLSessionDownloadTask *downloadtask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        progress(downloadProgress);
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        return [fileURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        if (error) {
            fail(error);
        }else{
            
            success(response,filePath);
        }
    }];
    
    [downloadtask resume];
    
    return downloadtask;
}

#pragma mark - Private

-(AFHTTPSessionManager *)managerWithBaseURL:(NSString *)baseURL  sessionConfiguration:(BOOL)isconfiguration{
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFHTTPSessionManager *manager =nil;
    
    NSURL *url = [NSURL URLWithString:baseURL];
    
    if (isconfiguration) {
        
        manager = [[AFHTTPSessionManager alloc] initWithBaseURL:url sessionConfiguration:configuration];
    }else{
        manager = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    }
    
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
//    manager.responseSerializer = [AFJSONResponseSerializer serializer];
//    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    manager.requestSerializer.timeoutInterval = 30;
    
    return manager;
}

-(id)responseConfiguration:(id)responseObject{
    
    NSString *string = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    return dic;
}

- (NSString *)md5HexDigest:(NSString *)strOrginal

{
    
    const char *original_str = [strOrginal UTF8String];
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(original_str, (CC_LONG)strlen(original_str), result);
    
    NSMutableString *hash = [NSMutableString string];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        
        [hash appendFormat:@"%02X", result[i]];
    
    return [hash lowercaseString];
}

-(NSString *)httpRequestString:(NSString *)url
                    parameters:(NSDictionary *)params {
    NSMutableString *requestStr = [NSMutableString stringWithString:url];
    [requestStr appendString:@"?"];
    for (id key in params.allKeys) {
        [requestStr appendFormat:@"%@=%@&", key, [params objectForKey:key]];
    }
    if (requestStr.length > url.length + 1) {
        NSRange range = {requestStr.length - 1, 1};
        [requestStr deleteCharactersInRange:range];
    }
    return requestStr;
}

- (void)autoLoginIfLoginOverdue {
    //如果code = -11,登录过期，重新登录一次
#warning TODO:自动登录请求处理
}
@end
@implementation MKHttpFile

+ (instancetype)fileWithName:(NSString *)name
                        data:(NSData *)data
                    mimeType:(NSString *)mimeType
                    filename:(NSString *)filename {
    MKHttpFile *file = [[self alloc] init];
    file.name = name;
    file.data = data;
    file.mimeType = mimeType;
    file.filename = filename;
    return file;
}

@end
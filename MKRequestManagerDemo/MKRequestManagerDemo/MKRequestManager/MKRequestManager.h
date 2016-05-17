//
//                #####################################################
//                #                                                   #
//                #                       _oo0oo_                     #
//                #                      o8888888o                    #
//                #                      88" . "88                    #
//                #                      (| -_- |)                    #
//                #                      0\  =  /0                    #
//                #                    ___/`---'\___                  #
//                #                  .' \\|     |# '.                 #
//                #                 / \\|||  :  |||# \                #
//                #                / _||||| -:- |||||- \              #
//                #               |   | \\\  -  #/ |   |              #
//                #               | \_|  ''\---/''  |_/ |             #
//                #               \  .-\__  '-'  ___/-. /             #
//                #             ___'. .'  /--.--\  `. .'___           #
//                #          ."" '<  `.___\_<|>_/___.' >' "".         #
//                #         | | :  `- \`.;`\ _ /`;.`/ - ` : | |       #
//                #         \  \ `_.   \_ __\ /__ _/   .-` /  /       #
//                #     =====`-.____`.___ \_____/___.-`___.-'=====    #
//                #                       `=---='                     #
//                #     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   #
//                #                                                   #
//                #               佛祖保佑         永无BUG              #
//                #                                                   #
//                #####################################################
//

//  Created by 李小争 on 16/5/16.
//  Copyright © 2016年 李小争. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFNetworking.h"


static NSString* const  WZNetWorkError = @"WZNetWorkError";

//===========================================
@interface MKRequestManager: NSObject

+ (instancetype)sharedInstance;

/**
 *  当前的网络状态
 */
@property (nonatomic) AFNetworkReachabilityStatus networkStatus;





/**
 *  宏定义请求成功的block
 *
 *  @param response 请求成功返回的数据
 */
typedef void (^MKResponseSuccess)(NSURLSessionDataTask * task,id responseObject);

/**
 *  宏定义请求失败的block
 *
 *  @param error 报错信息
 */
typedef void (^MKResponseFail)(NSURLSessionDataTask * task, NSError * error);

/**
 *  上传或者下载的进度
 *
 *  @param progress 进度
 */
typedef void (^MKProgress)(NSProgress *progress);

/**
 *  普通get方法请求网络数据
 *
 *  @param url     请求网址路径
 *  @param params  请求参数
 *  @param success 成功回调
 *  @param fail    失败回调
 */
-(void)GET:(NSString *)url
    params:(NSDictionary *)params success:(MKResponseSuccess)success
      fail:(MKResponseFail)fail;

/**
 *  普通post方法请求网络数据
 *
 *  @param url     请求网址路径
 *  @param params  请求参数
 *  @param success 成功回调
 *  @param fail    失败回调
 */
-(void)POST:(NSString *)url
     params:(NSDictionary *)params
    success:(MKResponseSuccess)success
       fail:(MKResponseFail)fail;


/**
 *  普通路径上传文件
 *
 *  @param url      请求网址路径
 *  @param params   请求参数
 *  @param files    文件数组
 *  @param progress 上传进度
 *  @param success  成功回调
 *  @param fail     失败回调
 */
-(void)uploadWithURL:(NSString *)url
              params:(NSDictionary *)params
               files:(NSArray *)files
            progress:(MKProgress)progress
             success:(MKResponseSuccess)success
                fail:(MKResponseFail)fail;


/**
 *  下载文件
 *
 *  @param url      请求网络路径
 *  @param fileURL  保存文件url
 *  @param progress 下载进度
 *  @param success  成功回调
 *  @param fail     失败回调
 *
 *  @return 返回NSURLSessionDownloadTask实例，可用于暂停继续，暂停调用suspend方法，重新开启下载调用resume方法
 */
-(NSURLSessionDownloadTask *)downloadWithURL:(NSString *)url
                                 savePathURL:(NSURL *)fileURL
                                    progress:(MKProgress )progress
                                     success:(void (^)(NSURLResponse *, NSURL *))success
                                        fail:(void (^)(NSError *))fail;
@end


@interface MKHttpFile : NSObject

/** 文件参数名(key) */
@property(nonatomic, copy) NSString *name;
/** 文件数据 */
@property(nonatomic, strong) NSData *data;
/** 文件类型 */
@property(nonatomic, copy) NSString *mimeType;
/** 文件名 */
@property(nonatomic, copy) NSString *filename;

+ (instancetype)fileWithName:(NSString *)name
                        data:(NSData *)data
                    mimeType:(NSString *)mimeType
                    filename:(NSString *)filename;
@end
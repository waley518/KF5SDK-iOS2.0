//
//  KFConfig.h
//  Pods
//
//  Created by admin on 16/10/9.
//
//

#import <Foundation/Foundation.h>

@interface KFConfig : NSObject

/**
 云客服域名,不能为空
 */
@property (nonnull, nonatomic, copy) NSString *hostName;
/**
 公司密钥,不能为空
 */
@property (nonnull, nonatomic, copy) NSString *appId;
/**
 初始化方法

 @return 返回唯一KFConfig实例对象
 */
+ (nonnull instancetype)shareConfig;

/**
 SDK沙盒路径
 */
+ (nonnull NSString *)dataDefaultPath;
/**
 初始化信息

 @param hostName  云客服域名
 @param appId     公司密钥
 */
- (void)initializeWithHostName:(nonnull NSString *)hostName appId:(nonnull NSString *)appId;

/**
 获取当前SDK的版本(当前SDK版本为2.11.2)

 @return 版本号
 */
- (nonnull NSString *)version;

@end

//
//  GQSecretImageHandler.h
//  Pods
//
//  Created by 林国强 on 16/6/6.
//
//

#import <Foundation/Foundation.h>
#import "GQSecretImageModel.h"

typedef void(^GQSecretImageHandlerSetting)(GQSecretImageModel *model);

@interface GQSecretImageHandler : NSObject

+ (instancetype)sharedInstance;

- (void)activeWtihSetting:(GQSecretImageHandlerSetting)setting;

- (void)stop;

@end

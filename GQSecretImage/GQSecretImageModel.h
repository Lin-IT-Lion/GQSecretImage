//
//  GQSecretImageModel.h
//  Pods
//
//  Created by 林国强 on 16/6/7.
//
//

#import <Foundation/Foundation.h>

@interface GQSecretImageModel : NSObject

@property (nonatomic, copy) NSString *secretImageText;

@property (nonatomic, copy) dispatch_block_t noAlbumAuthorizedBlock;

@end

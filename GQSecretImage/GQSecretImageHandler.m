//
//  GQSecretImageHandler.m
//  Pods
//
//  Created by 林国强 on 16/6/6.
//
//

#import "GQSecretImageHandler.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

NSString *const GQSecretImageHandlerFlagString = @"***===***";


#define GQSecretImageHandlerImageCollectionName [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"]
@interface GQSecretImageHandler()
@property (nonatomic, assign, getter = isStar)BOOL star;
@property (nonatomic, strong) GQSecretImageModel *model;
@property (nonatomic, copy) GQSecretImageHandlerSetting setting;
@end

@implementation GQSecretImageHandler

static GQSecretImageHandler *sharedInstance;

+ (void)load
{
    [self createAlbum];
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(takeScreenshot) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    });
    return sharedInstance;
}

+ (void)createAlbum
{
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_8_0) {
        BOOL haveAlbum = NO;
        // 列出所有用户创建的相册
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        for (PHAssetCollection *collection in topLevelUserCollections) {
            if ([collection.localizedTitle isEqualToString:GQSecretImageHandlerImageCollectionName]) {
                haveAlbum = YES;
                break;
            }
        }
        if (!haveAlbum) {
            PHPhotoLibrary *photoLibrar = [PHPhotoLibrary sharedPhotoLibrary];
            [photoLibrar performChanges:^{
                NSString *title = GQSecretImageHandlerImageCollectionName;
                [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
            } completionHandler:^(BOOL success, NSError * _Nullable error) {
                
            }];
        }
    } else {
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        NSMutableArray *groups = [NSMutableArray array];
        [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group) {
                [groups addObject:group];
            } else {
                BOOL haveAlbum = NO;
                for (ALAssetsGroup *groupItems in groups) {
                    NSString *name = [groupItems valueForProperty:ALAssetsGroupPropertyName];
                    if ([name isEqualToString:GQSecretImageHandlerImageCollectionName]) {
                        haveAlbum = YES;
                    }
                }
                if (!haveAlbum) {
                    [assetsLibrary addAssetsGroupAlbumWithName:GQSecretImageHandlerImageCollectionName resultBlock:^(ALAssetsGroup *group) {
                        [groups addObject:group];
                    } failureBlock:^(NSError *error) {
                        
                    }];
                }
            }
        } failureBlock:^(NSError *error) {
            
        }];
    }
}

- (GQSecretImageModel *)model
{
    if (_model == nil) {
        _model = [[GQSecretImageModel alloc] init];
    }
    return _model;
}

- (instancetype)init
{
    if (sharedInstance != nil) {
        return nil;
    }
    if ((self = [super init])) {
    }
    return self;
}

- (void)activeWtihSetting:(GQSecretImageHandlerSetting)setting
{
    self.star = YES;
    self.setting = setting;
}

- (void)stop
{
    self.star = NO;
}

- (void)takeScreenshot
{
    if (self.isStar) {
        [self saveImage];
    }
}

- (void)saveImage
{
    NSData *data = [self transformSecretImageToData:[self screenView]];
    [self saveSecretImageData:data];
}

- (UIImage*)screenView
{
    CGSize imageSize = CGSizeZero;
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(orientation))
        imageSize = [UIScreen mainScreen].bounds.size;
    else
        imageSize = CGSizeMake([UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (UIWindow *window in [[UIApplication sharedApplication] windows])
    {
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, window.center.x, window.center.y);
        CGContextConcatCTM(context, window.transform);
        CGContextTranslateCTM(context, -window.bounds.size.width * window.layer.anchorPoint.x, -window.bounds.size.height * window.layer.anchorPoint.y);
        if (orientation == UIInterfaceOrientationLandscapeLeft)
        {
            CGContextRotateCTM(context, M_PI_2);
            CGContextTranslateCTM(context, 0, -imageSize.width);
        }
        else if (orientation == UIInterfaceOrientationLandscapeRight)
        {
            CGContextRotateCTM(context, -M_PI_2);
            CGContextTranslateCTM(context, -imageSize.height, 0);
        } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            CGContextRotateCTM(context, M_PI);
            CGContextTranslateCTM(context, -imageSize.width, -imageSize.height);
        }
        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)])
        {
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
        }
        else
        {
            [window.layer renderInContext:context];
        }
        
        CGContextRestoreGState(context);
    }
    
    [self updateModel];
    
    if (self.model.showInfoText.length > 0) {
        
        [self.model.showInfoText drawInRect:CGRectMake(0, 22, imageSize.width, imageSize.height - 22) withAttributes:self.model.showInfoTextAttrs];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)latestImage
{
    typeof(self) __weak selfVc = self;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_8_4) {
        // 获取所有资源的集合，并按资源的创建时间排序
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
        PHAsset *asset = [assetsFetchResults firstObject];
        PHImageManager *manager = [PHCachingImageManager defaultManager];
        [manager requestImageDataForAsset:asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            NSData *data = [selfVc transformSecretImageToData:[UIImage imageWithData:imageData]];
            [selfVc saveSecretImageData:data];
        }];
    } else {
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group) {
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    if (result) {
                        CGImageRef ref = [[result defaultRepresentation] CGImageWithOptions:nil];
                        UIImage *image = [UIImage imageWithCGImage:ref];
                        NSData *data = [selfVc transformSecretImageToData:image];
                        [selfVc saveSecretImageData:data];
                        *stop = YES;
                    }
                }];
                *stop = YES;
            }
        } failureBlock:^(NSError *error) {

        }];
    }

}

- (NSData *)transformSecretImageToData:(UIImage *)image
{
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
    [self updateModel];
    NSData *stringData = [[NSString stringWithFormat:@"\n\n\n%@%@%@",GQSecretImageHandlerFlagString,self.model.secretImageText,GQSecretImageHandlerFlagString] dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *data = [NSMutableData data];
    [data appendData:imageData];
    [data appendData:stringData];
    
    return data;
}

- (BOOL)allowAlbum
{
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_8_4) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status != PHAuthorizationStatusNotDetermined && status != PHAuthorizationStatusAuthorized) {
            if (self.model.noAlbumAuthorizedBlock) {
                self.model.noAlbumAuthorizedBlock();
            }
             return NO;
        }
    } else {
        ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
        if (author != ALAuthorizationStatusAuthorized && author != ALAuthorizationStatusNotDetermined) {
            if (self.model.noAlbumAuthorizedBlock) {
                self.model.noAlbumAuthorizedBlock();
            }
            return NO;
        }
    }
    return YES;
}



- (void)saveSecretImageData:(NSData *)imageData
{
    if ([self allowAlbum] == NO) {
        return;
    }
    [GQSecretImageHandler createAlbum];
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_8_4) {
        __block NSString *createdAssetId;
        PHPhotoLibrary *photoLibrar = [PHPhotoLibrary sharedPhotoLibrary];
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        for (PHAssetCollection *collection in topLevelUserCollections) {
            if ([collection.localizedTitle isEqualToString:GQSecretImageHandlerImageCollectionName]) {
                [photoLibrar performChanges:^{
                    PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                    [request addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
                    createdAssetId = request.placeholderForCreatedAsset.localIdentifier;
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    PHFetchResult<PHAsset *> *list = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetId] options:nil];
                    [photoLibrar performChanges:^{
                        PHAssetCollectionChangeRequest *changAssetRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
                        [changAssetRequest addAssets:list];
                    } completionHandler:^(BOOL success, NSError * _Nullable error) {
                        
                    }];
                    
                }];
                break;
            }
        }
    } else {
        ALAssetsLibrary *libary = [[ALAssetsLibrary alloc] init];
        typeof(ALAssetsLibrary *) __weak weakLibary = libary;
        [libary writeImageDataToSavedPhotosAlbum:imageData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            if (error) {
                NSLog(@"Save image fail：%@",error);
            }else{
                [weakLibary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                    [weakLibary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                        NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
                        if ([name isEqualToString:GQSecretImageHandlerImageCollectionName]) {
                            [group addAsset:asset];
                            *stop = YES;
                        }
                    } failureBlock:^(NSError *error) {
                        
                    }];
                } failureBlock:^(NSError *error) {
                    
                }];
            }
        }];
    }
}

- (void)updateModel
{
    if (self.setting) {
        self.setting(self.model);
    }
}

@end

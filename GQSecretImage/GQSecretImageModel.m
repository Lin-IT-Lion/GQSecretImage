//
//  GQSecretImageModel.m
//  Pods
//
//  Created by 林国强 on 16/6/7.
//
//

#import "GQSecretImageModel.h"

@implementation GQSecretImageModel

- (NSDictionary *)showInfoTextAttrs
{
    if (_showInfoTextAttrs == nil) {
        _showInfoTextAttrs = @{NSFontAttributeName : [UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[UIColor blackColor], NSStrokeColorAttributeName : [UIColor whiteColor], NSStrokeWidthAttributeName :@(-3)};
    }
    return _showInfoTextAttrs;
}

@end

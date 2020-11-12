//
//  TIoTAddManualIntelligentVC.h
//  LinkApp
//
//  Created by ccharlesren on 2020/11/2.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TIoTIntelligentProductConfigModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IntelligentActioinType) {
    IntelligentActioinTypeManual,
    IntelligentActioinTypeDelay,
    IntelligentActioinTypeNotice,
    IntelligentActioinTypeTimer,
};

/**
 手动智能列表主页 （空白时，可直接添加）
 */
@interface TIoTAddManualIntelligentVC : UIViewController
@property (nonatomic, strong) NSMutableArray <TIoTPropertiesModel*>*taskArray;
@property (nonatomic, strong) NSMutableArray <NSString *>*valueArray;
@property (nonatomic, strong) TIoTIntelligentProductConfigModel *productModel;
//@property (nonatomic, strong) NSMutableArray <TIoTIntelligentProductConfigModel *>*productModelArray;

@property (nonatomic, strong) NSString *delayTimeString;
@property (nonatomic, assign) IntelligentActioinType actionType;
@property (nonatomic, assign) NSInteger valueStringIndexPath;
@property (nonatomic, assign) BOOL isEdited;
@property (nonatomic, strong) NSString *valueString;

- (void)refreshData;
@end

NS_ASSUME_NONNULL_END
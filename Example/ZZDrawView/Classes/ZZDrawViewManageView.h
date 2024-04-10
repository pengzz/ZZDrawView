//
//  ZZDrawViewManageView.h
//  ZZDrawView_Example
//
//  Created by PengZhiZhong on 2018/12/17.
//  Copyright © 2018 pengzz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZZDrawView.h"
#import "ZZDrawViewSettingBoard.h"

NS_ASSUME_NONNULL_BEGIN

/**
 绘画管理总view
 */
@interface ZZDrawViewManageView : UIView
@property(nonatomic, strong) UIImageView *bgImgView;//暂无用
@property(nonatomic, strong) ZZDrawView *drawView;
@property(nonatomic, strong) ZZDrawViewSettingBoard *settingBoard;

//完成回调
@property(nonatomic, copy) void(^completeBtnBlock)(ZZDrawViewManageView *view);
@end

NS_ASSUME_NONNULL_END

//
//  ZZDrawViewSettingBoard.h
//  ZZDrawView_Example
//
//  Created by PengZhiZhong on 2018/12/17.
//  Copyright © 2018 pengzz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZZDrawView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZZDrawViewSettingBoard : UIView
@property(nonatomic, retain)ZZDrawView *drawView;
@end


//画笔展示的球
@interface ZZColorBall : UIView
@property (nonatomic, strong) UIColor *ballColor;
@property (nonatomic, assign) CGFloat ballSize;
@property (nonatomic, assign) CGFloat lineWidth;
@end


NS_ASSUME_NONNULL_END

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

typedef NS_ENUM(NSInteger,setType) {
    setTypePen,
    setTypeCamera,
    setTypeAlbum,
    setTypeSave,
    setTypeEraser,
    setTypeBack,
    setTyperegeneration,
    setTypeClearAll
};

//typedef void(^boardSettingBlock)(setType type);

@interface ZZDrawViewSettingBoard : UIView
@property(nonatomic, retain)ZZDrawView *drawView;
//- (void)getSettingType:(void(^)(setType type))type;
//- (CGFloat)getLineWidth;
//- (UIColor *)getLineColor;
@end


//画笔展示的球
@interface ZZColorBall : UIView
@property (nonatomic, strong) UIColor *ballColor;
@property (nonatomic, assign) CGFloat ballSize;
@property (nonatomic, assign) CGFloat lineWidth;
@end


NS_ASSUME_NONNULL_END

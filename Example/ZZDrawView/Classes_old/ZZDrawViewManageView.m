//
//  ZZDrawViewManageView.m
//  ZZDrawView_Example
//
//  Created by PengZhiZhong on 2018/12/17.
//  Copyright © 2018 pengzz. All rights reserved.
//

#import "ZZDrawViewManageView.h"
#import "ZZDrawView.h"
#import "ZZDrawViewSettingBoard.h"

@interface  ZZDrawViewManageView()
@property(nonatomic, strong) UIImageView *bgImgView;
@property(nonatomic, strong) ZZDrawView *drawView;
@property(nonatomic, strong) ZZDrawViewSettingBoard *settingBoard;
@end

@implementation ZZDrawViewManageView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubViews];
    }
    return self;
}

- (void)initSubViews {
    self.bgImgView = [UIImageView new];
    _bgImgView.frame = self.bounds;
    _bgImgView.image = [UIImage imageNamed:@"20130616030824963"];
//    [self.view addSubview:_bgImgView];
    
    
    [self addSubview:self.drawView];
    
    
    [self addSubview:self.settingBoard];
}

- (ZZDrawView *)drawView {
    if (!_drawView) {
        _drawView = [[ZZDrawView alloc] initWithFrame:self.bounds];
        _drawView.brushColor = [UIColor blueColor];
        _drawView.brushWidth = 3;
        _drawView.shapeType = ZZShapeCurve;
        _drawView.backgroundImage = [UIImage imageNamed:@"20130616030824963"];
#if DEBUG
        _drawView.backgroundImage = [UIImage imageNamed:@"zz_bg_image.png"];
#endif
    }
    return _drawView;
}

- (ZZDrawViewSettingBoard *)settingBoard {
    if (!_settingBoard) {
        _settingBoard = [[ZZDrawViewSettingBoard alloc] initWithFrame:CGRectMake(0, 1*(CGRectGetMaxY(self.bounds)-200), CGRectGetMaxX(self.bounds), 200)];
        _settingBoard.drawView = self.drawView;
    }
    return _settingBoard;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

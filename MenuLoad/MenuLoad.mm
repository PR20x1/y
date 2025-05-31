#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>

#include "Includes.h"
#include "../Cheat/Aimbot.hpp"
#include "../Cheat/Cheat.hpp"
@interface MenuLoad()

@property (nonatomic, strong) ImGuiDrawView *vna;
@property (nonatomic, strong) UIImage *cachedAnimatedImage;

- (ImGuiDrawView*) GetImGuiView;

@end

static MenuLoad *extraInfo;

UIButton* InvisibleMenuButton;
UIButton* VisibleMenuButton;
MenuInteraction* menuTouchView;
UITextField* hideRecordTextfield;
UIView* hideRecordView;

ImFont* IconFont;

@interface MenuInteraction()

@end

@implementation MenuInteraction

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    ImGuiContext* Context = ImGui::GetCurrentContext();
    
    if (Context)
    {
        const ImVector<ImGuiWindow*>& Windows = Context->Windows;
        for (int i = 0; i < Windows.Size; ++i)
        {
            ImGuiWindow* CurrentWindow = Windows[i];
            if (!CurrentWindow)
                continue;

            if (CurrentWindow->Active && !(CurrentWindow->Flags & ImGuiWindowFlags_NoInputs))
            {
                CGRect touchableArea = CGRectMake(CurrentWindow->Pos.x, CurrentWindow->Pos.y, CurrentWindow->Size.x, CurrentWindow->Size.y);
                if (CGRectContainsPoint(touchableArea, point)) {
                    return [super pointInside:point withEvent:event];
                }
            }
        }
    }
    return NO;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[extraInfo GetImGuiView] updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[extraInfo GetImGuiView] updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[extraInfo GetImGuiView] updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [[extraInfo GetImGuiView] updateIOWithTouchEvent:event];
}

@end


@implementation MenuLoad

bool isOpened = false;

- (ImGuiDrawView*) GetImGuiView {
    return _vna;
}

+ (void)load
{
    [super load];

    CallAfterSeconds(10)
    {
        NSLog(@"Loading settings...");
        settings.Load();
        NSLog(@"Settings loaded successfully");

        extraInfo = [MenuLoad new];
        [extraInfo initTapGes];
        NSLog(@"Menu initialized");

        Cheats::LoadMods();
    });
}

-(void)initTapGes
{
    UIView * const mainView = [UIApplication sharedApplication].windows[0].rootViewController.view;
    const CGRect screenRect = [[UIScreen mainScreen] bounds];

    hideRecordTextfield = [[UITextField alloc] init];
    hideRecordView = [[UIView alloc] initWithFrame:screenRect];
    hideRecordView.backgroundColor = [UIColor clearColor];
    hideRecordView.userInteractionEnabled = YES;
    hideRecordTextfield.secureTextEntry = YES;
    [hideRecordView addSubview:hideRecordTextfield];
    
    CALayer * const layer = hideRecordTextfield.layer;
    
    if ([layer.sublayers.firstObject.delegate isKindOfClass:[UIView class]]) {
        hideRecordView = (UIView *)layer.sublayers.firstObject.delegate;
    } else {
        hideRecordView = nil;
    }

    if (hideRecordView) {
        [[UIApplication sharedApplication].windows.firstObject addSubview:hideRecordView];
    }
    
    if (!_vna) {
        _vna = [[ImGuiDrawView alloc] init];
    }
    
    [ImGuiDrawView showChange:NO];
    [hideRecordView addSubview:_vna.view];

    menuTouchView = [[MenuInteraction alloc] initWithFrame:mainView.frame];
    [mainView addSubview:menuTouchView];

    /* Provide Image or GIF URL */
    NSURL * const url = [NSURL URLWithString:@"https://www.canva.com/design/DAGo_tebX2w/R3CwS8bdiiWS_p0AZtSvsw/watch?utm_content=DAGo_tebX2w&utm_campaign=designshare&utm_medium=link2&utm_source=uniquelinks&utlId=h568cb044cf"];
    
    if (self.cachedAnimatedImage) {
        [self setupVisibleMenuButton:self.cachedAnimatedImage inMainView:mainView];
    } else {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            @autoreleasepool {
                NSData * const ImageData = [NSData dataWithContentsOfURL:url];
                if (ImageData) {
                    UIImage *animatedImage = [self ProcessImageWithData:ImageData];
                    if (animatedImage) {

                        self.cachedAnimatedImage = animatedImage;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self setupVisibleMenuButton:animatedImage inMainView:mainView];
                        });
                    }
                }
            }
        });
    }
    
    InvisibleMenuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    InvisibleMenuButton.frame = CGRectMake(CGRectGetMidX(mainView.frame) - 25, CGRectGetMidY(mainView.frame) - 25, 75, 75);
    InvisibleMenuButton.backgroundColor = [UIColor clearColor];
    [InvisibleMenuButton addTarget:self action:@selector(buttonDragged:withEvent:) forControlEvents:UIControlEventTouchDragInside];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showMenu:)];
    [InvisibleMenuButton addGestureRecognizer:tapGestureRecognizer];
    [mainView addSubview:InvisibleMenuButton];
}

- (void)setupVisibleMenuButton:(UIImage *)image inMainView:(UIView *)mainView {
    VisibleMenuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    VisibleMenuButton.frame = CGRectMake(CGRectGetMidX(mainView.frame) - 25, CGRectGetMidY(mainView.frame) - 25, 75, 75);
    VisibleMenuButton.backgroundColor = [UIColor clearColor];
    VisibleMenuButton.layer.cornerRadius = 25.0f;
    VisibleMenuButton.clipsToBounds = YES;
    [VisibleMenuButton setImage:image forState:UIControlStateNormal];
    [hideRecordView addSubview:VisibleMenuButton];
}

- (UIImage * _Nullable)ProcessImageWithData:(NSData * _Nonnull)data {
    if (!data) return nil;
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) return nil;
    
    size_t count = CGImageSourceGetCount(source);
    NSMutableArray<UIImage *> *images = [NSMutableArray arrayWithCapacity:count];
    NSTimeInterval duration = 0.0f;
    
    for (size_t i = 0; i < count; i++) {
        @autoreleasepool {
            const CGImageRef _Nullable imageRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
            if (!imageRef) continue;
            
            NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
            NSDictionary *gifProperties = properties[(NSString * _Nonnull)kCGImagePropertyGIFDictionary];
            
            NSNumber *delayTime = gifProperties[(NSString * _Nonnull)kCGImagePropertyGIFUnclampedDelayTime];
            if (!delayTime)
                delayTime = gifProperties[(NSString * _Nonnull)kCGImagePropertyGIFDelayTime];
            
            if (delayTime.floatValue < 0.011f)
                delayTime = @(0.100f);
            
            duration += delayTime.floatValue;
            
            UIImage *frameImage = [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
            [images addObject:frameImage];
            
            CGImageRelease(imageRef);
        }
    }
    
    CFRelease(source);
    
    if (duration == 0.0f)
        duration = (1.0f / 10.0f) * count;
    
    return [UIImage animatedImageWithImages:images duration:duration];
}

-(void)showMenu:(UITapGestureRecognizer *)tapGestureRecognizer {
    if(tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [ImGuiDrawView showChange:![ImGuiDrawView isMenuShowing]];
    }
}

- (void)buttonDragged:(UIButton *)button withEvent:(UIEvent *)event {
    UITouch *touch = [[event touchesForView:button] anyObject];

    CGPoint previousLocation = [touch previousLocationInView:button];
    CGPoint location = [touch locationInView:button];
    CGFloat delta_x = location.x - previousLocation.x;
    CGFloat delta_y = location.y - previousLocation.y;

    button.center = CGPointMake(button.center.x + delta_x, button.center.y + delta_y);
    
    CGRect mainFrame = [UIApplication sharedApplication].windows[0].rootViewController.view.bounds;
    if(button.center.x < 0) button.center = CGPointMake(0,button.center.y);
    if(button.center.y < 0) button.center = CGPointMake(button.center.x,0);
    if(button.center.y > mainFrame.size.height) button.center = CGPointMake(button.center.x,mainFrame.size.height);
    if(button.center.x > mainFrame.size.width) button.center = CGPointMake(mainFrame.size.width,button.center.y);
    
    VisibleMenuButton.center = button.center;
    VisibleMenuButton.frame = button.frame;
}

@end

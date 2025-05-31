#include "Includes.h"
#include "../Resources/Fonts.h"
#include "../Menu/UserMenu.h"
#include "../Cheat/GameAPI.hpp"
#include "../Cheat/CheatState.hpp"
#include "../Cheat/Aimbot.hpp"
#include "../Cheat/ESP.hpp"

@interface ImGuiDrawView () <MTKViewDelegate>

@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;

@end

@implementation ImGuiDrawView

static bool MenDeal = true;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];
    
    if (!self.device) abort();
    
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiStyle &style = ImGui::GetStyle();
    ImGuiIO& io = ImGui::GetIO(); (void)io;

    io.Fonts->Clear();
    
    // / / // / / // / / / / / / / // / / / / // / / // / / // // // / / // / / /// / // / / / /
    
    FontRanges &ranges = FontRanges::GetInstance();
    
    ImFontConfig font_config; font_config.FontDataOwnedByAtlas = false; /* font_config.PixelSnapH = true; */
    // font_config.FontBuilderFlags |= ImGuiFreeTypeBuilderFlags::ImGuiFreeTypeBuilderFlags_ForceAutoHint;
    io.Fonts->AddFontFromMemoryCompressedTTF(NSMFont_compressed_data, NSMFont_compressed_size, 17.f, &font_config, ranges.latin_ranges);
    
    // ImFontConfig china_config;
    // china_config.MergeMode = true; /* china_config.PixelSnapH = true; */ china_config.FontDataOwnedByAtlas = false;
    // china_config.FontBuilderFlags |= ImGuiFreeTypeBuilderFlags::ImGuiFreeTypeBuilderFlags_ForceAutoHint;
    // io.Fonts->AddFontFromMemoryCompressedTTF(DRGFont_compressed_data, DRGFont_compressed_size, 12.f, &china_config, io.Fonts->GetGlyphRangesChineseFull());
    
    ImFontConfig fa_config; fa_config.MergeMode = true; fa_config.PixelSnapH = true; fa_config.FontDataOwnedByAtlas = false;
    // fa_config.FontBuilderFlags |= ImGuiFreeTypeBuilderFlags::ImGuiFreeTypeBuilderFlags_ForceAutoHint;
    io.Fonts->AddFontFromMemoryCompressedTTF(fa6_solid_compressed_data, fa6_solid_compressed_size, 14.f, &fa_config, ranges.icons_ranges_max);
    // io.Fonts->AddFontFromMemoryCompressedTTF(fa_brands_400_compressed_data, fa_brands_400_compressed_size, 14.f, &fa_config, ranges.icons_ranges_brands);
    
    ImFontConfig icons_config; icons_config.PixelSnapH = true; icons_config.FontDataOwnedByAtlas = false;
    // icons_config.FontBuilderFlags |= ImGuiFreeTypeBuilderFlags::ImGuiFreeTypeBuilderFlags_ForceAutoHint;
    IconFont = io.Fonts->AddFontFromMemoryCompressedTTF(fa6_solid_compressed_data, fa6_solid_compressed_size, 18.f, &icons_config, ranges.icons_ranges);
    // LogoFont = io.Fonts->AddFontFromMemoryCompressedTTF(NSMFont_compressed_data, NSMFont_compressed_size, IconFont->FontSize + style.WindowPadding.y * 2 + style.FramePadding.y * 2, /*NULL*/ &font_config, ranges.logo_ranges);

    ImFontConfig esp_config; esp_config.PixelSnapH = true; esp_config.MergeMode = true; esp_config.FontDataOwnedByAtlas = false;
    Font = io.Fonts->AddFontFromMemoryCompressedTTF(DRGFont_compressed_data, DRGFont_compressed_size, 28.f, &esp_config, ranges.esp_ranges); // 18.f
     
    // / / // / / // / / / / / / / /// / / / / // / / // / / // / // / / // / / /// / // / / / /

    ImGui_ImplMetal_Init(_device);

    return self;
}

+ (void)showChange:(BOOL)open
{
    MenDeal = open;
}

+ (BOOL)isMenuShowing
{
    return MenDeal;
}

- (MTKView *)mtkView
{
    return (MTKView *)self.view;
}

- (void)loadView
{
    CGFloat w = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width;
    CGFloat h = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height;
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    self.mtkView.clipsToBounds = YES;
}

- (void)updateIOWithTouchEvent:(UIEvent *)event
{
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches)
    {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled)
        {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self updateIOWithTouchEvent:event];
}

- (void)drawInMTKView:(MTKView*)view
{
    hideRecordTextfield.secureTextEntry = settings.StreamerMode;

    ImGuiIO& io = ImGui::GetIO();
    if (isIPad)
    {
        io.FontGlobalScale = 1.3f;
    }
    
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;

    CGFloat framebufferScale = view.window.screen.nativeScale ? : UIScreen.mainScreen.nativeScale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ? : 30);

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    if (MenDeal) {
        [self.view setUserInteractionEnabled:YES];
        [self.view.superview setUserInteractionEnabled:YES];
        [menuTouchView setUserInteractionEnabled:YES];
    } else {
        [self.view setUserInteractionEnabled:NO];
        [self.view.superview setUserInteractionEnabled:NO];
        [menuTouchView setUserInteractionEnabled:NO];
    }
    
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil)
    {
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"Dear ImGui Rendering"];

        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();
        
        ImFont* font = ImGui::GetFont();
        font->Scale = 12.f / font->FontSize;

        if (MenDeal)
        {
            UserMenu::GetInstance().RenderMenu();
        }
        
        // Dessiner le cercle FOV si activé
        if (CheatState::enable_circleFov) {
            // Utiliser GameAPI::FOVCircleSize comme référence principale
            CheatState::circleSizeValue = GameAPI::FOVCircleSize;
            
            ImDrawList* drawList = ImGui::GetBackgroundDrawList();
            ImVec2 center(view.bounds.size.width / 2, view.bounds.size.height / 2);
            
            // Dessiner un cercle rouge simple
            drawList->AddCircle(center, GameAPI::FOVCircleSize, IM_COL32(255, 0, 0, 255), 100, 3.0f);
        }
        
        // Activer l'aimbot si nécessaire
        if (Aimbot::isEnabled) {
            NSLog(@"Aimbot::Enable() appelé depuis ImGuiDrawView");
            Aimbot::Enable();
        }

        // Activer l'ESP si nécessaire
        if (ESP::isEnabled) {
            NSLog(@"ESP::Enable() appelé depuis ImGuiDrawView");
            ESP::Enable();
        }
                   
        ImGui::Render();
        ImDrawData* draw_data = ImGui::GetDrawData();
        ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);

        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    [commandBuffer commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size {}

@end

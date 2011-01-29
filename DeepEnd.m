#import <SpringBoard/SpringBoard.h>
#import <CaptainHook/CaptainHook.h>
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>

CHDeclareClass(SBUIController);

CHDeclareClass(SBWallpaperView);
CHDeclareClass(SBAwayController);
CHDeclareClass(SBAppSwitcherController);
CHDeclareClass(SBAlertItemsController);

static CMMotionManager *motionManager;
static double crop;
static double cropLeft;
static double rollFactor;
static double pitchFactor;
static BOOL animate;
static CGRect originalContentsRect;
static CATransform3D scaleTransform;

static void StartMotion()
{
	if (!motionManager) {
		motionManager = [[CMMotionManager alloc] init];
		motionManager.deviceMotionUpdateInterval = 1.0 / 30.0;
	}
	
	if (animate)
		[CATransaction begin];
	if (!motionManager.deviceMotionActive) {
		[motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error)
		 {
			 if (motion) {
				 CGRect contentsRect;
				 contentsRect.size.width = crop;
				 contentsRect.size.height = crop;
				 CMAttitude *attitude = motion.attitude;
				 contentsRect.origin.x = cropLeft + (((M_PI - abs(attitude.roll))/M_PI)*attitude.roll + ((M_PI - abs(attitude.yaw))/(M_PI/2))*attitude.yaw) * rollFactor;
				 contentsRect.origin.y = cropLeft + attitude.pitch * pitchFactor;
				 CALayer *layer = [[CHSharedInstance(SBUIController) wallpaperView] layer];
				 layer.contentsRect = contentsRect;
				 CGSize size = layer.bounds.size;
				 layer.sublayerTransform = CATransform3DTranslate(scaleTransform, (cropLeft - contentsRect.origin.x) * size.width, (cropLeft - contentsRect.origin.y) * size.height, 0);
				 if (!layer.masksToBounds)
					 layer.masksToBounds = YES;
			 }
		 }];
	}
	if (animate)
		[CATransaction commit];
}

static void StopMotion()
{
	if (motionManager.deviceMotionActive)
		[motionManager stopDeviceMotionUpdates];
}

static void ResetAndStop()
{
	StopMotion();
	if (animate)
		[CATransaction begin];
	CALayer *layer = [[CHSharedInstance(SBUIController) wallpaperView] layer];
	layer.contentsRect = originalContentsRect;
	layer.sublayerTransform = CATransform3DIdentity;
	if (animate)
		[CATransaction commit];
}	

CHOptimizedMethod(0, super, void, SBWallpaperView, didMoveToWindow)
{
	if (self == [CHSharedInstance(SBUIController) wallpaperView]) {
		if (self.window)
			StartMotion();
		else
			ResetAndStop();
	}
	CHSuper(0, SBWallpaperView, didMoveToWindow);
}

CHOptimizedMethod(0, self, void, SBAwayController, activate)
{
	ResetAndStop();
	CHSuper(0, SBAwayController, activate);
}

CHOptimizedMethod(0, self, void, SBAwayController, deactivate)
{
	CHSuper(0, SBAwayController, deactivate);
	if ([[CHSharedInstance(SBUIController) wallpaperView] window]) {
		StartMotion();
	}
}

CHOptimizedMethod(0, self, void, SBUIController, finishLaunching)
{
	CHSuper(0, SBUIController, finishLaunching);
	originalContentsRect = [[CHSharedInstance(SBUIController) wallpaperView] layer].contentsRect;
}

CHOptimizedMethod(0, self, void, SBAppSwitcherController, viewWillAppear)
{
	ResetAndStop();
	CHSuper(0,SBAppSwitcherController, viewWillAppear);
}

CHOptimizedMethod(0, self, void, SBAppSwitcherController, viewDidDisappear)
{
	StartMotion();
	CHSuper(0, SBAppSwitcherController, viewDidDisappear);
}	

CHOptimizedMethod(1, self, void, SBAlertItemsController, activateAlertItem, id, item)
{
	ResetAndStop();
	CHSuper(1, SBAlertItemsController, activateAlertItem, item);
}

CHOptimizedMethod(1, self, void, SBAlertItemsController, deactivateAlertItem, id, item)
{
	StartMotion();
	CHSuper(1, SBAlertItemsController, deactivateAlertItem, item);
}

static void LoadSettings()
{
	CHAutoreleasePoolForScope();
	NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.rpetrich.deepend.plist"];
	double depth = [[dict objectForKey:@"DEDepth"] doubleValue] ?: 0.33;
	cropLeft = depth * 0.5;
	crop = 1.0 - depth;
	scaleTransform = CATransform3DMakeScale(1.0 / crop, 1.0 / crop, 1.0);
	id temp = [dict objectForKey:@"DERollFactor"];
	rollFactor = (temp ? [temp doubleValue] : 1.0) * cropLeft * (1.0 / M_PI);
	temp = [dict objectForKey:@"DEPitchFactor"];
	pitchFactor = (temp ? [temp doubleValue] : 1.0) * cropLeft * (1.0 / M_PI);
	animate = [dict objectForKey:@"DEAnimate"] ? [[dict objectForKey:@"DEAnimate"] boolValue] : YES;
	[dict release];
}

CHConstructor {
	CHLoadLateClass(SBUIController);
	CHHook(0, SBUIController, finishLaunching);
	CHLoadLateClass(SBWallpaperView);
	CHHook(0, SBWallpaperView, didMoveToWindow);
	CHLoadLateClass(SBAwayController);
	CHHook(0, SBAwayController, activate);
	CHHook(0, SBAwayController, deactivate);
	CHLoadLateClass(SBAppSwitcherController);
	CHHook(0, SBAppSwitcherController, viewWillAppear);
	CHHook(0, SBAppSwitcherController, viewDidDisappear);
	CHLoadLateClass(SBAlertItemsController);
	CHHook(1, SBAlertItemsController, activateAlertItem);
	CHHook(1, SBAlertItemsController, deactivateAlertItem);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (void *)LoadSettings, CFSTR("com.rpetrich.deepend.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	LoadSettings();
}

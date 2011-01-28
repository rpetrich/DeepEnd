#import <SpringBoard/SpringBoard.h>
#import <CaptainHook/CaptainHook.h>
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>

CHDeclareClass(SBUIController);

CHDeclareClass(SBWallpaperView);
CHDeclareClass(SBAwayController);

static CMMotionManager *motionManager;
static double crop;
static double cropLeft;
static double rollFactor;
static double pitchFactor;
static CATransform3D scaleTransform;

static void StartMotion()
{
	if (!motionManager) {
		motionManager = [[CMMotionManager alloc] init];
		motionManager.deviceMotionUpdateInterval = 1.0 / 30.0;
	}
	if (!motionManager.deviceMotionActive) {
		[motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *motion, NSError *error)
		{
			if (motion) {
				CGRect contentsRect;
				contentsRect.size.width = crop;
				contentsRect.size.height = crop;
				CMAttitude *attitude = motion.attitude;
				contentsRect.origin.x = cropLeft + attitude.roll * rollFactor;
				contentsRect.origin.y = cropLeft + attitude.pitch * pitchFactor;
				CALayer *layer = [[CHSharedInstance(SBUIController) wallpaperView] layer];
				layer.contentsRect = contentsRect;
				CGSize size = layer.bounds.size;
				layer.sublayerTransform = CATransform3DTranslate(scaleTransform, (contentsRect.origin.x - cropLeft) * size.width, (contentsRect.origin.y - cropLeft) * size.height, 0);
			}
		}];
	}
}

static void StopMotion()
{
	if (motionManager.deviceMotionActive)
		[motionManager stopDeviceMotionUpdates];
}

CHOptimizedMethod(0, super, void, SBWallpaperView, didMoveToWindow)
{
	if (self == [CHSharedInstance(SBUIController) wallpaperView]) {
		if (self.window)
			StartMotion();
		else
			StopMotion();
	}
	CHSuper(0, SBWallpaperView, didMoveToWindow);
}

CHOptimizedMethod(0, self, void, SBAwayController, activate)
{
	StopMotion();
	CHSuper(0, SBAwayController, activate);
}

CHOptimizedMethod(0, self, void, SBAwayController, deactivate)
{
	CHSuper(0, SBAwayController, deactivate);
	if ([[CHSharedInstance(SBUIController) wallpaperView] window])
		StartMotion();
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
	[dict release];
}

CHConstructor {
	CHLoadLateClass(SBUIController);
	CHLoadLateClass(SBWallpaperView);
	CHHook(0, SBWallpaperView, didMoveToWindow);
	CHLoadLateClass(SBAwayController);
	CHHook(0, SBAwayController, activate);
	CHHook(0, SBAwayController, deactivate);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (void *)LoadSettings, CFSTR("com.rpetrich.deepend.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	LoadSettings();
}

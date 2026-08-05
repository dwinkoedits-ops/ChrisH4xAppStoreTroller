/*
 *  ChrisH4xAppStoreTroller
 *  By ChrisH4x
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

// ─── Interface declarations ───────────────────────────────────────────────────

@interface ASKSingleComponentOfferButton : UIButton
@end

@interface SKUIItemStateAction : NSObject
- (void)perform;
@end

@interface SKUIItemPageViewController : UIViewController
- (id)valueForKey:(NSString *)key;
@end

@interface SSProduct : NSObject
- (id)valueForKey:(NSString *)key;
@end

@interface SSSystemVersionController : NSObject
+ (NSString *)systemVersion;
- (NSString *)systemVersion;
@end

@interface MSPurchaseParameters : NSObject
- (id)initWithDictionary:(NSDictionary *)dict;
@end


// ─── Shared Prefs ─────────────────────────────────────────────────────────────

#define PREFS_PATH  @"/var/mobile/Library/Preferences/com.chrishax.appStoreTroller.plist"
#define NOTIF_RELOAD "com.chrishax.appStoreTroller/reload"
#define MAX_FAKE_VERSION 100

static BOOL tweakEnabled     = YES;
static NSInteger fakeVersion = 99;

static void loadPrefs(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREFS_PATH];
    if (prefs) {
        id en = prefs[@"enabled"];
        tweakEnabled = en ? [en boolValue] : YES;
        id fv = prefs[@"fakeVersion"];
        NSInteger v  = fv ? [fv integerValue] : 99;
        fakeVersion  = MAX(1, MIN(v, MAX_FAKE_VERSION));
    }
}

static void prefsChangedCallback(CFNotificationCenterRef center __unused,
                                 void *observer              __unused,
                                 CFStringRef name            __unused,
                                 const void *object          __unused,
                                 CFDictionaryRef userInfo    __unused) {
    loadPrefs();
}

static void saveHistory(NSString *appName, NSString *bundleID) {
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH]
                                  ?: [NSMutableDictionary dictionary];
    NSMutableArray *history = [NSMutableArray arrayWithArray:prefs[@"history"] ?: @[]];
    NSDictionary *entry = @{
        @"appName":     appName  ?: @"Unknown",
        @"bundleID":    bundleID ?: @"",
        @"usedVersion": @(fakeVersion),
        @"date":        [NSDate date].description
    };
    [history insertObject:entry atIndex:0];
    if (history.count > 50) [history removeLastObject];
    prefs[@"history"] = history;
    [prefs writeToFile:PREFS_PATH atomically:YES];
}


// ─── Version Picker (forward declaration) ────────────────────────────────────

static void showVersionPicker(UIView *sourceView, void (^onChosen)(NSInteger));


// ─── UIDevice spoof ───────────────────────────────────────────────────────────

%hook UIDevice

- (NSString *)systemVersion {
    if (!tweakEnabled) return %orig;
    return [NSString stringWithFormat:@"%ld.0", (long)fakeVersion];
}

- (NSString *)systemName {
    if (!tweakEnabled) return %orig;
    return @"iPhone OS";
}

%end


// ─── NSProcessInfo spoof ──────────────────────────────────────────────────────

%hook NSProcessInfo

- (NSOperatingSystemVersion)operatingSystemVersion {
    if (!tweakEnabled) return %orig;
    NSOperatingSystemVersion v;
    v.majorVersion = fakeVersion;
    v.minorVersion = 0;
    v.patchVersion = 0;
    return v;
}

- (BOOL)isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion)version {
    if (!tweakEnabled) return %orig;
    if ((NSInteger)version.majorVersion > fakeVersion) return NO;
    return YES;
}

%end


// ─── ASKSingleComponentOfferButton long-press ────────────────────────────────

static NSString *currentAppName  = nil;
static NSString *currentBundleID = nil;

%hook ASKSingleComponentOfferButton

- (void)layoutSubviews {
    %orig;
    if (!tweakEnabled) return;

        for (UIGestureRecognizer *gr in self.gestureRecognizers) {
        if ([gr isKindOfClass:[UILongPressGestureRecognizer class]] &&
            ((UILongPressGestureRecognizer *)gr).minimumPressDuration == 3.0) return;
    }

    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(chx_longPressGetButton:)];
    lp.minimumPressDuration = 3.0;
    [self addGestureRecognizer:lp];
}

%new
- (void)chx_longPressGetButton:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *gen = [[UIImpactFeedbackGenerator alloc]
            initWithStyle:UIImpactFeedbackStyleMedium];
        [gen impactOccurred];
    }

    showVersionPicker((UIView *)self, ^(NSInteger chosen) {
        fakeVersion = chosen;
        NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH]
                                      ?: [NSMutableDictionary dictionary];
        prefs[@"fakeVersion"] = @(chosen);
        [prefs writeToFile:PREFS_PATH atomically:YES];
    });
}

%end


// ─── Version Picker UI ────────────────────────────────────────────────────────

static void showVersionPicker(UIView *sourceView __unused, void (^onChosen)(NSInteger)) {
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (root.presentedViewController) root = root.presentedViewController;

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"🎭 ChrisH4xAppStoreTroller"
        message:@"Choisir ta fausse version iOS\n(1 → 100 max)"
        preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder  = [NSString stringWithFormat:@"Actuel: %ld (défaut: 99)", (long)fakeVersion];
        tf.keyboardType = UIKeyboardTypeNumberPad;
        tf.text         = [NSString stringWithFormat:@"%ld", (long)fakeVersion];
    }];

    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"✅ Appliquer"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSInteger v = [alert.textFields.firstObject.text integerValue];

        if (v < 1 || v > MAX_FAKE_VERSION) {
            UIAlertController *err = [UIAlertController
                alertControllerWithTitle:@"🚫 Limite dépassée"
                message:[NSString stringWithFormat:@"Max iOS %d. T'as tapé: %ld", MAX_FAKE_VERSION, (long)v]
                preferredStyle:UIAlertControllerStyleAlert];
            [err addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [root presentViewController:err animated:YES completion:nil];
            return;
        }

        if (onChosen) onChosen(v);

        UIAlertController *done = [UIAlertController
            alertControllerWithTitle:@"ChrisH4xAppStoreTroller"
            message:[NSString stringWithFormat:@"Version iOS spoofée: %ld.0 ✅", (long)v]
            preferredStyle:UIAlertControllerStyleAlert];
        [done addAction:[UIAlertAction actionWithTitle:@"Top 🔥" style:UIAlertActionStyleDefault handler:nil]];
        [root presentViewController:done animated:YES completion:nil];
    }];

    [alert addAction:ok];
    [alert addAction:[UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil]];
    [root presentViewController:alert animated:YES completion:nil];
}


// ─── SKUIItemPageViewController — grab app info ───────────────────────────────

%hook SKUIItemPageViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (!tweakEnabled) return;
    @try {
        id item         = [self valueForKey:@"_item"];
        currentAppName  = [item valueForKey:@"name"] ?: [item valueForKey:@"title"];
        currentBundleID = [item valueForKey:@"bundleIdentifier"];
    } @catch (...) {}
}

%end


// ─── SSProduct — grab bundle ID ───────────────────────────────────────────────

%hook SSProduct

- (void)setItemIdentifier:(id)identifier {
    %orig;
    @try {
        NSString *bid = [self valueForKey:@"bundleIdentifier"];
        if (bid) currentBundleID = bid;
    } @catch (...) {}
}

%end


// ─── SKUIItemStateAction — log install history ────────────────────────────────

%hook SKUIItemStateAction

- (void)perform {
    if (tweakEnabled && currentAppName) saveHistory(currentAppName, currentBundleID);
    %orig;
}

%end


// ─── SSSystemVersionController spoof ─────────────────────────────────────────

%hook SSSystemVersionController

+ (NSString *)systemVersion {
    if (!tweakEnabled) return %orig;
    return [NSString stringWithFormat:@"%ld.0.0", (long)fakeVersion];
}

- (NSString *)systemVersion {
    if (!tweakEnabled) return %orig;
    return [NSString stringWithFormat:@"%ld.0.0", (long)fakeVersion];
}

%end


// ─── MSPurchaseParameters — patch XPC payload ────────────────────────────────

%hook MSPurchaseParameters

- (id)initWithDictionary:(NSDictionary *)dict {
    if (tweakEnabled && dict) {
        NSMutableDictionary *m = [dict mutableCopy];
        m[@"systemVersion"]   = [NSString stringWithFormat:@"%ld.0", (long)fakeVersion];
        m[@"platformVersion"] = [NSString stringWithFormat:@"%ld.0", (long)fakeVersion];
        return %orig(m);
    }
    return %orig(dict);
}

%end


// ─── Constructor ──────────────────────────────────────────────────────────────

%ctor {
    @autoreleasepool {
        loadPrefs();
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            NULL,
            prefsChangedCallback,
            CFSTR(NOTIF_RELOAD),
            NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately
        );
    }
}

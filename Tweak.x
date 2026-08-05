#import <UIKit/UIKit.h>

static BOOL tweakEnabled = YES;
static BOOL isSpoofingActive = NO;
#define PREF_PATH @"/var/mobile/Library/Preferences/com.chrish4x.appstoretroller.plist"

// --- GESTION DES PARAMÈTRES ---
static void loadPreferences() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    if (prefs) {
        tweakEnabled = prefs[@"isEnabled"] ? [prefs[@"isEnabled"] boolValue] : YES;
        isSpoofingActive = prefs[@"isSpoofingActive"] ? [prefs[@"isSpoofingActive"] boolValue] : NO;
    } else {
        tweakEnabled = YES;
        isSpoofingActive = NO;
    }
}

static void setSpoofingState(BOOL active) {
    isSpoofingActive = active;
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREF_PATH] ?: [NSMutableDictionary dictionary];
    [prefs setObject:@(active) forKey:@"isSpoofingActive"];
    [prefs writeToFile:PREF_PATH atomically:YES];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.chrish4x.appstoretroller/ReloadPrefs"), NULL, NULL, true);
}

// --- AFFICHAGE DU TOAST ---
static void showChrisH4xToast(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;
        
        UILabel *toastLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, window.frame.size.height - 120, window.frame.size.width - 40, 50)];
        toastLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.85];
        toastLabel.textColor = [UIColor whiteColor];
        toastLabel.textAlignment = NSTextAlignmentCenter;
        toastLabel.font = [UIFont boldSystemFontOfSize:14.0];
        toastLabel.text = message;
        toastLabel.layer.cornerRadius = 25;
        toastLabel.clipsToBounds = YES;
        toastLabel.alpha = 0.0;
        
        [window addSubview:toastLabel];
        
        [UIView animateWithDuration:0.5 animations:^{
            toastLabel.alpha = 1.0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 delay:2.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                toastLabel.alpha = 0.0;
            } completion:^(BOOL finished) {
                [toastLabel removeFromSuperview];
            }];
        }];
    });
}

// --- HOOKS DE SPOOFING ---
%hook UIDevice
- (NSString *)systemVersion {
    if (tweakEnabled && isSpoofingActive) return @"99.0";
    return %orig;
}
%end

%hook NSProcessInfo
- (NSOperatingSystemVersion)operatingSystemVersion {
    if (tweakEnabled && isSpoofingActive) {
        NSOperatingSystemVersion version = %orig;
        version.majorVersion = 99;
        return version;
    }
    return %orig;
}
- (NSString *)operatingSystemVersionString {
    if (tweakEnabled && isSpoofingActive) return @"Version 99.0 (Build 99A999)";
    return %orig;
}
%end

// --- INTERCEPTION ALERTE MODERNE (UIAlertController) ---
%hook UIViewController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    if (!tweakEnabled) {
        %orig;
        return;
    }

    if ([viewControllerToPresent isKindOfClass:[UIAlertController class]]) {
        UIAlertController *alert = (UIAlertController *)viewControllerToPresent;
        NSString *message = alert.message ? alert.message.lowercaseString : @"";
        
        if ([message containsString:@"ios"] || [message containsString:@"version"] || [message containsString:@"requiert"] || [message containsString:@"compatible"]) {
            
            UIAlertController *trollAlert = [UIAlertController alertControllerWithTitle:@"ChrisH4xAppStoreTroller" 
                                                                                message:@"Alerte interceptée !\nForcer l'installation en simulant iOS 99 ?" 
                                                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:@"Accepter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                setSpoofingState(YES);
                showChrisH4xToast(@"MERCI D'AVOIR UTILISE ChrisH4xAppStoreTroller");
            }];
            UIAlertAction *refuseAction = [UIAlertAction actionWithTitle:@"Refuser" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                setSpoofingState(NO);
                %orig(viewControllerToPresent, flag, completion);
            }];
            
            [trollAlert addAction:acceptAction];
            [trollAlert addAction:refuseAction];
            
            %orig(trollAlert, flag, completion);
            return;
        }
    }
    %orig;
}
%end

// --- INTERCEPTION ALERTE ANCIENNE iOS 12 (UIAlertView) ---
%hook UIAlertView
- (void)show {
    if (!tweakEnabled) {
        %orig;
        return;
    }
    
    NSString *message = self.message ? self.message.lowercaseString : @"";
    if ([message containsString:@"ios"] || [message containsString:@"version"] || [message containsString:@"requiert"] || [message containsString:@"compatible"]) {
        
        // On bloque l'affichage de la vieille alerte et on lance notre UI moderne
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *trollAlert = [UIAlertController alertControllerWithTitle:@"ChrisH4xAppStoreTroller" 
                                                                                message:@"Alerte système interceptée !\nForcer l'installation en simulant iOS 99 ?" 
                                                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:@"Accepter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                setSpoofingState(YES);
                showChrisH4xToast(@"MERCI D'AVOIR UTILISE ChrisH4xAppStoreTroller");
            }];
            
            UIAlertAction *refuseAction = [UIAlertAction actionWithTitle:@"Refuser" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                setSpoofingState(NO);
                %orig; // Affiche l'alerte d'origine si on refuse
            }];
            
            [trollAlert addAction:acceptAction];
            [trollAlert addAction:refuseAction];
            
            UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
            if (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            [rootVC presentViewController:trollAlert animated:YES completion:nil];
        });
        return;
    }
    
    %orig;
}
%end

%ctor {
    loadPreferences();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPreferences, CFSTR("com.chrish4x.appstoretroller/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

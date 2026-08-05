#import <UIKit/UIKit.h>

static BOOL tweakEnabled = YES;
static BOOL isSpoofingActive = NO;
#define PREF_PATH @"/var/mobile/Library/Preferences/com.chrish4x.appstoretroller.plist"

// --- GESTION DES PARAMÈTRES GLOBAUX ---
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

// Sauvegarde l'état pour que les daemons (appstored) puissent le lire
static void setSpoofingState(BOOL active) {
    isSpoofingActive = active;
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREF_PATH] ?: [NSMutableDictionary dictionary];
    [prefs setObject:@(active) forKey:@"isSpoofingActive"];
    [prefs writeToFile:PREF_PATH atomically:YES];
    
    // Prévient tous les processus Apple que la version a "changé"
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

// --- HOOKS DE SPOOFING (S'applique à l'App Store ET aux Daemons) ---
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

// --- INTERCEPTION DE L'ALERTE ---
%hook UIViewController

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    if (!tweakEnabled) {
        %orig;
        return;
    }

    if ([viewControllerToPresent isKindOfClass:[UIAlertController class]]) {
        UIAlertController *alert = (UIAlertController *)viewControllerToPresent;
        
        NSString *title = alert.title ? alert.title.lowercaseString : @"";
        NSString *message = alert.message ? alert.message.lowercaseString : @"";
        
        // Détection ultra-agressive adaptée à iOS 12
        if ([message containsString:@"ios"] || [title containsString:@"ios"] || [message containsString:@"version"] || [message containsString:@"compatible"]) {
            
            UIAlertController *trollAlert = [UIAlertController alertControllerWithTitle:@"ChrisH4xAppStoreTroller" 
                                                                                message:@"L'App Store tente de bloquer cette app.\nForcer l'installation en simulant iOS 99 ?" 
                                                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:@"Accepter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                // On active le mode iOS 99 pour tout le système App Store
                setSpoofingState(YES);
                showChrisH4xToast(@"MERCI D'AVOIR UTILISE ChrisH4xAppStoreTroller");
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    showChrisH4xToast(@"Retouche le nuage pour télécharger !");
                });
            }];
            
            UIAlertAction *refuseAction = [UIAlertAction actionWithTitle:@"Refuser" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                setSpoofingState(NO);
                // On laisse l'alerte normale s'afficher
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

// --- INITIALISATION ---
%ctor {
    loadPreferences();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPreferences, CFSTR("com.chrish4x.appstoretroller/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

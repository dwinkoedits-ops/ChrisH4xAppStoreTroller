#import <UIKit/UIKit.h>

// Variables globales
static BOOL tweakEnabled = YES;
static BOOL isSpoofingActive = NO;

// Recharger les préférences (compatible Rootless/Rootful sans chemin absolu)
static void loadPreferences() {
    NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.chrish4x.appstoretroller"];
    if ([prefs objectForKey:@"isEnabled"]) {
        tweakEnabled = [prefs boolForKey:@"isEnabled"];
    } else {
        tweakEnabled = YES; // Activé par défaut
    }
}

// Fonction pour afficher le Toast
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
        
        // Animation d'apparition et disparition
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
    if (tweakEnabled && isSpoofingActive) {
        return @"99.0";
    }
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
    if (tweakEnabled && isSpoofingActive) {
        return @"Version 99.0 (Build 99A999)";
    }
    return %orig;
}
%end

// --- INTERCEPTION DE L'ALERTE DE COMPATIBILITÉ ---
%hook UIViewController

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    if (!tweakEnabled) {
        %orig;
        return;
    }

    // On vérifie si c'est une alerte de l'App Store
    if ([viewControllerToPresent isKindOfClass:[UIAlertController class]]) {
        UIAlertController *alert = (UIAlertController *)viewControllerToPresent;
        NSString *message = alert.message.lowercaseString;
        
        // Mots-clés pour détecter l'erreur d'iOS non compatible (marche en FR et EN)
        if (message && [message containsString:@"ios"] && ([message containsString:@"requiert"] || [message containsString:@"requires"])) {
            
            // On bloque l'alerte originale et on crée la nôtre
            UIAlertController *trollAlert = [UIAlertController alertControllerWithTitle:@"ChrisH4xAppStoreTroller" 
                                                                                message:@"Cette app n'est pas compatible avec ta version d'iOS.\nVeux-tu tromper l'App Store en simulant iOS 99 ?" 
                                                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *acceptAction = [UIAlertAction actionWithTitle:@"Accepter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                // On active le spoof
                isSpoofingActive = YES;
                
                showChrisH4xToast(@"MERCI D'AVOIR UTILISE ChrisH4xAppStoreTroller");
                
                // Note : On prévient l'utilisateur qu'il doit recliquer
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    showChrisH4xToast(@"Appuie à nouveau sur le nuage !");
                });
            }];
            
            UIAlertAction *refuseAction = [UIAlertAction actionWithTitle:@"Refuser" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                // On laisse l'alerte d'erreur native s'afficher
                isSpoofingActive = NO;
                %orig(viewControllerToPresent, flag, completion);
            }];
            
            [trollAlert addAction:acceptAction];
            [trollAlert addAction:refuseAction];
            
            // On affiche notre alerte modifiée à la place
            %orig(trollAlert, flag, completion);
            return;
        }
    }
    
    // Si c'est autre chose qu'une erreur de compatibilité, on laisse passer
    %orig;
}

%end

// --- INITIALISATION ---
%ctor {
    loadPreferences();
    // Écoute les changements dans les réglages pour activer/désactiver à la volée
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPreferences, CFSTR("com.chrish4x.appstoretroller/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

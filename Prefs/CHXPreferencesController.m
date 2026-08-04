/*
 *  CHXPreferencesController.m
 *  ChrisH4xAppStoreTroller – Settings panel
 *
 *  Sections:
 *   [0] Tweak toggle + fake version stepper
 *   [1] Install history (last 50 apps)
 *   [2] Clear history button
 */

#import "CHXPreferencesController.h"

#define PREFS_PATH @"/var/mobile/Library/Preferences/com.chrishax.appStoreTroller.plist"
#define NOTIF_RELOAD @"com.chrishax.appStoreTroller/reload"
#define MAX_FAKE_VERSION 100

@interface CHXPreferencesController ()
@property (nonatomic, strong) NSMutableDictionary *prefs;
@property (nonatomic, strong) NSArray            *history;
@end

@implementation CHXPreferencesController

// ─── Life-cycle ──────────────────────────────────────────────────────────────

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ChrisH4xAppStoreTroller";
    [self loadPrefs];
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.backgroundColor = [UIColor systemGroupedBackgroundColor];

    UIBarButtonItem *about = [[UIBarButtonItem alloc]
        initWithTitle:@"ℹ️" style:UIBarButtonItemStylePlain
        target:self action:@selector(showAbout)];
    self.navigationItem.rightBarButtonItem = about;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadPrefs];
    [self.tableView reloadData];
}

// ─── Prefs I/O ───────────────────────────────────────────────────────────────

- (void)loadPrefs {
    self.prefs = [[NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH]
                   mutableCopy] ?: [NSMutableDictionary dictionary];
    self.history = self.prefs[@"history"] ?: @[];
}

- (void)savePrefs {
    [self.prefs writeToFile:PREFS_PATH atomically:YES];
    // Notify tweak to reload
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        (CFStringRef)NOTIF_RELOAD, NULL, NULL, YES
    );
}

// ─── TableView DataSource ─────────────────────────────────────────────────────

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    return 3;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"⚙️  Configuration";
        case 1: return [NSString stringWithFormat:@"📋  Historique (%lu apps)", (unsigned long)self.history.count];
        case 2: return nil;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tv titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        NSInteger v = [self.prefs[@"fakeVersion"] integerValue] ?: 99;
        return [NSString stringWithFormat:
            @"Maintiens 3s le bouton 'Obtenir/Get/Installer' pour choisir une version.\n"
            @"Version actuelle spoofée: iOS %ld.0  •  Max: iOS %d", (long)v, MAX_FAKE_VERSION];
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 2;   // Toggle + Version row
        case 1: return MAX(self.history.count, 1);  // History list (or "empty" cell)
        case 2: return 1;   // Clear button
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    switch (ip.section) {

        // ── Section 0: Toggle + Version ──────────────────────────────────
        case 0: {
            if (ip.row == 0) {
                UITableViewCell *cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"toggle"];
                cell.textLabel.text = @"Activer ChrisH4xAppStoreTroller";
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                UISwitch *sw = [[UISwitch alloc] init];
                sw.on = [self.prefs[@"enabled"] boolValue] != NO;
                [sw addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = sw;
                return cell;
            } else {
                UITableViewCell *cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"version"];
                NSInteger v = [self.prefs[@"fakeVersion"] integerValue] ?: 99;
                cell.textLabel.text = @"Version iOS spoofée";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"iOS %ld.0", (long)v];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                return cell;
            }
        }

        // ── Section 1: History ────────────────────────────────────────────
        case 1: {
            if (self.history.count == 0) {
                UITableViewCell *cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"empty"];
                cell.textLabel.text = @"Aucune app installée pour l'instant 🕳️";
                cell.textLabel.textColor = [UIColor secondaryLabelColor];
                cell.textLabel.font = [UIFont italicSystemFontOfSize:14];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                return cell;
            }
            UITableViewCell *cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"histItem"];
            NSDictionary *entry = self.history[ip.row];
            NSString *name = entry[@"appName"] ?: @"App inconnue";
            NSString *bid  = entry[@"bundleID"] ?: @"";
            NSInteger usedV = [entry[@"usedVersion"] integerValue];
            NSString *date  = entry[@"date"] ?: @"";
            cell.textLabel.text = name;
            cell.detailTextLabel.text = [NSString stringWithFormat:
                @"%@  •  iOS %ld spoofé  •  %@", bid, (long)usedV,
                [date componentsSeparatedByString:@" +"].firstObject ?: date];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        }

        // ── Section 2: Clear ──────────────────────────────────────────────
        case 2: {
            UITableViewCell *cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"clear"];
            cell.textLabel.text = @"🗑️  Effacer l'historique";
            cell.textLabel.textColor = [UIColor systemRedColor];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            return cell;
        }
    }
    return [UITableViewCell new];
}

// ─── TableView Delegate ───────────────────────────────────────────────────────

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];

    // Section 0, row 1 → version picker
    if (ip.section == 0 && ip.row == 1) {
        [self showVersionPicker];
        return;
    }

    // Section 2 → clear history
    if (ip.section == 2) {
        UIAlertController *conf = [UIAlertController
            alertControllerWithTitle:@"Effacer l'historique?"
            message:@"Cette action est irréversible."
            preferredStyle:UIAlertControllerStyleActionSheet];
        [conf addAction:[UIAlertAction actionWithTitle:@"Effacer" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            self.prefs[@"history"] = @[];
            [self savePrefs];
            [self loadPrefs];
            [tv reloadData];
        }]];
        [conf addAction:[UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil]];
        conf.popoverPresentationController.sourceView = [tv cellForRowAtIndexPath:ip];
        [self presentViewController:conf animated:YES completion:nil];
    }
}

// ─── Actions ──────────────────────────────────────────────────────────────────

- (void)toggleSwitch:(UISwitch *)sw {
    self.prefs[@"enabled"] = @(sw.on);
    [self savePrefs];
}

- (void)showVersionPicker {
    NSInteger current = [self.prefs[@"fakeVersion"] integerValue] ?: 99;

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"🎭 Version iOS spoofée"
        message:[NSString stringWithFormat:
            @"Tape un numéro entre 1 et %d.\n"
            @"• iOS 99 → bypass quasi tout ✅\n"
            @"• Si app nécessite iOS 17 et tu mets 7 → message d'incompatibilité ⚠️\n"
            @"• Max autorisé: iOS %d  •  101+ bloqué 🚫", MAX_FAKE_VERSION, MAX_FAKE_VERSION]
        preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.keyboardType   = UIKeyboardTypeNumberPad;
        tf.text           = [NSString stringWithFormat:@"%ld", (long)current];
        tf.placeholder    = @"1 – 100";
        tf.clearButtonMode = UITextFieldViewModeAlways;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"✅ Appliquer" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *text = alert.textFields.firstObject.text;
        NSInteger v = [text integerValue];

        if (v < 1 || v > MAX_FAKE_VERSION) {
            UIAlertController *err = [UIAlertController
                alertControllerWithTitle:@"🚫 Hors limites"
                message:[NSString stringWithFormat:
                    @"Tu as tapé: %ld\nLa version doit être entre 1 et %d.", (long)v, MAX_FAKE_VERSION]
                preferredStyle:UIAlertControllerStyleAlert];
            [err addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:err animated:YES completion:nil];
            return;
        }

        self.prefs[@"fakeVersion"] = @(v);
        [self savePrefs];
        [self.tableView reloadData];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAbout {
    UIAlertController *a = [UIAlertController
        alertControllerWithTitle:@"ChrisH4xAppStoreTroller"
        message:@"v1.0.0 by ChrisH4x\n\n"
                 "Spoofie ta version iOS dans l'App Store.\n"
                 "Compatible : Unc0ver, Checkra1n, Palera1n, Taurine, Dopamine, Freya...\n"
                 "Rootful & Rootless • ARM & ARM64 • iOS 5–18\n\n"
                 "⚠️ Max: iOS 100. 101+ bloqué."
        preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"🔥 Let's go" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:a animated:YES completion:nil];
}

@end

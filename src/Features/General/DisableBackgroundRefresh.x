// Disable feed refresh — background refresh and home tab refresh.

#import "../../InstagramHeaders.h"
#import "../../Utils.h"
#import <objc/runtime.h>
#import <substrate.h>

static BOOL sciDisableBgRefresh(void) {
    return [SCIUtils getBoolPref:@"disable_bg_refresh"];
}

static BOOL sciDisableHomeRefresh(void) {
    return [SCIUtils getBoolPref:@"disable_home_refresh"];
}

static BOOL sciDisableHomeScroll(void) {
    return [SCIUtils getBoolPref:@"disable_home_scroll"];
}

static BOOL sciDisableReelsRefresh(void) {
    return [SCIUtils getBoolPref:@"disable_reels_tab_refresh"];
}

// Returns 999999s when disabled (effectively never), -1 to keep IG's value.
static double sciOverrideInterval(void) {
    if (sciDisableBgRefresh()) return 999999;
    return -1;
}

// MARK: - Refresh-utility class-method overrides
// IGMainFeedRefreshUtility recomputes the intervals at runtime, ignoring the
// init args on IGMainFeedNetworkSource — override the 4 class methods too.

static double (*orig_wsRefresh)(id, SEL, id, id);
static double new_wsRefresh(id self, SEL _cmd, id ls, id store) {
    double o = sciOverrideInterval();
    return o > 0 ? o : orig_wsRefresh(self, _cmd, ls, store);
}

static double (*orig_wsBgRefresh)(id, SEL, id, id);
static double new_wsBgRefresh(id self, SEL _cmd, id ls, id store) {
    double o = sciOverrideInterval();
    return o > 0 ? o : orig_wsBgRefresh(self, _cmd, ls, store);
}

static double (*orig_peakWsRefresh)(id, SEL, double, id, id);
static double new_peakWsRefresh(id self, SEL _cmd, double iv, id ls, id store) {
    double o = sciOverrideInterval();
    return o > 0 ? o : orig_peakWsRefresh(self, _cmd, iv, ls, store);
}

static double (*orig_peakWsBgRefresh)(id, SEL, id, id);
static double new_peakWsBgRefresh(id self, SEL _cmd, id ls, id store) {
    double o = sciOverrideInterval();
    return o > 0 ? o : orig_peakWsBgRefresh(self, _cmd, ls, store);
}

%ctor {
    Class c = NSClassFromString(@"IGMainFeedViewModelUtility.IGMainFeedRefreshUtility");
    if (!c) return;
    Class meta = object_getClass(c);

    SEL s1 = NSSelectorFromString(@"warmStartRefreshIntervalWithLauncherSet:feedRefreshInstructionsStore:");
    if (class_getInstanceMethod(meta, s1))
        MSHookMessageEx(meta, s1, (IMP)new_wsRefresh, (IMP *)&orig_wsRefresh);

    SEL s2 = NSSelectorFromString(@"warmStartBackgroundRefreshIntervalWithLauncherSet:feedRefreshInstructionsStore:");
    if (class_getInstanceMethod(meta, s2))
        MSHookMessageEx(meta, s2, (IMP)new_wsBgRefresh, (IMP *)&orig_wsBgRefresh);

    SEL s3 = NSSelectorFromString(@"onPeakWarmStartRefreshIntervalWithWarmStartFetchInterval:launcherSet:feedRefreshInstructionsStore:");
    if (class_getInstanceMethod(meta, s3))
        MSHookMessageEx(meta, s3, (IMP)new_peakWsRefresh, (IMP *)&orig_peakWsRefresh);

    SEL s4 = NSSelectorFromString(@"onPeakWarmStartBackgroundRefreshIntervalWithLauncherSet:feedRefreshInstructionsStore:");
    if (class_getInstanceMethod(meta, s4))
        MSHookMessageEx(meta, s4, (IMP)new_peakWsBgRefresh, (IMP *)&orig_peakWsBgRefresh);
}

// MARK: - Home tab refresh

%hook IGTabBarController

- (void)_timelineButtonPressed {
    BOOL noRefresh = sciDisableHomeRefresh();
    BOOL noScroll = sciDisableHomeScroll();

    if (!noRefresh && !noScroll) {
        %orig;
        return;
    }

    UIViewController *selected = nil;
    if ([self respondsToSelector:@selector(selectedViewController)]) {
        selected = [self valueForKey:@"selectedViewController"];
    }

    BOOL onFeedTab = NO;

    if (selected) {
        UIViewController *top =
            [selected isKindOfClass:[UINavigationController class]]
            ? [(UINavigationController *)selected topViewController]
            : selected;

        onFeedTab = [NSStringFromClass([top class]) containsString:@"MainFeed"];
    }

    if (!onFeedTab) {
        %orig;
        return;
    }

    if (noRefresh && !noScroll) {
        return;
    }

    UIViewController *top =
        [selected isKindOfClass:[UINavigationController class]]
        ? [(UINavigationController *)selected topViewController]
        : selected;

    if (!top.view) {
        return;
    }

    NSMutableArray *queue = [NSMutableArray arrayWithObject:top.view];

    int scanned = 0;

    while (queue.count && scanned < 30) {
        UIView *cur = queue.firstObject;
        [queue removeObjectAtIndex:0];

        scanned++;

        if ([cur isKindOfClass:[UICollectionView class]]) {
            UICollectionView *cv = (UICollectionView *)cur;

            [cv setContentOffset:
                CGPointMake(0, -cv.adjustedContentInset.top)
                animated:YES];

            return;
        }

        for (UIView *sub in cur.subviews) {
            [queue addObject:sub];
        }
    }
}


// MARK: - Reels tab refresh

- (void)_discoverVideoButtonPressed {

    if (!sciDisableReelsRefresh()) {
        %orig;
        return;
    }

    UIViewController *selected = nil;

    if ([self respondsToSelector:@selector(selectedViewController)]) {
        selected = [self valueForKey:@"selectedViewController"];
    }

    BOOL onReelsTab = NO;

    if (selected) {
        UIViewController *top =
            [selected isKindOfClass:[UINavigationController class]]
            ? [(UINavigationController *)selected topViewController]
            : selected;

        NSString *cls = NSStringFromClass([top class]);

        onReelsTab =
            [cls containsString:@"Sundial"] ||
            [cls containsString:@"Reels"] ||
            [cls containsString:@"DiscoverVideo"];
    }

    if (!onReelsTab) {
        %orig;
        return;
    }

    // Block refresh but keep tab switching.
}

%end
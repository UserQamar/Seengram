#import "../../Utils.h"
#import <objc/runtime.h>

// Split by _analyticsModule: "highlight" substring → highlights toggle, else stories toggle.

static BOOL sciTapIsHighlight(id target) {
    Ivar iv = class_getInstanceVariable(object_getClass(target), "_analyticsModule");
    if (!iv) return NO;

    id v = nil;

    @try {
        v = object_getIvar(target, iv);
    }
    @catch (__unused id e) {
        return NO;
    }

    if (![v isKindOfClass:[NSString class]])
        return NO;

    return [((NSString *)v).lowercaseString containsString:@"highlight"];
}


%hook IGStoryViewerTapTarget

- (void)_didTap:(id)arg1 forEvent:(id)arg2 {

    NSString *key = sciTapIsHighlight(self)
        ? @"sticker_interact_confirm_highlights"
        : @"sticker_interact_confirm";


    if ([SCIUtils getBoolPref:key]) {

        NSLog(@"[SCInsta] Sticker interaction confirmation triggered");

        [SCIUtils showConfirmation:^{
            %orig;
        }];

    } else {

        %orig;

    }
}

%end
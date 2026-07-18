#import "../../InstagramHeaders.h"
#import "../../Utils.h"

%hook IGDirectThreadCallButtonsCoordinator

- (void)_didTapAudioButton {

    if ([SCIUtils getBoolPref:@"call_confirm"]) {

        NSLog(@"[SCInsta] Confirm audio call triggered");

        [SCIUtils showConfirmation:^{
            %orig;
        }];

    } else {

        %orig;

    }
}


- (void)_didTapVideoButton {

    if ([SCIUtils getBoolPref:@"call_confirm"]) {

        NSLog(@"[SCInsta] Confirm video call triggered");

        [SCIUtils showConfirmation:^{
            %orig;
        }];

    } else {

        %orig;

    }
}

%end
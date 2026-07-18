#import "../../InstagramHeaders.h"
#import "../../Utils.h"

%hook IGPendingRequestView

- (void)_onApproveButtonTapped {

    if ([SCIUtils getBoolPref:@"follow_request_confirm"]) {

        NSLog(@"[SCInsta] Confirm follow request approve triggered");

        [SCIUtils showConfirmation:^{
            %orig;
        }];

    } else {

        %orig;

    }
}


- (void)_onIgnoreButtonTapped {

    if ([SCIUtils getBoolPref:@"follow_request_confirm"]) {

        NSLog(@"[SCInsta] Confirm follow request ignore triggered");

        [SCIUtils showConfirmation:^{
            %orig;
        }];

    } else {

        %orig;

    }
}

%end
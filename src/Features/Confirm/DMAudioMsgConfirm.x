#import "../../InstagramHeaders.h"
#import "../../Utils.h"

%hook IGDirectThreadViewController

- (void)voiceRecordViewController:(id)arg1 didRecordAudioClipWithURL:(id)arg2 waveform:(id)arg3 duration:(CGFloat)arg4 entryPoint:(NSInteger)arg5 {

    if ([SCIUtils getBoolPref:@"dm_audio_msg_confirm"]) {

        NSLog(@"[SCInsta] Confirm audio message send triggered");

        [SCIUtils showConfirmation:^{
            %orig;
        }];

    } else {

        %orig;

    }
}

%end


%hook IGDirectComposer

- (void)_didLongPressVoiceMessage:(id)arg1 {

    if ([SCIUtils getBoolPref:@"dm_audio_msg_confirm"]) {

        NSLog(@"[SCInsta] Confirm voice message triggered");

        [SCIUtils showConfirmation:^{
            %orig;
        }];

    } else {

        %orig;

    }
}

%end


%hook _TtC20IGDirectAIVoiceUIKitP33_5754F7617E0D924F9A84EFA352BBD29A21CompactBarContentView

- (void)didTapSend {

    if ([SCIUtils getBoolPref:@"dm_audio_msg_confirm"]) {

        NSLog(@"[SCInsta] Confirm AI voice send triggered");

        [SCIUtils showConfirmation:^{
            %orig;
        }];

    } else {

        %orig;

    }
}

%end
//
//  GrowlBezelPrefs.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 14/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlBezelPrefs.h"


@implementation GrowlBezelPrefs

- (NSString *)mainNibName {
	return @"GrowlBezelPrefs";
}

- (void)mainViewDidLoad {
	int		positionPref = 0;
	int		sizePref = 0;
	int		opacityPref = 20;
	
	[slider_Opacity setAltIncrementValue:5];
	
	READ_GROWL_PREF_INT(BEZEL_POSITION_PREF, @"com.Growl.Bezel", &positionPref);
	READ_GROWL_PREF_INT(BEZEL_SIZE_PREF, @"com.Growl.Bezel", &sizePref);
	READ_GROWL_PREF_INT(BEZEL_OPACITY_PREF, @"com.Growl.Bezel", &opacityPref);
	
	if (positionPref == BEZEL_POSITION_DEFAULT) {
		[radio_PositionD setState:NSOnState];
		[radio_PositionTR setState:NSOffState];
		[radio_PositionBR setState:NSOffState];
		[radio_PositionBL setState:NSOffState];
		[radio_PositionTL setState:NSOffState];
	} else if (positionPref == BEZEL_POSITION_TOPRIGHT) {
		[radio_PositionD setState:NSOffState];
		[radio_PositionTR setState:NSOnState];
		[radio_PositionBR setState:NSOffState];
		[radio_PositionBL setState:NSOffState];
		[radio_PositionTL setState:NSOffState];
	} else if (positionPref == BEZEL_POSITION_BOTTOMRIGHT) {
		[radio_PositionD setState:NSOffState];
		[radio_PositionTR setState:NSOffState];
		[radio_PositionBR setState:NSOnState];
		[radio_PositionBL setState:NSOffState];
		[radio_PositionTL setState:NSOffState];
	} else if (positionPref == BEZEL_POSITION_BOTTOMLEFT) {
		[radio_PositionD setState:NSOffState];
		[radio_PositionTR setState:NSOffState];
		[radio_PositionBR setState:NSOffState];
		[radio_PositionBL setState:NSOnState];
		[radio_PositionTL setState:NSOffState];
	} else if (positionPref == BEZEL_POSITION_TOPLEFT) {
		[radio_PositionD setState:NSOffState];
		[radio_PositionTR setState:NSOffState];
		[radio_PositionBR setState:NSOffState];
		[radio_PositionBL setState:NSOffState];
		[radio_PositionTL setState:NSOnState];
	}
	
	[radio_Size selectCellAtRow:sizePref column:0];
	
	[slider_Opacity setIntValue:opacityPref];
	[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%",opacityPref]];
}

- (void)didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

- (IBAction)preferenceChanged:(id)sender {
	int		positionPref;
	int		sizePref;
	int		opacityPref;
	
	if (sender == radio_PositionD) {
		[radio_PositionTR setState:NSOffState];
		[radio_PositionBR setState:NSOffState];
		[radio_PositionBL setState:NSOffState];
		[radio_PositionTL setState:NSOffState];
		positionPref = BEZEL_POSITION_DEFAULT;
		WRITE_GROWL_PREF_INT(BEZEL_POSITION_PREF, positionPref, @"com.Growl.Bezel");
	} else if (sender == radio_PositionTR) {
		[radio_PositionD setState:NSOffState];
		[radio_PositionBR setState:NSOffState];
		[radio_PositionBL setState:NSOffState];
		[radio_PositionTL setState:NSOffState];
		positionPref = BEZEL_POSITION_TOPRIGHT;
		WRITE_GROWL_PREF_INT(BEZEL_POSITION_PREF, positionPref, @"com.Growl.Bezel");
	} else if (sender == radio_PositionBR) {
		[radio_PositionD setState:NSOffState];
		[radio_PositionTR setState:NSOffState];
		[radio_PositionBL setState:NSOffState];
		[radio_PositionTL setState:NSOffState];
		positionPref = BEZEL_POSITION_BOTTOMRIGHT;
		WRITE_GROWL_PREF_INT(BEZEL_POSITION_PREF, positionPref, @"com.Growl.Bezel");
	} else if (sender == radio_PositionBL) {
		[radio_PositionD setState:NSOffState];
		[radio_PositionTR setState:NSOffState];
		[radio_PositionBR setState:NSOffState];
		[radio_PositionTL setState:NSOffState];
		positionPref = BEZEL_POSITION_BOTTOMLEFT;
		WRITE_GROWL_PREF_INT(BEZEL_POSITION_PREF, positionPref, @"com.Growl.Bezel");
	} else if (sender == radio_PositionTL) {
		[radio_PositionD setState:NSOffState];
		[radio_PositionTR setState:NSOffState];
		[radio_PositionBR setState:NSOffState];
		[radio_PositionBL setState:NSOffState];
		positionPref = BEZEL_POSITION_TOPLEFT;
		WRITE_GROWL_PREF_INT(BEZEL_POSITION_PREF, positionPref, @"com.Growl.Bezel");
	} else if (sender == radio_Size) {
		sizePref = [radio_Size selectedRow];
		WRITE_GROWL_PREF_INT(BEZEL_SIZE_PREF, sizePref, @"com.Growl.Bezel");
	} else if (sender == slider_Opacity) {
		opacityPref = [slider_Opacity intValue];
		[text_Opacity setStringValue:[NSString stringWithFormat:@"%d\%",opacityPref]];
		WRITE_GROWL_PREF_INT(BEZEL_OPACITY_PREF, opacityPref, @"com.Growl.Bezel");
	}

	UPDATE_GROWL_PREFS();
}

@end

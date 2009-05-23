/*#define GrowliCalVeryLowColor		@"iCal-Priority-VeryLow-Color"
#define GrowliCalModerateColor		@"iCal-Priority-Moderate-Color"
#define GrowliCalNormalColor			@"iCal-Priority-Normal-Color"
#define GrowliCalHighColor			@"iCal-Priority-High-Color"
#define GrowliCalEmergencyColor		@"iCal-Priority-Emergency-Color"

#define GrowliCalVeryLowTextColor	@"iCal-Priority-VeryLow-Text-Color"
#define GrowliCalModerateTextColor	@"iCal-Priority-Moderate-Text-Color"
#define GrowliCalNormalTextColor		@"iCal-Priority-Normal-Text-Color"
#define GrowliCalHighTextColor		@"iCal-Priority-High-Text-Color"
#define GrowliCalEmergencyTextColor	@"iCal-Priority-Emergency-Text-Color"

#define GrowliCalVeryLowTopColor		@"iCal-Priority-VeryLow-Top-Color"
#define GrowliCalModerateTopColor	@"iCal-Priority-Moderate-Top-Color"
#define GrowliCalNormalTopColor		@"iCal-Priority-Normal-Top-Color"
#define GrowliCalHighTopColor		@"iCal-Priority-High-Top-Color"
#define GrowliCalEmergencyTopColor	@"iCal-Priority-Emergency-Top-Color"

#define GrowliCalVeryLowBorderColor		@"iCal-Priority-VeryLow-Border-Color"
#define GrowliCalModerateBorderColor	@"iCal-Priority-Moderate-Border-Color"
#define GrowliCalNormalBorderColor		@"iCal-Priority-Normal-Border-Color"
#define GrowliCalHighBorderColor		@"iCal-Priority-High-Border-Color"
#define GrowliCalEmergencyBorderColor	@"iCal-Priority-Emergency-Border-Color"*/

typedef enum {
	GrowliCalPurple = 0,
	GrowliCalPink,
	GrowliCalGreen,
	GrowliCalBlue,
	GrowliCalOrange,
	GrowliCalRed
} GrowliCalColorType;

#define GrowliCalColor			@"iCal-Color"

#define GrowliCalOpacity				@"iCal-Opacity"
#define GrowliCalDuration			@"iCal-Duration"

#define GrowliCalLimitPref			@"iCal - Limit"
#define GrowliCalScreen				@"iCal-Screen"
#define GrowliCalSizePref			@"iCal-Size"

#define GrowliCalSizeNormal			0
#define GrowliCalSizeLarge			1
#define GrowliCalSizePrefDefault		GrowliCalSizeNormal

#define GrowliCalPrefDomain			@"com.Growl.iCal"

// the default value for the duration preference
#define GrowliCalDurationPrefDefault		5.0f

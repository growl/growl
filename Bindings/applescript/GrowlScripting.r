#include <Carbon/Carbon.r>

#define Reserved8   reserved, reserved, reserved, reserved, reserved, reserved, reserved, reserved
#define Reserved12  Reserved8, reserved, reserved, reserved, reserved
#define Reserved13  Reserved12, reserved
#define dp_none__   noParams, "", directParamOptional, singleItem, notEnumerated, Reserved13
#define reply_none__   noReply, "", replyOptional, singleItem, notEnumerated, Reserved13
#define synonym_verb__ reply_none__, dp_none__, { }
#define plural__    "", {"", kAESpecialClassProperties, cType, "", reserved, singleItem, notEnumerated, readOnly, Reserved8, noApostrophe, notFeminine, notMasculine, plural}, {}

resource 'aete' (0, "") {
	0x1,  // major version
	0x0,  // minor version
	english,
	roman,
	{
		"Growl",
		"",
		'Grwl',
		1,
		1,
		{
			/* Events */

			"notify",
			"Post a notification to be displayed via Growl",
			'noti', 'fygr',
			reply_none__,
			dp_none__,
			{
				"with title", 'titl', 'TEXT',
				"title of the notification to display",
				required,
				singleItem, notEnumerated, Reserved13,
				"description", 'desc', 'TEXT',
				"full text of the notification to display",
				required,
				singleItem, notEnumerated, Reserved13,
				"image from URL", 'iurl', 'TEXT',
				"URL of the icon to use for this notification. Currently limited to file:/// URLs.",
				optional,
				singleItem, notEnumerated, Reserved13,
				"icon of file", 'ifil', 'TEXT',
				"URL of the file whose icon should be used as the image for this notification. For example, 'file:///Applications'. Must be a file:/// URL.",
				optional,
				singleItem, notEnumerated, Reserved13,
				"icon of application", 'iapp', 'TEXT',
				"Name of the application whose icon should be used for this notification. For example, 'Mail.app'.",
				optional,
				singleItem, notEnumerated, Reserved13,
				"sticky", 'stck', 'bool',
				"whether or not the notification displayed should time out. Defaults to 'no'.",
				optional,
				singleItem, notEnumerated, Reserved13
			}
		},
		{
			/* Classes */

		},
		{
			/* Comparisons */
		},
		{
			/* Enumerations */
		}
	}
};

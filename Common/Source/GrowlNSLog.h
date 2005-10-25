#ifdef GrowlNSLog
#	undef GrowlNSLog
#	define GrowlNSLog(...) NSLog(__VA_ARGS__)
#else
#	define GrowlNSLog(...) /*debugging log deleted*/
#endif

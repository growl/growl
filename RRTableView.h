//
//  RRTableView.h
//  Growl
//
//  Created by rudy on 11/12/04.
//  Copyright 2004 Rudy Richter. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RRTableView : NSTableView {


}

- (BOOL)becomeFirstResponder;

@end

@interface NSObject (RRTableViewDelegateAdditions)
	
-(void)tableViewDidClickInBody:(NSTableView*)tableView ;
@end
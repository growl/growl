/*
 * Iconara DOM framework: DOMProcessingInstruction (created 27 April 2002)
 *
 * Release 1
 *
 * Copyright 2002-2003 Iconara/Theo Hultberg
 *
 *
 * This file is part of the Iconara DOM framework.
 *
 * Iconara DOM is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Iconara DOM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Iconara DOM; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

#import <Foundation/Foundation.h>
#import "DOMNode.h";


/*!
 * Represents a processing instruction in a XML-document.
 * A processing instruction (pi) is a tag that looks like this:
 * 
 * @code 
 *     <?target content-string?>
 * @endcode
 *
 * An exception will be raised if the target matches the 
 * string "xml" in any combination of case. 
 *
 * The <?xml version="1.0"?> declaration is not part of the
 * document, it will be created during serialization. 
 *                    
 */
@protocol DOMProcessingInstruction <NSObject>

/*!
 * Sets the string of this processing instruction.
 */
- (void)setData:(NSString *)string;

/*!
 * Returns the content of this processing instruction as a string.
 */
- (NSString *)data;

/*!
 * Sets the target/name of this pi.
 *
 * @exception DOMSyntaxException
 *     An exception will be raised if the target matches the 
 *     string "xml" in any combination of case. 
 *     The <?xml version="1.0"?> declaration is not part of the
 *     document, it will be created during serialization.
 */
- (void)setTarget:(NSString *)target;

/*!
 * Returns the target/name of this pi.
 */
- (NSString *)target;

@end


@interface DOMProcessingInstruction : DOMNode <DOMProcessingInstruction> {
	NSString *target;
	NSString *data;
}

+ (id <DOMProcessingInstruction>)processingInstructionWithTarget:(NSString *)target;

+ (id <DOMProcessingInstruction>)processingInstructionWithTarget:(NSString *)target data:(NSString *)string;

- (id)initWithTarget:(NSString *)target;

- (id)initWithTarget:(NSString *)target data:(NSString *)string;

@end


/*
 * DOMProcessingInstruction is so long, this makes it shorter.
 *
 * Not used throughout the framework, for consistency, but applications
 * using the framework may use this macro.
 */
@compatibility_alias DOMPI DOMProcessingInstruction;

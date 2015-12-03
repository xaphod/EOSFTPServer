/*******************************************************************************
 * Copyright (c) 2012, Jean-David Gadina - www.xs-labs.com
 * Distributed under the Boost Software License, Version 1.0.
 *
 * Boost Software License - Version 1.0 - August 17th, 2003
 *
 * Permission is hereby granted, free of charge, to any person or organization
 * obtaining a copy of the software and accompanying documentation covered by
 * this license (the "Software") to use, reproduce, display, distribute,
 * execute, and transmit the Software, and to prepare derivative works of the
 * Software, and to permit third-parties to whom the Software is furnished to
 * do so, all subject to the following:
 *
 * The copyright notices in the Software and this entire statement, including
 * the above license grant, this restriction and the following disclaimer,
 * must be included in all copies of the Software, in whole or in part, and
 * all derivative works of the Software, unless such copies or derivative
 * works are solely in the form of machine-executable object code generated by
 * a source language processor.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
 * SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
 * FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ******************************************************************************/

/* $Id$ */

/*!
 * @file            ...
 * @author          Jean-David Gadina - www.xs-labs.com
 * @copyright       (c) 2012, XS-Labs
 * @abstract        ...
 */

#import "EOSFTPServer+Private.h"
#import "EOSFTPServerConnection.h"
#import "NSFileManager+EOS.h"
#import "EOSFile.h"

@implementation EOSFTPServer( Private )

- ( void )unrecognizedCommand: ( NSString * )command connection: ( EOSFTPServerConnection * )connection
{
    ( void )command;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( NSString * )directoryListingForConnection: ( EOSFTPServerConnection * )connection path: ( NSString * )path
{
    EOSFile                 * directory;
    NSDateFormatter         * dateFormatter;
    NSLocale                * locale;
    NSDirectoryEnumerator   * enumerator;
    NSMutableArray          * listing;
    NSString                * filePath;
    NSUInteger                subFilesCount;
    EOSFile                 * file;
    NSString                * fileInfos;
    
    directory = [ self fileAtPath: path connection: connection ];
    
    if( directory == nil )
    {
        return nil;
    }
    
    dateFormatter = [ NSDateFormatter new ];
    locale        = [ [ NSLocale alloc ] initWithLocaleIdentifier: @"en" ];
    enumerator    = [ [ NSFileManager defaultManager ]  enumeratorAtPath: directory.path ];
    listing       = [ NSMutableArray arrayWithCapacity: 100 ];
    
    [ dateFormatter setDateFormat: @"MMM dd HH:mm" ];
    [ dateFormatter setLocale: locale ];
    [ locale release ];
    
    EOS_FTP_DEBUG( @"Listing directory: %@", directory.path );
    
    while( ( filePath = [ enumerator nextObject ] ) )
    {
        [ enumerator skipDescendents ];
        
        filePath   = [ directory.path stringByAppendingPathComponent: filePath ];
        file       = [ EOSFile fileWithPath: filePath ];
        
        if( file == nil )
        {
            continue;
        }
        
        subFilesCount = [ [ NSFileManager defaultManager ] numberOfFilesInDirectory: filePath ];
        subFilesCount = ( subFilesCount < 1 ) ? 1 : subFilesCount;
        
        fileInfos = [ NSString stringWithFormat:
                     @"%c%@ %5lu %12@ %12@ %10lu %@ %@",
                     ( file.type == EOSFileTypeDirectory ) ? 'd' : '-',
                     file.humanReadablePermissions,
                     ( unsigned long )subFilesCount,
                     file.owner,
                     file.group,
                     (unsigned long)file.bytes,
                     [ dateFormatter stringFromDate: file.modificationDate ],
                     [ [ self serverPathForFile: file ] lastPathComponent ]
                     ];
        
        [ listing addObject: fileInfos ];
    }
    
    return ( listing.count > 0 ) ? [ listing componentsJoinedByString: @"\n" ] : @""; // TC. was: :nil;
}

@end

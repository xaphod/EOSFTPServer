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

#import "EOSFTPServer+Commands.h"
#import "EOSFTPServer+Private.h"
#import "EOSFTPServerConnection.h"
#import "EOSFTPServerUser.h"
#import "EOSFile.h"
#import "EOSFile.h"

#ifdef __clang__
#pragma clang diagnostic ignored "-Wformat-nonliteral"
#endif

#define __CHECK_AUTH( __c__ )   if( __c__.authenticated == NO )                                                                         \
{                                                                                                       \
EOS_FTP_DEBUG( @"Command needs authentication" );                                                   \
\
[ __c__ sendMessage: [ self formattedMessage: [ self messageForReplyCode: 530 ] code: 530 ] ];      \
\
return;                                                                                             \
}

@implementation EOSFTPServer( Commands )

- ( void )processCommandUSER: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    BOOL shouldAcceptUser;
    
    shouldAcceptUser         = YES;
    connection.authenticated = NO;
    
    if( _delegate != nil && [ _delegate respondsToSelector: @selector( ftpServer:shouldAcceptUser: ) ] )
    {
        shouldAcceptUser = [ _delegate ftpServer: self shouldAcceptUser: args ];
    }
    
    if( shouldAcceptUser && [ self userCanLogin: args ] == YES )
    {
        connection.username = args;
        
        EOS_FTP_DEBUG( @"Username OK: %@", args );
        
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 331 ] code: 331 ] ];
    }
    else
    {
        EOS_FTP_DEBUG( @"Wrong username: %@", args );
        
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 530 ] code: 530 ] ];
    }
}

- ( void )processCommandPASS: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    EOSFTPServerUser * user;
    
    connection.authenticated = NO;
    
    if( connection.username != nil )
    {
        user = [ EOSFTPServerUser userWithName: connection.username password: args ];
        
        if( [ self authenticateUser: user ] == YES )
        {
            if( _delegate != nil && [ _delegate respondsToSelector: @selector( ftpServer:userDidAuthentify: ) ] )
            {
                [ _delegate ftpServer: self userDidAuthentify: connection.username ];
            }
            
            connection.authenticated = YES;
            
            EOS_FTP_DEBUG( @"Password OK for user %@", connection.username );
            
            [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 230 ] code: 230 ] ];
        }
        else
        {
            if( _delegate != nil && [ _delegate respondsToSelector: @selector( ftpServer:userDidFailAuthentify: ) ] )
            {
                [ _delegate ftpServer: self userDidFailAuthentify: connection.username ];
            }
            
            EOS_FTP_DEBUG( @"Invalid password for user %@", connection.username );
            
            [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 530 ] code: 530 ] ];
        }
    }
    else
    {
        EOS_FTP_DEBUG( @"No username" );
        
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 530 ] code: 530 ] ];
    }
}

- ( void )processCommandACT:  ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( void )processCommandCWD:  ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    EOSFile * file;
    
    __CHECK_AUTH( connection );
    
    file = [ self fileAtPath: args connection: connection ];
    
    if( file == nil || file.type != EOSFileTypeDirectory )
    {
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 550 ] code: 550 ] ];
    }
    else
    {
        [ connection setCurrentDirectory: file.path ];
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 250 ] code: 250 ] ];
    }
}

- ( void )processCommandCDUP: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    if ([connection.currentDirectory isEqualToString:self.rootDirectory]) {
        [ connection sendMessage: [ self formattedMessage:[ self messageForReplyCode:550 ] code:550 ]];
    } else {
        NSString *dir = [connection.currentDirectory stringByDeletingLastPathComponent];
        EOSFile *file = [EOSFile fileWithPath:dir];
        
        if (file == nil || file.type != EOSFileTypeDirectory)
        {
            [ connection sendMessage: [ self formattedMessage:[ self messageForReplyCode:550 ] code:550 ]];
        }
        else
        {
            [ connection setCurrentDirectory: file.path ];
            [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 250 ] code: 250 ] ];
        }
    }
}

- ( void )processCommandSMNT: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( void )processCommandREIN: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( void )processCommandQUIT: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    EOS_FTP_DEBUG( @"Quitting" );
    
    ( void )args;
    
    if( _quitMessage.length > 0 )
    {
        [ connection sendMessage: [ self formattedMessage: [ NSString stringWithFormat: @"%@\n%@", [ self messageForReplyCode: 221 ], _quitMessage ] code: 221 ] ];
    }
    else
    {
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 221 ] code: 221 ] ];
    }
    
    [ connection performSelector: @selector( close ) withObject: nil afterDelay: 1 ];
}

- ( void )processCommandPORT: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    NSArray   * parts;
    NSUInteger  port;
    NSInteger   high;
    NSInteger   low;
    
    __CHECK_AUTH( connection );
    
    parts   = [ args componentsSeparatedByString: @"," ];
    high    = [ [ parts objectAtIndex: 4 ] integerValue ];
    low     = [ [ parts objectAtIndex: 5 ] integerValue ];
    port    = ( NSUInteger )( ( ( NSUInteger )high << 8 ) + ( NSUInteger )low );
    
    connection.transferMode = EOSFTPServerTransferModePORT;
    
    [ connection openDataSocket: port ];
}

- ( void )processCommandEPRT: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    NSArray *parts = [ args componentsSeparatedByString:@"|"];
    NSUInteger port = (NSUInteger)[[parts objectAtIndex:3] intValue];
    
    connection.transferMode = EOSFTPServerTransferModePORT;
    
    [ connection openDataSocket:port];
}

- ( void )processCommandPASV: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )args;
    
    [ connection setTransferMode: EOSFTPServerTransferModePASV ];
    [ connection openDataSocket: 0 ];
}

- (void)processCommandEPSV: ( EOSFTPServerConnection * ) connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )args;
    
    [ connection setTransferMode: EOSFTPServerTransferModePASV ];
    [ connection openDataSocket: 0 ];
}

- ( void )processCommandTYPE: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    NSString                 * typeString;
    EOSFTPServerConnectionType type;
    
    typeString = [ args uppercaseString ];
    
    if( [ typeString isEqualToString: @"A" ] )
    {
        EOS_FTP_DEBUG( @"Switching to ASCII connection type" );
        
        type = EOSFTPServerConnectionTypeASCII;
    }
    else if( [ typeString isEqualToString: @"E" ] )
    {
        EOS_FTP_DEBUG( @"Switching to EBDIC connection type" );
        
        type = EOSFTPServerConnectionTypeEBCDIC;
    }
    else
    {
        EOS_FTP_DEBUG( @"Unknown type %@. Switching to ASCII connection type", typeString );
        
        type = EOSFTPServerConnectionTypeASCII;
    }
    
    connection.type = type;
    
    [ connection sendMessage: [ self formattedMessage: [ NSString stringWithFormat: @"%@\nType set to %@", [ self messageForReplyCode: 200 ], typeString ] code: 200 ] ];
}

- ( void )processCommandSTRU: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( void )processCommandMODE: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( void )processCommandRETR: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    EOSFile *file = [self fileAtPath:args connection:connection];
    
    if (!file) {
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 550 ] code: 550 ] ];
    } else {
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 150 ] code: 150 ] ];
        [connection sendData:file.data];
    }
}

- ( void )processCommandSTOR: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    connection.currentArgs = [NSString stringWithString:args];
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 150 ] code: 150 ] ];
    
    NSString *filePath = [connection.currentDirectory stringByAppendingPathComponent:args];
    [[NSNotificationCenter defaultCenter] postNotificationName:EOSFTPServerFileStatusNotification object:self userInfo:@{@"path": filePath, @"status": @(FTPFileStatusUploading)}];
}

- ( void )processCommandSTOU: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( void )processCommandAPPE: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( void )processCommandALLO: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( void )processCommandREST: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( void )processCommandRNFR: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    EOSFile *file = [self fileAtPath:args connection:connection];
    
    if (!file) {
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 550 ] code: 550 ] ];
    } else {
        connection.currentArgs = args;
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 350 ] code: 350 ] ];
    }
}

- ( void )processCommandRNTO: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    NSString *oldPath = [self pathForArgs:connection.currentArgs connection:connection];
    NSString *newPath = [self pathForArgs:args connection:connection];
    
    if ([[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:nil]) {
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 250 ] code: 250 ] ];
    } else {
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 550 ] code: 550 ] ];
    }
}

- ( void )processCommandABOR: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( void )processCommandDELE: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( void )processCommandRMD:  ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( void )processCommandMKD:  ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    NSString *dirPath = [connection.currentDirectory stringByAppendingPathComponent:args];
    
    EOSFile *dir = [EOSFile addDirectoryWithPath:dirPath];
    if (dir == nil) {
        EOS_FTP_DEBUG(@"Can't add directory %@", dirPath);
        
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 421 ] code: 421 ] ];
        [ connection close ];
        
        return;
    }
    
    [ connection sendMessage: [ self formattedMessage: [ NSString stringWithFormat: [ self messageForReplyCode: 257 ], args ] code: 257 ] ];
}

- ( void )processCommandPWD:  ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    NSString * dir;
    
    __CHECK_AUTH( connection );
    
    ( void )args;
    
    dir = [ self serverPathForFile: [ EOSFile fileWithPath: connection.currentDirectory ] ];
    
    if( dir == nil )
    {
        EOS_FTP_DEBUG( @"Invalid current directory: %@", connection.currentDirectory );
        
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 421 ] code: 421 ] ];
        [ connection close ];
        
        return;
    }
    
    [ connection sendMessage: [ self formattedMessage: [ NSString stringWithFormat: [ self messageForReplyCode: 257 ], dir ] code: 257 ] ];
}

- ( void )processCommandLIST: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    NSString * list;
    NSArray  * lines;
    
    __CHECK_AUTH( connection );
    
    list = [ self directoryListingForConnection: connection path: args ];
    
    if( list.length > 0 )
    {
        lines = [ list componentsSeparatedByString: @"\n" ];
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 150 ] code: 150 ] ];
        
        list = [ NSString stringWithFormat: @"total %lu\n%@\r\n", (unsigned long)lines.count, list ];
        
        [ connection sendDataString: list ];
    }
    else
    {
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 450 ] code: 450 ] ];
    }
}

- ( void )processCommandNLST: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    EOSFile                 * directory;
    NSDirectoryEnumerator   * enumerator;
    NSMutableArray          * listing;
    NSString                * filePath;
    EOSFile                 * file;
    
    __CHECK_AUTH( connection );
    
    directory = [ self fileAtPath: args connection: connection ];
    
    if( directory == nil )
    {
        [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 450 ] code: 450 ] ];
    }
    else
    {
        enumerator    = [ [ NSFileManager defaultManager ]  enumeratorAtPath: directory.path ];
        listing       = [ NSMutableArray arrayWithCapacity: 100 ];
        
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
            
            [ listing addObject: [ self serverPathForFile: file ] ];
        }
        
        if( listing.count > 0 )
        {
            [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 150 ] code: 150 ] ];
            [ connection sendDataString: [ listing componentsJoinedByString: @"\x0D\x0A" ] ];
        }
        else
        {
            [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 450 ] code: 450 ] ];
        }
    }
}

- ( void )processCommandSITE: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 500 ] code: 500 ] ];
}

- ( void )processCommandSYST: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ NSString stringWithFormat: [ self messageForReplyCode: 215 ], @"Unix" ] code: 215 ] ];
}

- ( void )processCommandSTAT: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    __CHECK_AUTH( connection );
    
    ( void )connection;
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 502 ] code: 502 ] ];
}

- ( void )processCommandHELP: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    NSRange    range;
    NSString * name;
    
    range = [ args rangeOfString: @" " ];
    
    if( range.location != NSNotFound )
    {
        name = [ args substringToIndex: range.location ];
    }
    else
    {
        name = args;
    }
    
    EOS_FTP_DEBUG( @"Getting help for command %@", name );
    
    [ connection sendMessage: [ self formattedMessage: [ self helpForCommand: name ] code: 214 ] ];
}

- ( void )processCommandNOOP: ( EOSFTPServerConnection * )connection arguments: ( NSString * )args
{
    ( void )args;
    
    [ connection sendMessage: [ self formattedMessage: [ self messageForReplyCode: 200 ] code: 200 ] ];
}

@end

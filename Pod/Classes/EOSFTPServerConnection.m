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

#import "EOSFTPServerConnection.h"
#import "EOSFTPServerConnection+Private.h"
#import "EOSFTPServerConnection+AsyncSocketDelegate.h"
#import "EOSFTPServerConnection+EOSFTPServerDataConnectionDelegate.h"
#import "EOSFTPServerDataConnection.h"
#import "AsyncSocket.h"
#import "EOSFTPServer.h"
#import "NSData+EOS.h"

#ifdef __clang__
#pragma clang diagnostic ignored "-Wformat-nonliteral"
#endif

@implementation EOSFTPServerConnection

@synthesize transferMode        = _transferMode;
@synthesize username            = _username;
@synthesize authenticated       = _authenticated;
@synthesize encoding            = _encoding;
@synthesize type                = _type;
@synthesize delegate            = _delegate;

- ( id )initWithSocket: ( AsyncSocket * )socket server: ( EOSFTPServer * )server
{
    NSString * message;
    
    if( ( self = [ super init ] ) )
    {
        _connectionSocket   = [ socket retain ];
        _server             = [ server retain ];
        _transferMode       = EOSFTPServerTransferModePASV;
        _dataPort           = 2001;
        _queuedData         = [ [ NSMutableArray alloc ] initWithCapacity: 100 ];
        _encoding           = NSUTF8StringEncoding;
        _currentDirectory   = [ _server.rootDirectory copy ];
        _readData           = [[NSMutableData alloc] init];
        
        [ _connectionSocket setDelegate: self ];
        
        if( _server.welcomeMessage.length > 0 )
        {
            message = [ _server formattedMessage: [ NSString stringWithFormat: @"%@\n%@", [ _server messageForReplyCode: 220 ], _server.welcomeMessage ] code: 221 ];
        }
        else
        {
            message = [ _server formattedMessage: [ _server messageForReplyCode: 220 ] code: 221 ];
        }
        
        [ self sendMessage: message ];
        
        EOS_FTP_DEBUG( @"Establishing new connection" );
    }
    
    return self;
}

- ( void )dealloc
{
    if( _connectionSocket != nil )
    {
        [ _connectionSocket disconnect ];
    }
    
    if( _dataListeningSocket != nil )
    {
        [ _dataListeningSocket disconnect ];
    }
    
    if( _dataSocket != nil )
    {
        [ _dataSocket disconnect ];
    }
    
    _connectionSocket.delegate      = nil;
    _dataConnection.delegate        = nil;
    _dataSocket.delegate            = nil;
    _dataListeningSocket.delegate   = nil;
    
    [ _connectionSocket     release ];
    [ _dataListeningSocket  release ];
    [ _dataSocket           release ];
    [ _dataConnection       release ];
    [ _server               release ];
    [ _queuedData           release ];
    [ _currentDirectory     release ];
    [ _currentArgs          release ];
    [ _readData             release ];
    
    [ super dealloc ];
}

- ( void )sendMessage: ( NSString * )message
{
    NSMutableData * data;
    
    data = [ [ message dataUsingEncoding: NSUTF8StringEncoding ] mutableCopy ];
    
    [ data appendData: [ NSData CRLFData ] ];
    
    [ _connectionSocket writeData: data withTimeout: EOS_FTP_SERVER_READ_TIMEOUT tag: EOS_FTP_SERVER_CLIENT_REQUEST ];
    [ _connectionSocket readDataToData: [ AsyncSocket CRLFData ] withTimeout: EOS_FTP_SERVER_READ_TIMEOUT tag: EOS_FTP_SERVER_CLIENT_REQUEST ];
    
    [ data release ];
}

- ( void )sendDataString: ( NSString * )dataString
{
    NSMutableString * message;
    NSMutableData   * data;
    
    message = [ [ NSMutableString alloc ] initWithString: dataString ];
    
    CFStringNormalize( ( CFMutableStringRef )message, kCFStringNormalizationFormC );
    
    data = [ [ message dataUsingEncoding: _encoding ] mutableCopy ];
    
    [ message release ];
    
    if( _dataConnection != nil )
    {
        EOS_FTP_DEBUG( @"Sending data" );
        
        [ _dataConnection writeData: data ];
    }
    else
    {
        [ _queuedData addObject:data ];
    }
    
    [ data release ];
}

- ( void )sendData: ( NSData * )dataToSend
{
    NSMutableData *data = [NSMutableData dataWithData:dataToSend];
    
    if( _dataConnection != nil )
    {
        EOS_FTP_DEBUG( @"Sending data" );
        
        [ _dataConnection writeData: data ];
    }
    else
    {
        [ _queuedData addObject:data ];
    }
}

- ( void )close
{
    if( _connectionSocket != nil )
    {
        [ _connectionSocket disconnectAfterWriting ];
    }
    
    if( _delegate != nil && [ _delegate respondsToSelector: @selector( ftpConnectionDidClose: ) ] )
    {
        [ _delegate ftpConnectionDidClose: self ];
    }
}

- ( BOOL )openDataSocket: ( NSUInteger )port
{
    NSError  * e;
    NSString * address;
    
    [ _dataSocket     release ];
    [ _dataConnection release ];
    
    e           = nil;
    _dataSocket = [ [ AsyncSocket alloc ] initWithDelegate: self ];
    
    switch( _transferMode )
    {
        case EOSFTPServerTransferModePORT:
            
            EOS_FTP_DEBUG( @"Opening data socket (PORT)" );
            
            [ _dataSocket connectToHost: [ _connectionSocket connectedHost ] onPort: ( UInt16 )port error: &e ];
            
            _dataPort       = port;
            _dataConnection = [ [ EOSFTPServerDataConnection alloc ] initWithSocket: _dataSocket connection: self queuedData: _queuedData delegate: self ];
            
            [ self sendMessage: [ _server formattedMessage: [ _server messageForReplyCode: 200 ] code: 200 ] ];
            
            break;
            
        case EOSFTPServerTransferModePASV:
            
            EOS_FTP_DEBUG( @"Opening data socket (PASV)" );
            
            _dataPort = [ _server getPASVDataPort ];
            address   = [ [ _connectionSocket localHost ] stringByReplacingOccurrencesOfString: @"." withString: @"," ];
            
            [ _dataSocket acceptOnPort: ( UInt16 )_dataPort error: &e ];
            [ self sendMessage: [ _server formattedMessage: [ NSString stringWithFormat: [ _server messageForReplyCode: 227 ], address, _dataPort >> 8, _dataPort & 0x00FF ]  code: 227 ] ];
            
            break;
            
        default:
            
            EOS_FTP_DEBUG( @"Unknown connection transfer mode: %u", _transferMode );
            
            [ self sendMessage: [ _server formattedMessage: [ _server messageForReplyCode: 421 ] code: 421 ] ];
            [ self close ];
            
            break;
    }
    
    EOS_FTP_DEBUG( @"Data socket opened - error: %@", e );
    
    return YES;
}

- ( NSString * )currentDirectory
{
    @synchronized( self )
    {
        return _currentDirectory;
    }
}

- ( void )setCurrentDirectory: ( NSString * )path
{
    BOOL isDir;
    
    @synchronized( self )
    {
        [ _currentDirectory release ];
        
        isDir             = NO;
        _currentDirectory = nil;
        
        if( [ path hasSuffix: @"/" ] == NO )
        {
            path = [ path stringByAppendingString: @"/" ];
        }
        
        if( [ [ NSFileManager defaultManager ] fileExistsAtPath: path isDirectory: &isDir ] == NO )
        {
            _currentDirectory = _server.rootDirectory;
        }
        else if( isDir == NO )
        {
            _currentDirectory = _server.rootDirectory;
        }
        else
        {
            _currentDirectory = [ path copy ];
        }
    }
}

@end
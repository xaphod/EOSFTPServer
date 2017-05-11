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

#import "EOSFTPServerConnection+AsyncSocketDelegate.h"
#import "EOSFTPServerConnection+Private.h"
#import "EOSFTPServerConnection+EOSFTPServerDataConnectionDelegate.h"
#import "EOSFTPServerDataConnection.h"
#import "NSData+EOS.h"
@import xaphodObjCUtils;

@implementation EOSFTPServerConnection( AsyncSocketDelegate )

- ( BOOL )onSocketWillConnect: ( AsyncSocket * )socket
{
//    EOS_FTP_DEBUG( @"Socket will connect on port %u", [ socket localPort ] );
    
    [ socket readDataWithTimeout: EOS_FTP_SERVER_READ_TIMEOUT tag: 0 ];

    return YES;
}

- ( void )onSocket: ( AsyncSocket * )socket didAcceptNewSocket: ( AsyncSocket * )newSocket
{
    ( void )socket;
    
    EOS_FTP_DEBUG( @"New socket accepted on port %u", [ newSocket localPort ] );
    
    [ _dataConnection release ];
    
    _dataConnection = [ [ EOSFTPServerDataConnection alloc ] initWithSocket: socket connection: self queuedData: _queuedData delegate: self ];
}

- ( void )onSocket: ( AsyncSocket * )socket didReadData: ( NSData * )data withTag: ( long )tag
{
    ( void )socket;
    ( void )tag;
    
//    EOS_FTP_DEBUG( @"Data read (tag: %li)", tag );
    
    [ _connectionSocket readDataToData: [ NSData CRLFData ] withTimeout: EOS_FTP_SERVER_READ_TIMEOUT tag: EOS_FTP_SERVER_CLIENT_REQUEST ];
    
    [ self processData: data ];
}

- ( void )onSocket: ( AsyncSocket * )socket didWriteDataWithTag: ( long )tag
{
    ( void )socket;
    ( void )tag;
    
//    EOS_FTP_DEBUG( @"Data written (tag: %li)", tag );
    
    [ _connectionSocket readDataToData: [ NSData CRLFData ] withTimeout: EOS_FTP_SERVER_READ_TIMEOUT tag: EOS_FTP_SERVER_CLIENT_REQUEST ];
}

@end

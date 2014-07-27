//
//  CWViewController.m
//  EOSFTPServer
//
//  Created by Michael Litvak on 07/27/2014.
//  Copyright (c) 2014 Michael Litvak. All rights reserved.
//

#import "CWViewController.h"
#import <EOSFTpServer/EOSFTPServer.h>
#import <EOSFTpServer/EOSFTPServerUser.h>

@interface CWViewController ()

@end

@implementation CWViewController {
    EOSFTPServer *_ftpServer;
    
    UIButton *_startButton;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _startButton = [[UIButton alloc] initWithFrame:CGRectMake(50, 50, 200, 60)];
    _startButton.backgroundColor = [UIColor grayColor];
    [_startButton setTitle:@"Start FTP Server" forState:UIControlStateNormal];
    [_startButton addTarget:self action:@selector(startAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_startButton];
    
    _ftpServer = [[EOSFTPServer alloc] initWithPort:2121];
    _ftpServer.chroot = YES;
    [_ftpServer addUser:[EOSFTPServerUser userWithName:@"michael" password:@"test"]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    
    NSString *ftpPath = [basePath stringByAppendingPathComponent:@"ftp"];
    
    BOOL isDir = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:ftpPath isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:ftpPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    _ftpServer.rootDirectory = ftpPath;
    
}

- (void)startAction {
    if ([_ftpServer start]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server Started" message:@"FTP Server started on port 2121" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not start FTP server" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

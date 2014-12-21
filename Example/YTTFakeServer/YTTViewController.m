//
//  YTTViewController.m
//  YTTFakeServer
//
//  Created by yatatsu on 11/24/2014.
//  Copyright (c) 2014 yatatsu. All rights reserved.
//

#import "YTTViewController.h"
#import "YTTAPIManager.h"
#import <SVProgressHUD/SVProgressHUD.h>

@interface YTTViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation YTTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

#pragma mark - UITableViewDataSource 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self dataSource] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    cell.textLabel.text = [self dataSource][indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *path = [self paths][indexPath.row];
    NSDictionary *params = [self params][indexPath.row];
    NSString *method = [self methods][indexPath.row];
    
    YTTAPIManager *sharedManager = [YTTAPIManager sharedManager];
    __weak typeof(self) wself = self;
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    if ([method isEqualToString:@"GET"]) {
        [sharedManager GET:path parameters:params success:^(NSURLSessionDataTask *task, NSDictionary *json) {
            NSLog(@"success %@", path);
            [SVProgressHUD dismiss];
            [wself showResult:json];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"failure %@", error);
            [SVProgressHUD dismiss];
            [wself showAlertForError:error];
        }];
    } else {
        [sharedManager POST:path parameters:params success:^(NSURLSessionDataTask *task, NSDictionary *json) {
            NSLog(@"success %@", path);
            [SVProgressHUD dismiss];
            [wself showResult:json];
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"failure %@", error);
            [SVProgressHUD dismiss];
            [wself showAlertForError:error];
        }];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - 

- (NSArray *)dataSource
{
    return @[@"/api/auth (POST) (fake)",
             @"/api/auth (error) (fake)",
             @"/api/users/2 (GET) (fake)",
             @"httpbin.org/get (GET)",
            ];
}

- (NSArray *)methods
{
    return @[@"POST",
             @"POST",
             @"GET",
             @"GET",
             ];
}

- (NSArray *)paths
{
    return @[@"api/auth",
             @"api/auth",
             @"api/users/2",
             @"get",
             ];
}

- (NSArray *)params
{
    return @[@{@"id":@"Alice",@"password":@"1234"},
             @{@"id":@"Alice",@"password":@"XXXX"},
             @{},
             @{},
             ];
}

#pragma mark - 

- (void)showAlertForError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"error" message:error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)showResult:(NSDictionary *)dict
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"result" message:dict.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end

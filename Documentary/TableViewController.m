//
//  TableViewController.m
//  Documentary
//
//  Created by Andrew Pontious on 1/3/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some right reserved: http://opensource.org/licenses/mit-license.php
//

#import "TableViewController.h"

#import "AppDelegate.h"
#import "iCloudManager.h"
#import "DocumentViewController.h"

@interface TableViewController () <UIActionSheetDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *addBarButtonItem;

@property (nonatomic, copy) NSArray *documentNames;

@property (nonatomic, copy) NSURL *documentURLToDelete;

@end

static const NSInteger kLabelTag = 1001;

NSString *const kShowDocumentSegueIdentifier = @"showDocument";

@implementation TableViewController

#pragma mark Standard Methods

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentURLsUpdated:) name:kICloudManagerDocumentURLsUpdatedNotification object:nil];
    
    [self updateDocumentNames];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kShowDocumentSegueIdentifier] == YES) {
        NSURL *documentURL = [AppDelegate appDelegate].iCloudManager.documentURLs[[self.tableView indexPathForSelectedRow].row];
        
        DocumentViewController *documentViewController = segue.destinationViewController;
        
        documentViewController.documentURL = documentURL;
    }
}

#pragma mark UITableViewDataSource Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.documentNames count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    UILabel *label = (UILabel *)[cell viewWithTag:kLabelTag];
    
    label.text = self.documentNames[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (editingStyle) {
        case UITableViewCellEditingStyleNone:
            break;
        case UITableViewCellEditingStyleDelete: {
            self.documentURLToDelete = [AppDelegate appDelegate].iCloudManager.documentURLs[indexPath.row];
            UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel button title") destructiveButtonTitle:NSLocalizedString(@"Delete Document", @"Delete Document button title") otherButtonTitles:nil];
            [sheet showInView:tableView];
        }
            break;
        case UITableViewCellEditingStyleInsert:
            break;
    }
}

#pragma mark UIActionSheetDelegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) { // Delete Document
        [self.tableView setEditing:NO animated:YES];
        
        // TODO: put spinner over entire table and be unresponsive till it finishes? Trouble is, this will return *before* table is actually updated. And couldn't there be an update before deletion finishes? We just don't know.
        // Alternatively: treat cell specially, put spinner over it and don't allow it to be selected or deleted again.
        
        [[AppDelegate appDelegate].iCloudManager deleteDocument:self.documentURLToDelete callback:^(NSError *error) {
            NSLog(@"Deletion error: %@", error);
        }];
    } else if (buttonIndex == 1) { // Cancel
        [self.tableView setEditing:NO animated:YES];
    }
}

#pragma mark Actions

- (IBAction)addNewDocument {
    self.addBarButtonItem.enabled = NO;
    
    [[AppDelegate appDelegate].iCloudManager createNewDocument:^(NSError *error) {
        self.addBarButtonItem.enabled = YES;
        // Note there will still be a gap between when the button is active again and when the new file will appear.
    }];
}

#pragma mark Private Methods

- (void)updateDocumentNames {
    NSArray *documentURLs = [[AppDelegate appDelegate].iCloudManager.documentURLs copy];
    
    __block NSMutableArray *documentNames = [NSMutableArray array];
    
    [documentURLs enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger index, BOOL *stop) {
        [documentNames addObject:[[url URLByDeletingPathExtension] lastPathComponent]];
    }];
    
    if ([self.documentNames isEqualToArray:documentNames] == NO) {
        self.documentNames = documentNames;
        [self.tableView reloadData];
    }
}

- (void)documentURLsUpdated:(NSNotification *)notification {
    [self updateDocumentNames];
}

@end

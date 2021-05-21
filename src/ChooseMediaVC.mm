//
//  ChooseMediaVC.m
//  Jami
//
//  Created by kateryna on 2021-05-19.
//

#import "ChooseMediaVC.h"
#import "views/RingTableView.h"
#import "views/HoverTableRowView.h"
#import "views/NSColor+RingTheme.h"

@interface ChooseMediaVC () {
    __unsafe_unretained IBOutlet RingTableView* devicesView;
    __unsafe_unretained IBOutlet NSLayoutConstraint* tableHeightConstraint;
    __unsafe_unretained IBOutlet NSLayoutConstraint* tableWidthConstraint;
}

@end

@implementation ChooseMediaVC

QVector<QString> mediaDevices;
QString defaultDevice;
NSInteger MEDIA_NAME_TAG = 100;
NSInteger CURRENT_SELECTION_TAG = 200;
CGFloat ROW_HEIGHT = 40;

-(void)setMediaDevices:(const QVector<QString>&)devices andDefaultDevice:(const QString&)device {
    mediaDevices = devices;
    defaultDevice = device;
    CGFloat tableHeight = ROW_HEIGHT * mediaDevices.size();
}

-(CGFloat)getTableWidth {
    NSTextField* textField = [[NSTextField alloc] init];
    CGFloat maxWidth = 0;
    for (auto device : mediaDevices) {
        textField.stringValue = device.toNSString();
        [textField sizeToFit];
        if (textField.frame.size.width > maxWidth) {
            maxWidth = textField.frame.size.width;
        }
    }
    return maxWidth;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGFloat tableHeight = ROW_HEIGHT * mediaDevices.size();
    CGFloat tableWidth = [self getTableWidth] + 65;
    tableHeightConstraint.constant = tableHeight;
    tableWidthConstraint.constant = tableWidth;
    // Do view setup here.
}
#pragma mark - NSTableViewDelegate methods

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    HoverTableRowView *howerRow = [tableView makeViewWithIdentifier:@"HoverRowView" owner:nil];
    [howerRow setBlurType:7];
    return howerRow;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView* result = [tableView makeViewWithIdentifier:@"MediaDeviceCell" owner:tableView];
    NSTextField* mediaName = [result viewWithTag: MEDIA_NAME_TAG];
    NSImageView* currentSelection = [result viewWithTag: CURRENT_SELECTION_TAG];
    mediaName.stringValue = mediaDevices[row].toNSString();
    currentSelection.hidden = mediaDevices[row] != defaultDevice;
    NSImage* image =  [NSColor image: currentSelection.image tintedWithColor: [NSColor textColor]];
    currentSelection.image = image;
    return result;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = [notification.object selectedRow];
    self.onDeviceSelected(mediaDevices[row].toNSString());
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return ROW_HEIGHT;
}

#pragma mark - NSTableDataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return mediaDevices.size();
}

@end

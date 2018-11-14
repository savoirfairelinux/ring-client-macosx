/*
 *  Copyright (C) 2015-2016 Savoir-faire Linux Inc.
 *  Author: Alexandre Lision <alexandre.lision@savoirfairelinux.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
 */
#import "CurrentCallVC.h"
#import <libavutil/frame.h>

#import <QuartzCore/QuartzCore.h>

///Qt
#import <QMimeData>
#import <QtMacExtras/qmacfunctions.h>
#import <QtCore/qabstractitemmodel.h>
#import <QPixmap>
#import <QUrl>

///LRC
#import <video/previewmanager.h>
#import <video/renderer.h>
#import <api/newcallmodel.h>
#import <api/call.h>
#import <api/conversationmodel.h>
#import <api/avmodel.h>
#import <api/newvideo.h>
#include <api/newcodecmodel.h>

#import <globalinstances.h>

#import "AppDelegate.h"
#import "views/ITProgressIndicator.h"
#import "views/CallView.h"
#import "views/NSColor+RingTheme.h"
#import "delegates/ImageManipulationDelegate.h"
#import "ChatVC.h"
#import "views/IconButton.h"
#import "views/CallLayer.h"
#import "utils.h"

@interface RendererConnectionsHolder : NSObject

@property QMetaObject::Connection frameUpdated;
@property QMetaObject::Connection started;
@property QMetaObject::Connection stopped;
@property QMetaObject::Connection previewFrameUpdated;


@end

@implementation RendererConnectionsHolder

@end

@interface CurrentCallVC () <NSPopoverDelegate> {
    std::string convUid_;
    std::string callUid_;
    const lrc::api::account::Info *accountInfo_;
    NSTimer* refreshDurationTimer;
}

// Main container
@property (unsafe_unretained) IBOutlet NSSplitView* splitView;
@property (unsafe_unretained) IBOutlet NSView* backgroundImage;
@property (unsafe_unretained) IBOutlet NSBox* bluerBackgroundEffect;

// Header info
@property (unsafe_unretained) IBOutlet NSView* headerContainer;
@property (unsafe_unretained) IBOutlet NSTextField* personLabel;
@property (unsafe_unretained) IBOutlet NSTextField* stateLabel;
@property (unsafe_unretained) IBOutlet NSTextField* timeSpentLabel;
@property (unsafe_unretained) IBOutlet NSImageView* personPhoto;

@property (unsafe_unretained) IBOutlet NSImageView* outgoingPhoto;
@property (unsafe_unretained) IBOutlet NSTextField* outgoingPersonLabel;
@property (unsafe_unretained) IBOutlet NSTextField* outgoingStateLabel;
@property (unsafe_unretained) IBOutlet NSTextField* outgoingId;

// Call Controls
@property (unsafe_unretained) IBOutlet NSView* controlsPanel;

@property (unsafe_unretained) IBOutlet IconButton* holdOnOffButton;
@property (unsafe_unretained) IBOutlet IconButton* hangUpButton;
@property (unsafe_unretained) IBOutlet IconButton* recordOnOffButton;
@property (unsafe_unretained) IBOutlet IconButton* pickUpButton;
@property (unsafe_unretained) IBOutlet IconButton* muteAudioButton;
@property (unsafe_unretained) IBOutlet IconButton* muteVideoButton;
@property (unsafe_unretained) IBOutlet IconButton* transferButton;
@property (unsafe_unretained) IBOutlet IconButton* addParticipantButton;
@property (unsafe_unretained) IBOutlet IconButton* chatButton;
@property (unsafe_unretained) IBOutlet IconButton* qualityButton;

@property (unsafe_unretained) IBOutlet NSView* advancedPanel;
@property (unsafe_unretained) IBOutlet IconButton* advancedButton;
@property (assign) IBOutlet NSLayoutConstraint* callRecordButtonMarginLeft;

@property (strong) NSPopover* addToContactPopover;
@property (strong) NSPopover* brokerPopoverVC;
@property (strong) IBOutlet ChatVC* chatVC;

// Ringing call panel
@property (unsafe_unretained) IBOutlet NSView* ringingPanel;
@property (unsafe_unretained) IBOutlet NSImageView* incomingPersonPhoto;
@property (unsafe_unretained) IBOutlet NSTextField* incomingDisplayName;

// Outgoing call panel
@property (unsafe_unretained) IBOutlet NSView* outgoingPanel;
@property (unsafe_unretained) IBOutlet ITProgressIndicator *loadingIndicator;

// audio only view
@property (unsafe_unretained) IBOutlet NSView* audioCallView;
@property (unsafe_unretained) IBOutlet NSImageView* audioCallPhoto;
@property (unsafe_unretained) IBOutlet NSTextField* audioCallTime;
@property (unsafe_unretained) IBOutlet NSTextField* audioCallPersonLabel;
@property (unsafe_unretained) IBOutlet NSTextField* audioCallPersonId;
@property (unsafe_unretained) IBOutlet NSImageView* incomingImage;

// Video
@property (unsafe_unretained) IBOutlet CallView *videoView;
@property (unsafe_unretained) IBOutlet NSView *previewView;

@property RendererConnectionsHolder* renderConnections;
//@property RendererConnectionsHolder* videoHolder;
@property QMetaObject::Connection videoStarted;
@property QMetaObject::Connection selectedCallChanged;
@property QMetaObject::Connection messageConnection;
@property QMetaObject::Connection mediaAddedConnection;
@property QMetaObject::Connection profileUpdatedConnection;

@end

@implementation CurrentCallVC

lrc::api::AVModel* mediaModel;
@synthesize personLabel, personPhoto, stateLabel, holdOnOffButton, hangUpButton,
            recordOnOffButton, pickUpButton, chatButton, transferButton, addParticipantButton, timeSpentLabel,
            muteVideoButton, muteAudioButton, controlsPanel, advancedPanel, advancedButton, headerContainer, videoView,
            incomingDisplayName, incomingPersonPhoto, previewView, splitView, loadingIndicator, ringingPanel,
            outgoingPanel, outgoingPersonLabel, outgoingStateLabel, outgoingPhoto, outgoingId,
            callRecordButtonMarginLeft, audioCallView, audioCallPhoto, audioCallTime, audioCallPersonLabel, audioCallPersonId, backgroundImage, bluerBackgroundEffect;

@synthesize renderConnections;
//@synthesize videoHolder;

NSLock* frameLk;

-(void) setCurrentCall:(const std::string&)callUid
          conversation:(const std::string&)convUid
               account:(const lrc::api::account::Info*)account
               avModel:(lrc::api::AVModel *)avModel
{
    if(account == nil)
        return;

    mediaModel = avModel;

    auto* callModel = account->callModel.get();

    if (not callModel->hasCall(callUid)){
        callUid_.clear();
        return;
    }
    callUid_ = callUid;
    convUid_ = convUid;
    accountInfo_ = account;
    [self.chatVC setConversationUid:convUid model:account->conversationModel.get()];
    auto currentCall = callModel->getCall(callUid_);
    [muteVideoButton setHidden: currentCall.isAudioOnly ? YES: NO];
    callRecordButtonMarginLeft.constant = currentCall.isAudioOnly ? -40.0f: 10.0f;
    [previewView setHidden: YES];
    videoView.callId = callUid;
}

- (void) ensureLayoutForCallStatus:(lrc::api::call::Status) status {
    using Status = lrc::api::call::Status;
    switch (status) {
        case Status::IN_PROGRESS:
            if (![videoView.layer isKindOfClass:[CallLayer class]]) {
                [videoView setLayer:[[CallLayer alloc] init]];
            }
            break;
        default:
            if ([videoView.layer isKindOfClass:[CallLayer class]]) {
                [videoView setLayer:[CALayer layer]];
                [videoView.layer setBackgroundColor:[[NSColor blackColor] CGColor]];
            }
            break;
    }
    holdOnOffButton.image = status == lrc::api::call::Status::PAUSED ?
    [NSImage imageNamed:@"ic_action_holdoff.png"] : [NSImage imageNamed:@"ic_action_hold.png"];
}

- (void)awakeFromNib
{
    NSLog(@"INIT CurrentCall VC");
    [self.view setWantsLayer:YES];

    [previewView setWantsLayer:YES];
    [previewView.layer setBackgroundColor:[NSColor blackColor].CGColor];
    [previewView.layer setContentsGravity:kCAGravityResizeAspectFill];
    [previewView.layer setFrame:previewView.frame];

    [controlsPanel setWantsLayer:YES];
    [controlsPanel.layer setBackgroundColor:[NSColor clearColor].CGColor];
    [controlsPanel.layer setFrame:controlsPanel.frame];

    renderConnections = [[RendererConnectionsHolder alloc] init];
    //videoHolder = [[RendererConnectionsHolder alloc] init];

    [loadingIndicator setColor:[NSColor whiteColor]];
    [loadingIndicator setNumberOfLines:200];
    [loadingIndicator setWidthOfLine:4];
    [loadingIndicator setLengthOfLine:4];
    [loadingIndicator setInnerMargin:59];

    [self.videoView setCallDelegate:self];
    CGColor* color = [[[NSColor blackColor] colorWithAlphaComponent:0.2] CGColor];
    [headerContainer.layer setBackgroundColor:color];
    [bluerBackgroundEffect setWantsLayer:YES];
    bluerBackgroundEffect.alphaValue = 0.6;
    [audioCallView setWantsLayer:YES];
    [audioCallView.layer setBackgroundColor: [[NSColor clearColor] CGColor]];
    [backgroundImage setWantsLayer: YES];
    backgroundImage.layer.contentsGravity = kCAGravityResizeAspectFill;
    frameLk = [[NSLock alloc] init];
}

-(void) updateDurationLabel
{
    if (accountInfo_ != nil) {
        auto* callModel = accountInfo_->callModel.get();
        if (callModel->hasCall(callUid_)) {
            auto& callStatus = callModel->getCall(callUid_).status;
            if (callStatus != lrc::api::call::Status::ENDED &&
                callStatus != lrc::api::call::Status::TERMINATING &&
                callStatus != lrc::api::call::Status::INVALID) {
                if(callModel->getCall(callUid_).isAudioOnly) {
                    [audioCallTime setStringValue:@(callModel->getFormattedCallDuration(callUid_).c_str())];
                } else {
                    [timeSpentLabel setStringValue:@(callModel->getFormattedCallDuration(callUid_).c_str())];
                }
                return;
            }
        }
    }

    // If call is not running anymore or accountInfo_ is not set for any reason
    // we stop the refresh loop
    [refreshDurationTimer invalidate];
    refreshDurationTimer = nil;
    [timeSpentLabel setHidden:YES];
    [audioCallView setHidden:YES];
}

-(void) updateCall
{
    if (accountInfo_ == nil)
        return;

    auto* callModel = accountInfo_->callModel.get();
    if (not callModel->hasCall(callUid_)) {
        return;
    }

    auto currentCall = callModel->getCall(callUid_);
    NSLog(@"\n status %@ \n",@(lrc::api::call::to_string(currentCall.status).c_str()));
    auto convIt = getConversationFromUid(convUid_, *accountInfo_->conversationModel);
    if (convIt != accountInfo_->conversationModel->allFilteredConversations().end()) {
        NSString* bestName = bestNameForConversation(*convIt, *accountInfo_->conversationModel);
        [personLabel setStringValue:bestName];
        [outgoingPersonLabel setStringValue:bestName];
        [audioCallPersonLabel setStringValue:bestName];
        NSString* ringID = bestIDForConversation(*convIt, *accountInfo_->conversationModel);
        if([bestName isEqualToString:ringID]) {
            ringID = @"";
        }
        [outgoingId setStringValue:ringID];
        [audioCallPersonId setStringValue:ringID];
    }

    [timeSpentLabel setStringValue:@(callModel->getFormattedCallDuration(callUid_).c_str())];
    [audioCallTime setStringValue:@(callModel->getFormattedCallDuration(callUid_).c_str())];
    if (refreshDurationTimer == nil)
        refreshDurationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                target:self
                                                              selector:@selector(updateDurationLabel)
                                                              userInfo:nil
                                                               repeats:YES];
    [stateLabel setStringValue:@(to_string(currentCall.status).c_str())];
    [outgoingStateLabel setStringValue:@(to_string(currentCall.status).c_str())];

    // Default values for this views
    [loadingIndicator setHidden:YES];
    [ringingPanel setHidden:YES];
    [outgoingPanel setHidden:YES];
    [controlsPanel setHidden:NO];
    [headerContainer setHidden:NO];
    [chatButton setHidden:NO];
    [self setBackground];

    using Status = lrc::api::call::Status;
    [self ensureLayoutForCallStatus:currentCall.status];
    switch (currentCall.status) {
        case Status::SEARCHING:
        case Status::CONNECTING:
            [headerContainer setHidden:YES];
            [outgoingPanel setHidden:NO];
            [outgoingPhoto setHidden:NO];
            [self setupContactInfo:outgoingPhoto];
            [loadingIndicator setHidden:NO];
            [controlsPanel setHidden:YES];
            break;
        case Status::INCOMING_RINGING:
            [outgoingPhoto setHidden:YES];
            [controlsPanel setHidden:YES];
            [outgoingPanel setHidden:YES];
            [self setupIncoming:callUid_];
            break;
        case Status::OUTGOING_RINGING:
            [controlsPanel setHidden:YES];
            [outgoingPanel setHidden:NO];
            [loadingIndicator setHidden:NO];
            [headerContainer setHidden:YES];
            break;
        /*case Status::CONFERENCE:
            [self setupConference:currentCall];
            break;*/
        case Status::PAUSED:
        case Status::INACTIVE:
        case Status::IN_PROGRESS:
            // change constraints (uncollapse avatar)
            if(currentCall.isAudioOnly) {
                [self setUpAudioOnlyView];
            } else {
                [self setUpVideoCallView];
            }
            break;
        case Status::CONNECTED:
            break;
        case Status::ENDED:
        case Status::TERMINATING:
        case Status::INVALID:
            break;
    }
}

-(void) setUpVideoCallView {
    [self setupContactInfo:personPhoto];
    [timeSpentLabel setHidden:NO];
    [outgoingPhoto setHidden:YES];
    [headerContainer setHidden:NO];
    [previewView setHidden: NO];
    [bluerBackgroundEffect setHidden:YES];
    [backgroundImage setHidden:YES];
}

-(void) setUpAudioOnlyView {
    [audioCallView setHidden:NO];
    [headerContainer setHidden:YES];
    [audioCallPhoto setImage: [self getContactImageOfSize:120.0 withDefaultAvatar:YES]];
}

-(void) setBackground {
    auto* convModel = accountInfo_->conversationModel.get();
    auto it = getConversationFromUid(convUid_, *convModel);
    NSImage *image= [self getContactImageOfSize:120.0 withDefaultAvatar:NO];
    if(image) {
        CIImage * ciImage = [[CIImage alloc] initWithData:[image TIFFRepresentation]];
        CIContext *context = [[CIContext alloc] init];
        CIFilter *clamp = [CIFilter filterWithName:@"CIAffineClamp"];
        [clamp setValue:[NSAffineTransform transform] forKey:@"inputTransform"];
        [clamp setValue:ciImage forKey: kCIInputImageKey];
        CIFilter* bluerFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [bluerFilter setDefaults];
        [bluerFilter setValue:[NSNumber numberWithFloat: 9] forKey:@"inputRadius"];
        [bluerFilter setValue:[clamp valueForKey:kCIOutputImageKey] forKey: kCIInputImageKey];
        CIImage *result = [bluerFilter valueForKey:kCIOutputImageKey];
        CGRect extent = [result extent];
        CGImageRef cgImage = [context createCGImage:result fromRect: [ciImage extent]];
        NSImage *bluredImage = [[NSImage alloc] initWithCGImage:cgImage size:NSSizeFromCGSize(CGSizeMake(image.size.width, image.size.height))];
        backgroundImage.layer.contents = bluredImage;
        [backgroundImage setHidden:NO];
    } else {
        [bluerBackgroundEffect setFillColor:[NSColor ringDarkGrey]];
        [backgroundImage setHidden:YES];
    }
}

-(NSImage *) getContactImageOfSize: (double) size withDefaultAvatar:(BOOL) shouldDrawDefault {
    auto* convModel = accountInfo_->conversationModel.get();
    auto convIt = getConversationFromUid(convUid_, *convModel);
    if (convIt == convModel->allFilteredConversations().end()) {
        return nil;
    }
    if(shouldDrawDefault) {
        auto& imgManip = reinterpret_cast<Interfaces::ImageManipulationDelegate&>(GlobalInstances::pixmapManipulator());
        QVariant photo = imgManip.conversationPhoto(*convIt, *accountInfo_, QSize(size, size), NO);
        return QtMac::toNSImage(qvariant_cast<QPixmap>(photo));
    }
    auto contact = accountInfo_->contactModel->getContact(convIt->participants[0]);
    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:@(contact.profileInfo.avatar.c_str()) options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return [[NSImage alloc] initWithData:imageData];
}


-(void) setupContactInfo:(NSImageView*)imageView
{
    [imageView setImage: [self getContactImageOfSize:120.0 withDefaultAvatar:YES]];
}

-(void) setupIncoming:(const std::string&) callId
{
    if (accountInfo_ == nil)
        return;

    auto* callModel = accountInfo_->callModel.get();
    if (not callModel->hasCall(callUid_)) {
        return;
    }

    auto call = callModel->getCall(callUid_);
    auto* convModel = accountInfo_->conversationModel.get();

    [ringingPanel setHidden:NO];
    [controlsPanel setHidden:YES];
    [headerContainer setHidden:YES];
    auto it = getConversationFromUid(convUid_, *convModel);
    if (it != convModel->allFilteredConversations().end()) {
        [incomingPersonPhoto setImage: [self getContactImageOfSize:120.0 withDefaultAvatar:YES]];
        [incomingDisplayName setStringValue:bestNameForConversation(*it, *convModel)];
    }
}


-(void) setupConference:(Call*) c
{
    [videoView setShouldAcceptInteractions:YES];
    [self.chatButton setHidden:NO];
    [self.addParticipantButton setHidden:NO];
    [self.transferButton setHidden:YES];
}

-(void)collapseRightView
{
    NSView *right = [[splitView subviews] objectAtIndex:1];
    NSView *left  = [[splitView subviews] objectAtIndex:0];
    NSRect leftFrame = [left frame];
    [right setHidden:YES];
    [splitView display];
}

- (void) changeCallSelection:(std::string&)callUid
{
    if (accountInfo_ == nil)
        return;

    auto* callModel = accountInfo_->callModel.get();
    if (not callModel->hasCall(callUid)) {
        return;
    }

    QObject::disconnect(self.selectedCallChanged);
    self.selectedCallChanged = QObject::connect(callModel,
                                                &lrc::api::NewCallModel::callStatusChanged,
                                                [self](const std::string callId) {
                                                    [self updateCall];
                                                });
}

-(void) connectVideoSignals
{
    if (accountInfo_ == nil)
        return;

//    auto* callModel = accountInfo_->callModel.get();
//    QObject::disconnect(self.videoStarted);
//    self.videoStarted = QObject::connect(callModel,
//                                         &lrc::api::NewCallModel::remotePreviewStarted,
//                                         [self](const std::string& callId, Video::Renderer* renderer) {
//                                             NSLog(@"Video started!");
//                                             [videoView setLayer:[[CallLayer alloc] init]];
//                                             [videoView setShouldAcceptInteractions:YES];
//                                             [self mouseIsMoving: NO];
//                                             [self connectVideoRenderer:renderer];
//                                         });
//
//    if (callModel->hasCall(callUid_)) {
//        if (auto renderer = callModel->getRenderer(callUid_)) {
//            QObject::disconnect(self.videoStarted);
//             //[videoView setLayer:[[CallLayer alloc] init]];
//            [self connectVideoRenderer: renderer];
//        }
//    }
    [self connectRenderer];

}

-(void) connectRenderer
{
    QObject::disconnect(renderConnections.frameUpdated);
    QObject::disconnect(renderConnections.stopped);
    QObject::disconnect(renderConnections.started);
   // QObject::disconnect(renderConnections.previewFrameUpdated);
    renderConnections.started =
    QObject::connect(mediaModel,
                     &lrc::api::AVModel::rendererStarted,
                     [=](const std::string& id) {
                         QObject::disconnect(renderConnections.frameUpdated);
                         renderConnections.frameUpdated =
                         QObject::connect(mediaModel,
                                          &lrc::api::AVModel::avframeUpdated,
                                          [=] (const std::string &id) {

                                            if (id == lrc::api::video::PREVIEW_RENDERER_ID) {
//                                                auto renderer = &mediaModel->getRenderer(lrc::api::video::PREVIEW_RENDERER_ID);
//                                                if(!renderer->isRendering()) {
//                                                    return;
//                                                }
//                                                 [self renderer: renderer renderFrameForPreviewView:previewView];

                                            } else {
                                                auto renderer = &mediaModel->getRenderer(id);
                                                if(!renderer->isRendering()) {
                                                    return;
                                                }
//                                                if(!frame) {
//                                                    return;
//                                                }
//
//                                                if (frame->data[3] == NULL) {
//                                                    return;
//                                                }
//                                                //[frameLk lock];
//                                                if(!(CVPixelBufferRef)frame->data[3]) {
//                                                    return;
//                                                }
//
//                                                CIImage *image = [CIImage imageWithCVPixelBuffer: (CVPixelBufferRef)frame->data[3]];
//                                                NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:image];
//                                                NSImage *nsImage = [[NSImage alloc] initWithSize:rep.size];
//                                                [nsImage addRepresentation:rep];
//                                                self.incomingImage.image = nsImage;
//                                                return;
//                                                [self renderer:renderer renderFrameForDistantView: videoView];
                                            }
//                                              if (id == lrc::api::video::PREVIEW_RENDERER_ID) {
//                                                  return;
//                                              }
//                                              auto renderer = &mediaModel->getRenderer(id);
//                                              if(!renderer->isRendering()) {
//                                                  return;
//                                              }
//                                              [self renderer:renderer renderFrameForDistantView: videoView];
                                          });
                        // NSString *isPreview = id == lrc::api::video::PREVIEW_RENDERER_ID ? @"YES" : @"NO";
                        // NSLog(@"renderstarted, %@ is preview, %@ ", @(id.c_str()), isPreview);
                         if (id == lrc::api::video::PREVIEW_RENDERER_ID) {
                          //   QObject::disconnect(renderConnections.frameUpdated);
                            // renderConnections.frameUpdated =
//                             QObject::connect(mediaModel,
//                                              &lrc::api::AVModel::frameUpdated,
//                                              [=](const std::string& id) {
//                                                  NSString *isPreview = id == lrc::api::video::PREVIEW_RENDERER_ID ? @"YES" : @"NO";
//auto renderer = &mediaModel->getRenderer(lrc::api::video::PREVIEW_RENDERER_ID);
//                            if(!renderer->isRendering()) {
//                                                                                                        return;
//                                                                                                    }
//                                                                                                    [self renderer: renderer renderFrameForPreviewView:previewView];
//                                              });

                             //QObject::disconnect(renderConnections.previewFrameUpdated);
//                             renderConnections.previewFrameUpdated =
//                             QObject::connect(mediaModel,
//                                              &lrc::api::AVModel::previewFrameUpdated,
//                                              [=]() {
//                                                  NSString *isPreview = id == lrc::api::video::PREVIEW_RENDERER_ID ? @"YES" : @"NO";
//                                                  //NSLog(@"previewrenderupdated, %@ is preview, %@ ", @(id.c_str()), isPreview);
//                                                  auto renderer = &mediaModel->getRenderer(lrc::api::video::PREVIEW_RENDERER_ID);
//                                                  if(!renderer->isRendering()) {
//                                                      return;
//                                                  }
//                                                  [self renderer: renderer renderFrameForPreviewView:previewView];
//                                              });
                         } else {
                             if (![videoView.layer isKindOfClass:[CallLayer class]]) {
                                 [videoView setLayer:[[CallLayer alloc] init]];
                             }
                             [self mouseIsMoving: NO];
                             [videoView setShouldAcceptInteractions:YES];
//                             QObject::disconnect(renderConnections.frameUpdated);
//                             renderConnections.frameUpdated =
//                             QObject::connect(mediaModel,
//                                              &lrc::api::AVModel::frameUpdated,
//                                              [=](const std::string& id) {
//                                                  NSString *isPreview = id == lrc::api::video::PREVIEW_RENDERER_ID ? @"YES" : @"NO";
//                                                //  NSLog(@"renderupdated, %@ is preview, %@ ", @(id.c_str()), isPreview);
//                                                  if (id == lrc::api::video::PREVIEW_RENDERER_ID) {
//                                                      return;
//                                                  }
//                                                  auto renderer = &mediaModel->getRenderer(id);
//                                                  if(!renderer->isRendering()) {
//                                                      return;
//                                                  }
//                                                  [self renderer:renderer renderFrameForDistantView: videoView];
//                                              });

                         }
                     });
    renderConnections.stopped =
    QObject::connect(mediaModel,
                     &lrc::api::AVModel::rendererStopped,
                     [=](const std::string& id) {
                         NSString *isPreview = id == lrc::api::video::PREVIEW_RENDERER_ID ? @"YES" : @"NO";
                       //  NSLog(@"renderstopped, %@ is preview, %@ ", @(id.c_str()), isPreview);
                         QObject::disconnect(renderConnections.previewFrameUpdated);
                         if (id == lrc::api::video::PREVIEW_RENDERER_ID) {
                             [previewView.layer setContents:nil];
                         } else {
                             QObject::disconnect(renderConnections.frameUpdated);
                             [videoView setLayer:[CALayer layer]];
                             [videoView.layer setBackgroundColor:[[NSColor blackColor] CGColor]];
                             [self mouseIsMoving: YES];
                             [videoView setShouldAcceptInteractions:NO];
                             [(CallLayer*)videoView.layer setVideoRunning:NO];
                         }

                     });
}

//-(void) connectVideoRenderer: (Video::Renderer*)renderer
//{
//    QObject::disconnect(videoHolder.frameUpdated);
//    QObject::disconnect(videoHolder.started);
//    QObject::disconnect(videoHolder.stopped);
//
//    if(renderer == nil)
//        return;
//
//    videoHolder.frameUpdated = QObject::connect(renderer,
//                     &Video::Renderer::frameUpdated,
//                     [=]() {
//                         [self renderer:renderer renderFrameForDistantView:videoView];
//                     });
//
//    videoHolder.started = QObject::connect(renderer,
//                     &Video::Renderer::started,
//                     [=]() {
//                         if (![videoView.layer isKindOfClass:[CallLayer class]]) {
//                             [videoView setLayer:[[CallLayer alloc] init]];
//                         }
//                         [self mouseIsMoving: NO];
//                         [videoView setShouldAcceptInteractions:YES];
//                         QObject::disconnect(videoHolder.frameUpdated);
//                         videoHolder.frameUpdated = QObject::connect(renderer,
//                                                                     &Video::Renderer::frameUpdated,
//                                                                     [=]() {
//                                                                         [self renderer:renderer renderFrameForDistantView:videoView];
//                                                                     });
//                     });
//
//    videoHolder.stopped = QObject::connect(renderer,
//                     &Video::Renderer::stopped,
//                     [=]() {
//                         [videoView setLayer:[CALayer layer]];
//                         [videoView.layer setBackgroundColor:[[NSColor blackColor] CGColor]];
//                         [self mouseIsMoving: YES];
//                         [videoView setShouldAcceptInteractions:NO];
//                         QObject::disconnect(videoHolder.frameUpdated);
//                         [(CallLayer*)videoView.layer setVideoRunning:NO];
//                     });
//}

-(void) renderer: (const lrc::api::video::Renderer *)renderer renderFrameForPreviewView:(NSView*) view
{
    QSize res = renderer->size();

    auto frame_ptr = renderer->currentFrame();
    auto frame_data = frame_ptr.ptr;
    if (!frame_data)
        return;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(frame_data,
                                                    res.width(),
                                                    res.height(),
                                                    8,
                                                    4*res.width(),
                                                    colorSpace,
                                                    kCGImageAlphaPremultipliedLast);


    CGImageRef newImage = CGBitmapContextCreateImage(newContext);

    /*We release some components*/
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);

    [CATransaction begin];
    view.layer.contents = (__bridge id)newImage;
    [CATransaction commit];

    CFRelease(newImage);
}

-(void) renderer: (const lrc::api::video::Renderer *)renderer renderFrameForDistantView:(CallView*) view
{
    [frameLk lock];
    AVFrame* frame_ptr = renderer->currentAVFrame();
    if(!frame_ptr) {
        [frameLk unlock];
        return;
    }

    if (frame_ptr->data[3] == NULL) {
        [frameLk unlock];
        return;
    }
    //[frameLk lock];
    if(!(CVPixelBufferRef)frame_ptr->data[3]) {
        [frameLk unlock];
        return;
    }

    CIImage *image = [CIImage imageWithCVPixelBuffer: (CVPixelBufferRef)frame_ptr->data[3]];
    [frameLk unlock];
    NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:image];
    NSImage *nsImage = [[NSImage alloc] initWithSize:rep.size];
    [nsImage addRepresentation:rep];
    self.incomingImage.image = nsImage;
//    CallLayer* callLayer = (CallLayer*) view.layer;
     //[frameLk unlock];
//    if ([callLayer respondsToSelector:@selector(setCurrentFrame:)]) {
//                [callLayer setCurrentFrame:(CVPixelBufferRef)frame_ptr->data[3]];
//                [callLayer setVideoRunning:YES];
//            }
//    if (!frame_ptr->pointer())
//        return;
//
//    CallLayer* callLayer = (CallLayer*) view.layer;
//    if ([callLayer respondsToSelector:@selector(setCurrentFrame:)]) {
//        [callLayer setCurrentFrame:*std::move(&frame_ptr)];
//        [callLayer setVideoRunning:YES];
//    }
}

- (void) initFrame
{
    [self.view setFrame:self.view.superview.bounds];
    [self.view setHidden:YES];
    self.view.layer.position = self.view.frame.origin;
    [self collapseRightView];
}

# pragma private IN/OUT animations

-(void)uncollapseRightView
{
    NSView *left  = [[splitView subviews] objectAtIndex:0];
    NSView *right = [[splitView subviews] objectAtIndex:1];
    [right setHidden:NO];

    CGFloat dividerThickness = [splitView dividerThickness];

    // get the different frames
    NSRect leftFrame = [left frame];
    NSRect rightFrame = [right frame];

    leftFrame.size.width = (leftFrame.size.width - rightFrame.size.width - dividerThickness);
    rightFrame.origin.x = leftFrame.size.width + dividerThickness;
    [left setFrameSize:leftFrame.size];
    [right setFrame:rightFrame];
    [splitView display];

    [self.chatVC takeFocus];
}

-(void) cleanUp
{
    if(self.splitView.isInFullScreenMode)
        [self.splitView exitFullScreenModeWithOptions:nil];
    QObject::disconnect(renderConnections.frameUpdated);
    QObject::disconnect(renderConnections.started);
    QObject::disconnect(renderConnections.stopped);
//    QObject::disconnect(previewHolder.frameUpdated);
//    QObject::disconnect(previewHolder.stopped);
//    QObject::disconnect(previewHolder.started);
    QObject::disconnect(self.messageConnection);
    [previewView.layer setContents:nil];
    [previewView setHidden: YES];
    [videoView setLayer:[CALayer layer]];
    [videoView.layer setBackgroundColor:[[NSColor blackColor] CGColor]];

    [self.chatButton setHidden:YES];
    [self.chatButton setPressed:NO];
    [self collapseRightView];

    [personLabel setStringValue:@""];
    [timeSpentLabel setStringValue:@""];
    [stateLabel setStringValue:@""];
    //audio view
    [audioCallTime setStringValue:@""];
    [audioCallPersonId setStringValue:@""];
    [audioCallPersonLabel setStringValue:@""];
    [audioCallView setHidden:YES];
    [audioCallPhoto setImage:nil];
    //background view
    [bluerBackgroundEffect setHidden:NO];
    [backgroundImage setHidden:NO];
    //outgoing view
    [outgoingPersonLabel setStringValue:@""];
    [outgoingStateLabel setStringValue:@""];
}

-(void) setupCallView
{
    if (accountInfo_ == nil)
        return;

    auto* callModel = accountInfo_->callModel.get();
    auto* convModel = accountInfo_->conversationModel.get();

    // when call comes in we want to show the controls/header
    [self mouseIsMoving: YES];
    [videoView setShouldAcceptInteractions: NO];

    [self connectVideoSignals];
    /* check if text media is already present */
    if(not callModel->hasCall(callUid_))
        return;

    [loadingIndicator setAnimates:YES];
    [self updateCall];

    /* monitor media for messaging text messaging */
    QObject::disconnect(self.messageConnection);
    self.messageConnection = QObject::connect(convModel,
                                              &lrc::api::ConversationModel::interactionStatusUpdated,
                                              [self] (std::string convUid,
                                                      uint64_t msgId,
                                                      lrc::api::interaction::Info msg) {
                                                  if (msg.type == lrc::api::interaction::Type::TEXT) {
                                                      if(not [[self splitView] isSubviewCollapsed:[[[self splitView] subviews] objectAtIndex: 1]]){
                                                          return;
                                                      }
                                                      [self uncollapseRightView];
                                                  }
                                              });
    //monitor for updated profile
    QObject::disconnect(self.profileUpdatedConnection);
    self.profileUpdatedConnection =
    QObject::connect(accountInfo_->contactModel.get(),
                     &lrc::api::ContactModel::contactAdded,
                     [self](const std::string &contactUri) {
                         auto convIt = getConversationFromUid(convUid_, *accountInfo_->conversationModel.get());
                         if (convIt == accountInfo_->conversationModel->allFilteredConversations().end()) {
                             return;
                         }
                         if (convIt->participants.empty()) {
                             return;

                         }
                         auto& contact = accountInfo_->contactModel->getContact(convIt->participants[0]);
                         if (contact.profileInfo.type == lrc::api::profile::Type::RING && contact.profileInfo.uri == contactUri)
                             accountInfo_->conversationModel->makePermanent(convUid_);
                         [incomingPersonPhoto setImage: [self getContactImageOfSize:120.0 withDefaultAvatar:YES]];
                         [outgoingPhoto setImage: [self getContactImageOfSize:120.0 withDefaultAvatar:YES]];
                         [self.delegate conversationInfoUpdatedFor:convUid_];
                         if(accountInfo_->callModel.get()->getCall(callUid_).isAudioOnly) {
                         [audioCallPhoto setImage: [self getContactImageOfSize:120.0 withDefaultAvatar:YES]];
                             [self setBackground];
                             return;
                         }
                         [personPhoto setImage: [self getContactImageOfSize:120.0 withDefaultAvatar:YES]];
                     });
}

-(void) showWithAnimation:(BOOL)animate
{
    if (!animate) {
        [self.view setHidden:NO];
        [self setupCallView];
        return;
    }

    CGRect frame = CGRectOffset(self.view.superview.bounds, -self.view.superview.bounds.size.width, 0);
    [self.view setHidden:NO];

    [CATransaction begin];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setFromValue:[NSValue valueWithPoint:frame.origin]];
    [animation setToValue:[NSValue valueWithPoint:self.view.superview.bounds.origin]];
    [animation setDuration:0.2f];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [CATransaction setCompletionBlock:^{
        [self setupCallView];
    }];

    [self.view.layer addAnimation:animation forKey:animation.keyPath];
    [CATransaction commit];
}

-(void) hideWithAnimation:(BOOL)animate
{
    if(self.view.frame.origin.x < 0) {
        return;
    }

    if (!animate) {
        [self.view setHidden:YES];
        return;
    }

    CGRect frame = CGRectOffset(self.view.frame, -self.view.frame.size.width, 0);
    [CATransaction begin];
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setFromValue:[NSValue valueWithPoint:self.view.frame.origin]];
    [animation setToValue:[NSValue valueWithPoint:frame.origin]];
    [animation setDuration:0.2f];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];

    [CATransaction setCompletionBlock:^{
        [self.view setHidden:YES];
        // first make sure everything is disconnected
        [self cleanUp];
//        if (currentCall_) {
//            [self animateIn];
//        }
    }];
    [self.view.layer addAnimation:animation forKey:animation.keyPath];

    [self.view.layer setPosition:frame.origin];
    [CATransaction commit];
}

/**
 *  Debug purpose
 */
-(void) dumpFrame:(CGRect) frame WithName:(NSString*) name
{
    NSLog(@"frame %@ : %f %f %f %f \n\n",name ,frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
}

#pragma mark - Button methods

- (IBAction)hangUp:(id)sender {
    if (accountInfo_ == nil)
        return;

    auto* callModel = accountInfo_->callModel.get();

    callModel->hangUp(callUid_);
}

- (IBAction)accept:(id)sender {
    if (accountInfo_ == nil)
        return;

    // If we accept a conversation with a non trusted contact, we first accept it
    auto convIt = getConversationFromUid(convUid_, *accountInfo_->conversationModel.get());
    if (convIt != accountInfo_->conversationModel->allFilteredConversations().end()) {
        auto& contact = accountInfo_->contactModel->getContact(convIt->participants[0]);
        if (contact.profileInfo.type == lrc::api::profile::Type::PENDING)
            accountInfo_->conversationModel->makePermanent(convUid_);
    }

    auto* callModel = accountInfo_->callModel.get();

    callModel->accept(callUid_);
}

- (IBAction)toggleRecording:(id)sender {
    if (accountInfo_ == nil)
        return;

    auto* callModel = accountInfo_->callModel.get();

    callModel->toggleAudioRecord(callUid_);
    [recordOnOffButton setPressed:!recordOnOffButton.isPressed];
}

- (IBAction)toggleHold:(id)sender {
    if (accountInfo_ == nil)
        return;

    auto* callModel = accountInfo_->callModel.get();
    auto currentCall = callModel->getCall(callUid_);
    if (currentCall.status != lrc::api::call::Status::PAUSED) {
        holdOnOffButton.image = [NSImage imageNamed:@"ic_action_holdoff.png"];
    } else {
        holdOnOffButton.image = [NSImage imageNamed:@"ic_action_hold.png"];
    }

    callModel->togglePause(callUid_);
}

- (IBAction)toggleAdvancedControls:(id)sender {
    [advancedButton setPressed:!advancedButton.isPressed];
    [advancedPanel setHidden:![advancedButton isPressed]];
}

- (IBAction)showDialpad:(id)sender {
    AppDelegate* appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [appDelegate showDialpad];
}

-(IBAction)toggleChat:(id)sender;
{
    BOOL rightViewCollapsed = [[self splitView] isSubviewCollapsed:[[[self splitView] subviews] objectAtIndex: 1]];
    if (rightViewCollapsed) {
        [self uncollapseRightView];
    } else {
        [self collapseRightView];
    }
    [chatButton setPressed:rightViewCollapsed];
}

- (IBAction)muteAudio:(id)sender
{
    if (accountInfo_ == nil)
        return;

    auto* callModel = accountInfo_->callModel.get();
    auto currentCall = callModel->getCall(callUid_);
    if (currentCall.audioMuted) {
        muteAudioButton.image = [NSImage imageNamed:@"ic_action_audio.png"];
    } else {
       muteAudioButton.image = [NSImage imageNamed:@"ic_action_mute_audio.png"];
    }
    callModel->toggleMedia(callUid_, lrc::api::NewCallModel::Media::AUDIO);
}

- (IBAction)muteVideo:(id)sender
{
    if (accountInfo_ == nil)
        return;
    auto* callModel = accountInfo_->callModel.get();
    auto currentCall = callModel->getCall(callUid_);
    if(!currentCall.isAudioOnly) {
        if (currentCall.videoMuted) {
            muteVideoButton.image = [NSImage imageNamed:@"ic_action_video.png"];
        } else {
            muteVideoButton.image = [NSImage imageNamed:@"ic_action_mute_video.png"];
        }
    }
    callModel->toggleMedia(callUid_, lrc::api::NewCallModel::Media::VIDEO);
}

- (IBAction)toggleTransferView:(id)sender {

}

- (IBAction)toggleAddParticipantView:(id)sender {
    
}

#pragma mark - NSPopOverDelegate

- (void)popoverWillClose:(NSNotification *)notification
{
    if (_brokerPopoverVC != nullptr) {
        [_brokerPopoverVC performClose:self];
        _brokerPopoverVC = NULL;
    }

    if (self.addToContactPopover != nullptr) {
        [self.addToContactPopover performClose:self];
        self.addToContactPopover = NULL;
    }

    [self.transferButton setPressed:NO];
    [self.addParticipantButton setState:NSOffState];
}

- (void)popoverDidClose:(NSNotification *)notification
{
    [videoView setCallDelegate:self];
}

#pragma mark - ContactLinkedDelegate

- (void)contactLinked
{
    if (self.addToContactPopover != nullptr) {
        [self.addToContactPopover performClose:self];
        self.addToContactPopover = NULL;
    }
}

#pragma mark - NSSplitViewDelegate

/* Return YES if the subview should be collapsed because the user has double-clicked on an adjacent divider. If a split view has a delegate, and the delegate responds to this message, it will be sent once for the subview before a divider when the user double-clicks on that divider, and again for the subview after the divider, but only if the delegate returned YES when sent -splitView:canCollapseSubview: for the subview in question. When the delegate indicates that both subviews should be collapsed NSSplitView's behavior is undefined.
 */
- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex;
{
    NSView* rightView = [[splitView subviews] objectAtIndex:1];
    return ([subview isEqual:rightView]);
}


- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview;
{
    NSView* rightView = [[splitView subviews] objectAtIndex:1];
    return ([subview isEqual:rightView]);
}


# pragma mark - CallnDelegate

- (void) callShouldToggleFullScreen
{
    if(self.splitView.isInFullScreenMode)
        [self.splitView exitFullScreenModeWithOptions:nil];
    else {
        NSApplicationPresentationOptions options = NSApplicationPresentationDefault +NSApplicationPresentationAutoHideDock +
        NSApplicationPresentationAutoHideMenuBar + NSApplicationPresentationAutoHideToolbar;
        NSDictionary *opts = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:options],
                              NSFullScreenModeApplicationPresentationOptions, nil];

        [self.splitView enterFullScreenMode:[NSScreen mainScreen]  withOptions:opts];
    }
}

-(void) mouseIsMoving:(BOOL) move
{
    [[controlsPanel animator] setAlphaValue:move]; // fade out
    [[headerContainer animator] setAlphaValue:move];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
    return YES;
}

-(void) screenShare {
    NSScreen *mainScreen = [NSScreen mainScreen];
    NSRect screenFrame = mainScreen.frame;
    QRect captureRect = QRect(screenFrame.origin.x, screenFrame.origin.y, screenFrame.size.width, screenFrame.size.height);
    mediaModel->setDisplay(0, screenFrame.origin.x, screenFrame.origin.y, screenFrame.size.width, screenFrame.size.height);
}
-(void) switchToDevice:(int)deviceID {
    auto devices = mediaModel->getDevices();
    auto device = devices[deviceID];
    mediaModel->switchInputTo(device);
}

-(std::vector<std::string>) getDeviceList {
    return mediaModel->getDevices();
}

-(void) switchToFile:(std::string)uri {
    mediaModel->setInputFile(QUrl::fromLocalFile(uri.c_str()).toLocalFile().toStdString());
}

@end

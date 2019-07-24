/*
 *  Copyright (C) 2019 Savoir-faire Linux Inc.
 *  Author: Kateryna Kostiuk <kateryna.kostiuk@savoirfairelinux.com>
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

#import "Common.h"

extern "C" {
#import <libavutil/frame.h>
}

@implementation Common

+ (void)copyLineByLineSrc:(uint8_t*)src
                  toDest:(uint8_t*)dest
                linesize:(int)linesize
                   bytes:(int)bytesPerRow
            numberOfRows:(int)rows {
    for (int i = 0; i < rows ; i++) {

        memcpy(dest, src, linesize);
        dest = dest + bytesPerRow;
        src = src + linesize;
    }
}

+ (void) fillPixelBuffr:(CVPixelBufferRef &)pixelBuffer
              fromFrame:(const AVFrame*)frame
             bufferPool:(CVPixelBufferPoolRef &)pixelBufferPool {

    if(!frame || !frame->data[0] || !frame->data[1]) {
        return;
    }
    CVReturn theError;
    bool createPool = false;
    if (!pixelBufferPool) {
        createPool = true;
    } else {
        NSDictionary* atributes = (__bridge NSDictionary*)CVPixelBufferPoolGetAttributes(pixelBufferPool);
        if(!atributes)
            atributes = (__bridge NSDictionary*)CVPixelBufferPoolGetPixelBufferAttributes(pixelBufferPool);
        int width = [[atributes objectForKey:(NSString*)kCVPixelBufferWidthKey] intValue];
        int height = [[atributes objectForKey:(NSString*)kCVPixelBufferHeightKey] intValue];
        if (width != frame->width || height != frame->height) {
            createPool = true;
        }
    }
    if (createPool) {
        CVPixelBufferPoolRelease(pixelBufferPool);
        CVPixelBufferRelease(pixelBuffer);
        pixelBuffer = nil;
        pixelBufferPool = nil;
        NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
        [attributes setObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
        [attributes setObject:[NSNumber numberWithInt:frame->width] forKey: (NSString*)kCVPixelBufferWidthKey];
        [attributes setObject:[NSNumber numberWithInt:frame->height] forKey: (NSString*)kCVPixelBufferHeightKey];
        [attributes setObject:@(frame->linesize[0]) forKey:(NSString*)kCVPixelBufferBytesPerRowAlignmentKey];
        [attributes setObject:[NSDictionary dictionary] forKey:(NSString*)kCVPixelBufferIOSurfacePropertiesKey];
        theError = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef) attributes, &pixelBufferPool);
        if (theError != kCVReturnSuccess) {
            NSLog(@"CVPixelBufferPoolCreate Failed");
            return;
        }
    }
    if(!pixelBuffer) {
        theError = CVPixelBufferPoolCreatePixelBuffer(NULL, pixelBufferPool, &pixelBuffer);
        if(theError != kCVReturnSuccess) {
            NSLog(@"CVPixelBufferPoolCreatePixelBuffer Failed");
            return;
        }
    }
    theError = CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    if (theError != kCVReturnSuccess) {
        NSLog(@"lock error");
        return;
    }
    size_t bytePerRowY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    size_t bytesPerRowUV = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    uint8_t*  base = static_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0));
    bool isPreview = (AVPixelFormat)frame->format == AV_PIX_FMT_NV12;
    if (bytePerRowY == frame->linesize[0] || isPreview) {
        memcpy(base, frame->data[0], bytePerRowY * frame->height);
    } else {
        [Common copyLineByLineSrc: frame->data[0]
                           toDest: base
                         linesize: frame->linesize[0]
                            bytes: bytePerRowY
                     numberOfRows: frame->height];
    }
    base = static_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1));
    if (isPreview) {
        if (bytesPerRowUV == frame->linesize[0]) {
            memcpy(base, frame->data[1], bytesPerRowUV * frame->height/2);
        } else {
            [Common copyLineByLineSrc: frame->data[1]
                               toDest: base
                             linesize: frame->linesize[0]
                                bytes: bytesPerRowUV
                         numberOfRows: frame->height/2];
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return;
    }

    uint32_t size = frame->linesize[1] * frame->height / 2;
    uint8_t* dstData = new uint8_t[2 * size];
    uint8_t * firstData = new uint8_t[size];
    memcpy(firstData, frame->data[1], size);
    uint8_t * secondData  = new uint8_t[size];
    memcpy(secondData, frame->data[2], size);
    for (int i = 0; i < 2 * size; i++){
        if (i % 2 == 0){
            dstData[i] = firstData[i/2];
        }else {
            dstData[i] = secondData[i/2];
        }
    }
    memcpy(base, dstData, bytesPerRowUV * frame->height/2);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    free(dstData);
    free(firstData);
    free(secondData);
}
@end

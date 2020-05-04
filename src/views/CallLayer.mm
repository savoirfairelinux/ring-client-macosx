/*
 *  Copyright (C) 2017-2019 Savoir-faire Linux Inc.
 *  Author: Anthony Léonard <anthony.leonard@savoirfairelinux.com>
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

#import "CallLayer.h"
#import <OpenGL/gl3.h>

static const GLchar* vShaderSrc = R"glsl(
#version 150

in vec2 in_Pos;
in vec2 in_TexCoord;
uniform vec2 in_Scaling;

out vec2 texCoord;

void main()
{
    texCoord = in_TexCoord;
    gl_Position = vec4(in_Pos.x*in_Scaling.x, in_Pos.y*in_Scaling.y, 0.0, 1.0);
}
)glsl";

static const GLchar* fShaderSrc = R"glsl(
#version 150

out vec4 fragColor;
in vec2 texCoord;

uniform sampler2D tex_y, tex_uv;

void main()
{
    mediump vec3 yuv, rgb;
    yuv.x = (texture(tex_y, texCoord).r);
    yuv.yz = (texture(tex_uv, texCoord).rb - vec2(0.5, 0.5));
    rgb = mat3( 1,       1,     1,
                0, -.18732, 1.8556,
                1.57481, -.46813, 0) * yuv;
    fragColor = vec4(rgb, 1);
}
)glsl";

@interface CallLayer()

@property BOOL currentFrameDisplayed;
@property NSLock* currentFrameLk;
@property CGFloat currentWidth;
@property CGFloat currentHeight;
@property CVPixelBufferRef currentFrame;

@end

@implementation CallLayer

// OpenGL handlers
GLuint textureY, textureUV, textureUniformY, textureUniformUV, vbo, vShader, fShader, sProg, vao;

@synthesize currentFrameDisplayed, currentFrameLk, currentWidth, currentHeight, currentFrame;

- (id) init
{
    self = [super init];
    if (self) {
        currentFrameLk = [[NSLock alloc] init];
        [self setVideoRunning:NO];
    }
    return self;
}

// This setter is redefined so we can initialize the OpenGL context when this one is
// setup by the UI (which seems to be done just before the first draw attempt and not in init method);
- (void)setOpenGLContext:(NSOpenGLContext *)openGLContext
{
    [super setOpenGLContext:openGLContext];

    if (openGLContext) {
        GLfloat vertices[] = {
            -1.0, 1.0, 0.0, 0.0,   // Top-left
            1.0, 1.0, 1.0, 0.0,    // Top-right
            -1.0, -1.0, 0.0, 1.0,  // Bottom-left
            1.0, -1.0, 1.0, 1.0    // Bottom-right
        };

        [openGLContext makeCurrentContext];

        // VAO
        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);

        // VBO
        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

        // Vertex shader
        vShader = glCreateShader(GL_VERTEX_SHADER);
        glShaderSource(vShader, 1, &vShaderSrc, NULL);
        glCompileShader(vShader);

        // Fragment shader
        fShader = glCreateShader(GL_FRAGMENT_SHADER);
        glShaderSource(fShader, 1, &fShaderSrc, NULL);
        glCompileShader(fShader);

        // Program
        sProg = glCreateProgram();
        glAttachShader(sProg, vShader);
        glAttachShader(sProg, fShader);
        glBindFragDataLocation(sProg, 0, "fragColor");
        glLinkProgram(sProg);
        glUseProgram(sProg);

        textureUniformY = glGetUniformLocation(sProg, "tex_y");
        textureUniformUV = glGetUniformLocation(sProg, "tex_uv");
        
        GLint params = -1;
        GLchar ErrorLog[512] = { 0 };
        GLint size = 0;
        glGetProgramiv(sProg, GL_INFO_LOG_LENGTH, &params);
        if(params > 0)
        {
            glGetProgramInfoLog(sProg, 512, &size, ErrorLog);
            fprintf(stderr, "Prog Info Log: %s\n", ErrorLog);
            //glGetProgramInfoLog(sProg, logLen, &logLen, log);
            // Show any errors as appropriatetextureUniformUV == GL_INVALID_INDEX){
            NSLog(@"textureUniformUV error");
        }

        // Vertices position attrib
        GLuint inPosAttrib = glGetAttribLocation(sProg, "in_Pos");
        glEnableVertexAttribArray(inPosAttrib);
        glVertexAttribPointer(inPosAttrib, 2, GL_FLOAT, GL_FALSE, 4*sizeof(GLfloat), 0);

        // Texture position attrib
        GLuint inTexCoordAttrib = glGetAttribLocation(sProg, "in_TexCoord");
        glEnableVertexAttribArray(inTexCoordAttrib);
        glVertexAttribPointer(inTexCoordAttrib, 2, GL_FLOAT, GL_FALSE, 4*sizeof(GLfloat), (void*)(2*sizeof(GLfloat)));
        // Texturey
        glActiveTexture(GL_TEXTURE0);
        glGenTextures(1, &textureY);
        glBindTexture(GL_TEXTURE_2D, textureY);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
        
        // TextureUV
        glActiveTexture(GL_TEXTURE1);
        glGenTextures(1, &textureUV);
        glBindTexture(GL_TEXTURE_2D, textureUV);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    }
}

- (NSOpenGLPixelFormat *)openGLPixelFormatForDisplayMask:(uint32_t)mask
{
    NSOpenGLPixelFormatAttribute attrs[] = {
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAScreenMask,
        mask,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion3_2Core,
        0
    };

    NSOpenGLPixelFormat* pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

    return pixelFormat;
}

- (BOOL)isAsynchronous
{
    return YES;
}

- (void)drawInOpenGLContext:(NSOpenGLContext *)context pixelFormat:(NSOpenGLPixelFormat *)pixelFormat forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    if(!currentFrame) {
        return;
    }
        
    GLenum errEnum;

    [currentFrameLk lock];
    if(!currentFrameDisplayed) {
        CVPixelBufferLockBaseAddress(currentFrame, 0);
        uint8_t* yplane = static_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(currentFrame, 0));
        uint8_t* uvplane = static_cast<uint8_t*>(CVPixelBufferGetBaseAddressOfPlane(currentFrame, 1));
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, textureY);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, currentWidth, currentHeight, 0, GL_RED, GL_UNSIGNED_BYTE, yplane);
        glUniform1i(textureUniformY, 0);
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, textureUV);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, currentWidth, currentHeight * 0.5, 0, GL_RED, GL_UNSIGNED_BYTE, uvplane);
        glUniform1i(textureUniformUV, 1);
        CVPixelBufferUnlockBaseAddress(currentFrame, 0);

        currentFrameDisplayed = YES;
    }
    // To ensure that we will not divide by zero
    if (currentWidth && currentHeight) {
        // Compute scaling factor to keep the original aspect ratio of the video
        CGSize viewSize = self.frame.size;
         if (viewSize.width > 200)  {
        auto len = viewSize.width/viewSize.height;
             }
        float viewRatio = viewSize.width/viewSize.height;
        float frameRatio = ((float)currentWidth)/((float)currentHeight);
        float ratio = viewRatio * (1/frameRatio);

        GLint inScalingUniform = glGetUniformLocation(sProg, "in_Scaling");

        float multiplier = MAX(frameRatio, ratio);
        if((viewRatio >= 1 && frameRatio >= 1) ||
           (viewRatio < 1 && frameRatio < 1) ||
           (ratio > 0.5 && ratio < 1.5) ) {
            if (ratio > 1.0)
                glUniform2f(inScalingUniform, 1.0, 1.0 * ratio);
            else
                glUniform2f(inScalingUniform, 1.0/ratio, 1.0);
        } else {
            if (ratio < 1.0)
                glUniform2f(inScalingUniform, 1.0, 1.0 * ratio);
            else
                glUniform2f(inScalingUniform, 1.0/ratio, 1.0);

        }
    }

    glFlush();
    [currentFrameLk unlock];

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    if([self videoRunning])
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void) setCurrentFrame:(lrc::api::video::Frame)framePtr
{

}

-(void)renderWithPixelBuffer:(CVPixelBufferRef)buffer size:(CGSize)size rotation: (float)rotation fillFrame: (bool)fill {
    [currentFrameLk lock];
    currentFrame = buffer;
    currentWidth = size.width;
    currentHeight = size.height;
    currentFrameDisplayed = NO;
    [currentFrameLk unlock];
}

-(void)renderAVFrame:(std::unique_ptr<AVFrame, void(*)(AVFrame*)>)buffer
{
//    [currentFrameLk lock];
//    auto ptr = buffer.get();
//    if(ptr) {
//        currentFrame = buffer.get();
//        ptrY = currentFrame->data[0];
//        ptrUV = currentFrame->data[1];
//    }
//    currentFrameDisplayed = NO;
//    [currentFrameLk unlock];
}

@end

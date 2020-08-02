//
//  KKView.m
//  OpenGL_ES_CustomShader
//
//  Created by China on 2020/7/30.
//  Copyright © 2020 China. All rights reserved.
//
#import <OpenGLES/ES2/gl.h>
#import "KKView.h"

@interface KKView ()
@property (nonatomic, strong) CAEAGLLayer * myEaglayer;
@property (nonatomic, strong) EAGLContext * myContext;

@property (nonatomic, assign) GLuint myRenderBuffer;
@property (nonatomic, assign) GLuint myFrameBuffer;

@property (nonatomic, assign) GLuint myPrograme;
@end


/*
不采样GLKBaseEffect，使用编译链接自定义的着色器（shader）。用简单的glsl语言来实现顶点、片元着色器，并图形进行简单的变换。
思路：
  1.创建图层
  2.创建上下文
  3.清空缓存区
  4.设置RenderBuffer
  5.设置FrameBuffer
  6.开始绘制

*/

@implementation KKView
- (void)layoutSubviews{
    [self creatLayer];
    [self creatContext];
    [self clearRenderBufferAndFrameBuffer];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self renderLayer];
}

// 开始绘制

- (void)renderLayer{
    glClearColor(0.3f, 0.45f, 0.5f, 1.0f);
    
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
    
    // 读取顶点着色器
    NSString * vertPath = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    NSString * fragPath = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
    NSLog(@"%@ ---- %@", vertPath, fragPath);
    
    self.myPrograme = [self loadShadersWithVertShaderPath:vertPath fragementShaderPath:fragPath];
    
    glLinkProgram(self.myPrograme);
    
    GLint linkStatus;
    
    // 获取link状态
    glGetProgramiv(self.myPrograme, GL_LINK_STATUS, &linkStatus);
    
    // 获取错误信息
    if (linkStatus == GL_FALSE) {
        GLchar errorInfo[512];
        glGetProgramInfoLog(self.myPrograme, sizeof(errorInfo), 0, &errorInfo[0]);
        
        NSString * message = [NSString stringWithUTF8String:errorInfo];
        
        NSLog(@"Program Link ERROR : %@", message);
        return;
    }
    
    NSLog(@"Program Link SUCCESS");
    
    //使用program
    glUseProgram(self.myPrograme);
    
    
    //6.设置顶点、纹理坐标
    //前3个是顶点坐标，后2个是纹理坐标
    GLfloat attrArr[] =
    {
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        -0.5f, -0.5f, -1.0f,    0.0f, 0.0f,
        
        0.5f, 0.5f, -1.0f,      1.0f, 1.0f,
        -0.5f, 0.5f, -1.0f,     0.0f, 1.0f,
        0.5f, -0.5f, -1.0f,     1.0f, 0.0f,
    };

    /// 处理顶点数据
    GLuint attrBuffer;
    //申请一个缓存区标志
    glGenBuffers(1, &attrBuffer);
    //attrBuffer绑定到GL_ARRAY_BUFFER标识符上
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    //把顶点数据从CPU内存中复制到GPU上
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    //将顶点数据通过program传递给顶点着色器中
    GLuint position = glGetAttribLocation(self.myPrograme, "position");
    //设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(position);
    
    //设置读取方式
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 0);
    
    /// 处理纹理数据
    GLuint textCoor = glGetAttribLocation(self.myPrograme, "textCoordinate");
    //设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(textCoor);
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT) * 5, (GLfloat *)NULL + 3);
    
    //设置加载纹理
    [self loadTexture:@"kunkun"];
    
    //11. 设置纹理采样器 sampler2D
    glUniform1i(glGetUniformLocation(self.myPrograme, "colorMap"), 0);
       
    //12.绘图
    glDrawArrays(GL_TRIANGLES, 0, 6);
       
    //13.从渲染缓存区显示到屏幕上
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}
- (GLuint )loadTexture:(NSString *)textureName{
    // 将UIImage转化成CGImageRef
    CGImageRef spriteImage = [UIImage imageNamed:textureName].CGImage;
    
    //判断图片是否获取成功
    
    if (!spriteImage) {
        NSLog(@"Get Image Failure");
        exit(1);
    }
    
    size_t with = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    //获取图片字节数
    GLubyte * spriteByte = (GLubyte *)(calloc(with * height * 4, sizeof(GLubyte)));
    
    // 创建上下文
    /*
        参数1：data,指向要渲染的绘制图像的内存地址
        参数2：width,bitmap的宽度，单位为像素
        参数3：height,bitmap的高度，单位为像素
        参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
        参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
        参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
        */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteByte, with, height, 8, with*4,CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    //在CGContextRef上--> 将图片绘制出来
    /*
     CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
     CGContextDrawImage
     参数1：绘图上下文
     参数2：rect坐标
     参数3：绘制的图片
     */
    CGRect rect = CGRectMake(0, 0, with, height);
    
    //使用默认方式绘制
    
    CGContextDrawImage(spriteContext, rect, spriteImage);
    
    //释放上下文
    CGContextRelease(spriteContext);
    
    // 绑定纹理到默认ID
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //设置纹理属性
    /*
     参数1：纹理维度
     参数2：线性过滤、为s,t坐标设置模式
     参数3：wrapMode,环绕模式
     */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    CGFloat fw = with, fh = height;
    
    //10.载入纹理2D数据
    /*
     参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
     参数2：加载的层次，一般设置为0
     参数3：纹理的颜色值GL_RGBA
     参数4：宽
     参数5：高
     参数6：border，边界宽度
     参数7：format
     参数8：type
     参数9：纹理数据
     */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteByte);
    
    free(spriteByte);
    
    return 0;
}
// 设置FrameBuffer
- (void)setupFrameBuffer{
    // 定义一个ID
    GLuint buffer;
    
    //申请一个缓存区标志
    glGenFramebuffers(1, &buffer);
    
    self.myFrameBuffer = buffer;
    
    glBindBuffer(GL_FRAMEBUFFER, self.myFrameBuffer);
    
    //生成帧缓存区之后，则需要将renderbuffer跟framebuffer进行绑定，
    //5.将渲染缓存区myColorRenderBuffer 通过glFramebufferRenderbuffer函数绑定到 GL_COLOR_ATTACHMENT0上。
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myFrameBuffer);
    
}

// 设置renderBuffer
- (void)setupRenderBuffer{
    // 定义一个ID
    GLuint buffer;
    
    // 申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    
    self.myRenderBuffer = buffer;
    
    //将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myRenderBuffer);
    
    //将可绘制对象(drawable object's)  CAEAGLLayer的存储绑定到OpenGL ES renderBuffer对象
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEaglayer];
}

// 清空缓存区
- (void)clearRenderBufferAndFrameBuffer{
    /*
        buffer分为frame buffer 和 render buffer2个大类。
        其中frame buffer 相当于render buffer的管理者。
        frame buffer object即称FBO。
        render buffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。
        */
    glDeleteBuffers(1, &_myRenderBuffer);
    self.myRenderBuffer = 0;
    
    glDeleteBuffers(1, &_myFrameBuffer);
    self.myFrameBuffer = 0;
    
}

//创建上下文
- (void)creatContext{
    //制定OpenGL ES 渲染API的版本
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    
    //创建上下文
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:api];
    
    // 判断是否创建成功
    if (!context) {
        NSLog(@"Creat Context failure");
        return;
    }
    
    //设置上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Set CurrentContext Failure");
        return;
    }
    
    //全局换context
    self.myContext = context;
}
//创建图层
- (void)creatLayer{
    // 创建特殊图层
    /*
        重写layerClass
     */
    self.myEaglayer = (CAEAGLLayer *)self.layer;
    
    // 设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    
    // 设置描述属性
    /*
    kEAGLDrawablePropertyRetainedBacking  表示绘图表面显示后，是否保留其内容。
    kEAGLDrawablePropertyColorFormat
        可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
    
        kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
        kEAGLColorFormatRGB565：16位RGB的颜色，
        kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。


    */
    self.myEaglayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false, kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
}
+ (Class)layerClass{
    return [CAEAGLLayer class];
}

#pragma mark — shader初始化
- (GLuint)loadShadersWithVertShaderPath:(NSString *)vertShaderPath fragementShaderPath:(NSString *)fragementShaderPath{
    // 定义两个零时着色器
    GLuint vertShader, fragementShader;
    //创建programe
    GLuint pragment = glCreateProgram();
    
    //编译顶点着色器，片元着色器
    [self compileShader:&vertShader type:GL_VERTEX_SHADER filePath:vertShaderPath];
    [self compileShader:&fragementShader type:GL_FRAGMENT_SHADER filePath:fragementShaderPath];
    
    //创建最终程序
    
    glAttachShader(pragment, vertShader);
    glAttachShader(pragment, fragementShader);
    
    //释放不再需要的shader
    glDeleteShader(vertShader);
    glDeleteShader(fragementShader);
    
    return pragment;
}

// 指针，传的shader是一个指针
- (void)compileShader:(GLuint *)shader type:(GLenum )type filePath:(NSString *)path{
    // 读取文件路径
    NSString * content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    const GLchar * source = (GLchar *)[content UTF8String];
    
    // 创建shader
    *shader = glCreateShader(type);
    /**
     <#GLuint shader#> 要编译的着色器对象
     <#GLsizei count#> 传递源码字符串数量
     <#const GLchar *const *string#> 着色器程序源码
     <#const GLint *length#> 长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
     
     */
    
    glShaderSource(*shader, 1, &source, NULL);
    
    //把着色器代码，编译成目标代码
    glCompileShader(*shader);
    
}

@end

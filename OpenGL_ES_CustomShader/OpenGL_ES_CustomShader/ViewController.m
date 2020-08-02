//
//  ViewController.m
//  OpenGL_ES_CustomShader
//
//  Created by China on 2020/7/31.
//  Copyright © 2020 China. All rights reserved.
//

#import "ViewController.h"
#import "CCView.h"
#import "KKView.h"

@interface ViewController ()
@property (nonatomic, strong) CCView * myView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _myView = [[CCView alloc] init];
    self.view = _myView;
//    self.myView = (CCView *)self.view;
    // Do any additional setup after loading the view.
}


@end

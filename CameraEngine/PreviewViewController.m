//
//  PreviewViewController.m
//  CameraEngine
//
//  Created by Remi Robert on 19/08/15.
//  Copyright (c) 2015 Remi Robert. All rights reserved.
//

#import "PreviewViewController.h"

@interface PreviewViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *preview;

@end

@implementation PreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.image) {
        self.preview.contentMode = UIViewContentModeScaleAspectFit;
        self.preview.image = self.image;
    }
    else if (self.videoUrl) {
        
    }
}

@end

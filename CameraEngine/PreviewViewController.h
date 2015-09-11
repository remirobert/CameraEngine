//
//  PreviewViewController.h
//  CameraEngine
//
//  Created by Remi Robert on 19/08/15.
//  Copyright (c) 2015 Remi Robert. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreviewViewController : UIViewController
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *videoUrl;
@end

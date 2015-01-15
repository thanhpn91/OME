//
//  ViewController.h
//  OME
//
//  Created by Thanh Pham on 1/7/15.
//  Copyright (c) 2015 Officience. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (strong, nonatomic) NSArray *images;
@property (strong, nonatomic) IBOutlet UIView *frameView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView1;
@property (strong, nonatomic) IBOutlet UIImageView *imageView2;
@property (strong, nonatomic) IBOutlet UIImageView *imageView3;
@property (strong, nonatomic) IBOutlet UIImageView *imageView4;
-(UIImage *)cropImageToSquare:(UIImage *)image scaledToSize:(CGSize)newSize;
- (IBAction)takePhoto:(id)sender;
- (IBAction)loadFromGallery:(id)sender;
- (IBAction)btnFlashOnClicked:(id)sender;
- (IBAction)btnCameraChanged:(id)sender;
- (IBAction)btnGridShowup:(id)sender;
@end



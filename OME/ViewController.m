//
//  ViewController.m
//  OME

//  Created by Thanh Pham on 1/7/15.
//  Copyright (c) 2015 Officience. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Parse/Parse.h>
#import "PPImageScrollingTableViewCell.h"
@interface ViewController ()

@end

@implementation ViewController
AVCaptureSession *session;
AVCaptureStillImageOutput *stillImageOutput;
CGRect frame;

- (void)viewDidLoad {
    [super viewDidLoad];
    static NSString *CellIdentifier = @"Cell";
//    [self.tableView registerClass:[PPImageScrollingTableViewCell class] forCellReuseIdentifier:CellIdentifier];
//    self.images = @[
//                        @{
//                            @"images":
//                                @[
//                                    @{ @"name":@"sample_1", @"title":@"A-0"},
//                                    @{ @"name":@"sample_2", @"title":@"A-1"},
//                                    @{ @"name":@"sample_3", @"title":@"A-2"},
//                                    @{ @"name":@"sample_4", @"title":@"A-3"},
//                                    @{ @"name":@"sample_5", @"title":@"A-4"},
//                                    @{ @"name":@"sample_6", @"title":@"A-5"}
//                                ]
//                        }
//                    ];
    
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)viewWillAppear:(BOOL)animated{
    session = [[AVCaptureSession alloc] init];
    [session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    // initial Capture Device
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    
    if([session canAddInput:deviceInput]){
        [session addInput:deviceInput];
    }
    
    // initial Capture Layer    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    
    frame = CGRectMake(0, 20, 380, 380); 
    //self.frameView.frame;
    [previewLayer setFrame:frame];
    [rootLayer insertSublayer:previewLayer atIndex:0];
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG , AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
    
    [session addOutput:stillImageOutput];
    [session startRunning];
    
    [self retrieveFromParse];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (UIImage *)cropImageToSquare:(UIImage *)image scaledToSize:(CGSize)newSize{
    double ratio;
    double delta;
    CGPoint offset;
    CGSize imageSIze = image.size;
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.width);
    
    //figure out if the picture is landscape or portrait, then
    //calculate scale factor and offset
    if (image.size.width > image.size.height) {
        ratio = newSize.width / image.size.width;
        delta = (ratio*image.size.width - ratio*image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize.width / image.size.height;
        delta = (ratio*image.size.height - ratio*image.size.width);
        offset = CGPointMake(0, delta/2);
    }
    
    //make the final clipping rect based on the calculated values
    CGRect clipRect = CGRectMake(-offset.x, -offset.y - 20,
                                 (ratio * image.size.width) + delta,
                                 (ratio * image.size.height + delta + 40));
    
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (IBAction)takePhoto:(id)sender {
    AVCaptureConnection *videoConnection = nil;
    
    for (AVCaptureConnection *connection in stillImageOutput.connections){
        for(AVCaptureInputPort *port in [connection inputPorts]){
            if([[port mediaType] isEqual:AVMediaTypeVideo]){
                videoConnection = connection;
                break;
            }
        }
        if(videoConnection){
            break;
        }
    }
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if(imageDataSampleBuffer != NULL){
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
           // UIImage *image = [UIImage imageWithData:imageData];
            UIImage *image =[self cropImageToSquare:[UIImage imageWithData:imageData] scaledToSize:CGSizeMake(640, 640)];
            self.imageView1.image = image;
            self.imageView2.image = image;
            self.imageView3.image = image;
            self.imageView4.image = image;
        }
    }];
}

- (IBAction)btnFlashOnClicked:(id)sender {
    AVCaptureDevice *flashLight = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([flashLight isTorchAvailable] && [flashLight isTorchModeSupported:AVCaptureTorchModeOn])
    {
        BOOL success = [flashLight lockForConfiguration:nil];
        if (success)
        {
            if ([flashLight isTorchActive])
            {
                //[btnFlash setTitle:@"TURN ON" forState:UIControlStateNormal];
                [flashLight setTorchMode:AVCaptureTorchModeOff];
            }
            else
            {
                //[btnFlash setTitle:@"TURN OFF" forState:UIControlStateNormal];
                [flashLight setTorchMode:AVCaptureTorchModeOn];
            }
            [flashLight unlockForConfiguration];
        }
    }
}

- (IBAction)btnCameraChanged:(id)sender {
    //Change camera source
    if(session)
    {
        //Indicate that some changes will be made to the session
        [session beginConfiguration];
        
        //Remove existing input
        AVCaptureInput* currentCameraInput = [session.inputs objectAtIndex:0];
        [session removeInput:currentCameraInput];
        
        //Get new input
        AVCaptureDevice *newCamera = nil;
        if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack)
        {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        }
        else
        {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }
        
        //Add input to session
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:nil];
        [session addInput:newVideoInput];
        
        //Commit all the configuration changes at once
        [session commitConfiguration];
    }
}
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) 
    {
        if ([device position] == position) return device;
    }
    return nil;
}

- (IBAction)btnGridShowup:(id)sender {
}
-(void)retrieveFromParse {
    PFQuery *retriveImage = [PFQuery queryWithClassName:@"Frame"];
    [retriveImage findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"Retrieved data");
        if(!error){
            NSLog(@"%@", objects);
            
            //[allObjects addObjectsFromArray:objects];
           // PFFile *file = [object objectForKey:@"Frame_image"];
//            if(file != NULL){
//                [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
//                    UIImage *image = [UIImage imageWithData:data];
//                    UIImageView *imageView = [[UIImageView alloc ] initWithImage:image];
//                    self.imageView1.image = imageView.image;
//                }];
//            }
        }
    }];
    
}
// Fix auto-rotation to portrait
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}
-(BOOL)shouldAutorotate {
    return YES;
}
- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


- (IBAction)loadFromGallery:(id)sender {
}
@end

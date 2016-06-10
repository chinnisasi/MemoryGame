//
//  ViewController.m
//  MemoryGame
//
//  Created by Sasidhar Koti on 10/06/16.
//  Copyright © 2016 Sasidhar Koti. All rights reserved.
//

#import "ViewController.h"
#import "MNImageCollectionCell.h"
#import "UIImageView+WebCache.h"
#import "MBProgressHUD.h"
#import "AFHTTPRequestOperationManager.h"

@interface ViewController ()
@property (nonatomic, strong) NSArray * imagesArr;
@property (nonatomic, strong) NSTimer * timer;
@property (nonatomic, assign) NSUInteger counter;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) UIImage* imageToGuess;



@property (weak, nonatomic) IBOutlet UILabel *counterLbl;

@property (weak, nonatomic) IBOutlet UIImageView *guessImgView;
@property (weak, nonatomic) IBOutlet UICollectionView *imgGridView;
@property (weak, nonatomic) IBOutlet UILabel *guessLbl;

@property (weak, nonatomic) IBOutlet UIButton *retryBtn;

@end

@implementation ViewController {
    NSInteger randomNumber;
    NSUInteger isPlayStarted;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    isPlayStarted = NO;
    

    [self showLoadingIndicatorWithText:@"Loading..."];
    self.retryBtn.hidden = YES;
    [self startGame];
   
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)startGame
{
    randomNumber = arc4random() % 9;
    self.counter = 0;
    if ([self.timer isValid]){
        [self.timer invalidate];
        self.timer = nil;
    }
    self.timer = nil;
    self.counter = 0;
    self.guessLbl.hidden = YES;
    self.counterLbl.hidden = YES;
    self.imgGridView.hidden = YES;
    self.guessImgView.hidden = YES;
    [self getFlickrImages];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateImagesArrModel:(NSArray*)photoDataArray
{
    self.counter = 0;
    self.imagesArr = [[photoDataArray valueForKeyPath:@"media.m"] subarrayWithRange:NSMakeRange(0, 9)];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateCountDown) userInfo:nil repeats:YES];
    self.imgGridView.hidden = NO;
    [self.imgGridView reloadData];
    [self hideLoadingIndicator];
}

- (void)updateCountDown
{
    self.counterLbl.hidden = NO;
    self.counter = self.counter + 1;
    [self.counterLbl setHidden:NO];
    self.counterLbl.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.counter];
    if (self.counter == 15) {
        isPlayStarted = YES;
        self.guessLbl.hidden = NO;
        [self.counterLbl setHidden:YES];
        [self.guessImgView setHidden:NO];
        NSString * imageURLStr = [self.imagesArr objectAtIndex:randomNumber];
        self.guessImgView.hidden = NO;
         __weak __typeof__(self) weakSelf = self;
        [self.guessImgView sd_setImageWithURL:[NSURL URLWithString:imageURLStr]
                             placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                 __typeof__(self) strongSelf = weakSelf;
                                 if(error == nil) {
                                     strongSelf.imageToGuess = image;
                                 }
                             }];
        
        
        [self.imgGridView reloadData];
        [self.timer invalidate];
        self.timer = nil;
        self.counter = 0;
    }
}

- (void) reloadFlickrRequest{
    
    [self getFlickrImages];
}

- (void) getFlickrImages{
    
     __weak __typeof__(self) weakSelf = self;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager GET:@"https://api.flickr.com/services/feeds/photos_public.gne?format=json" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        __typeof__(self) strongSelf = weakSelf;
        NSError *parserError;
        NSData *refinedData = [responseObject subdataWithRange:NSMakeRange([@"jsonFlickrFeed(" length], [responseObject length]-([@"jsonFlickrFeed(" length]+1))];

        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:refinedData options:0 error:&parserError];
         NSArray * photoDataArray = [responseDict valueForKey:@"items"];
         dispatch_async(dispatch_get_main_queue(), ^{
             if([photoDataArray count]) {
                 [strongSelf updateImagesArrModel:photoDataArray];
             } else {
                 if (parserError != nil) {
                     [self reloadFlickrRequest];
                     return;
                 }
             }
         });
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self hideLoadingIndicator];
        dispatch_async(dispatch_get_main_queue(), ^{
            __typeof__(self) strongSelf = weakSelf;
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Error"
                                                  message:[error localizedDescription]
                                                  preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:@"OK"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                       }];
            [alertController addAction:okAction];
            [strongSelf presentViewController:alertController animated:YES completion:nil];
            
        });
    }];
}



#pragma mark - CollectionView Delegate & Data Source


- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    return [self.imagesArr count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    MNImageCollectionCell * imageCell = [collectionView
                                         dequeueReusableCellWithReuseIdentifier:@"imageCellIdentifier"
                                         forIndexPath:indexPath];
    
    imageCell.layer.borderColor = [UIColor lightGrayColor].CGColor;
    imageCell.layer.borderWidth = 0.5;
    NSString * imageURLStr = [self.imagesArr objectAtIndex:indexPath.row];
    [imageCell.imgView sd_setImageWithURL:[NSURL URLWithString:imageURLStr]
                         placeholderImage:nil];

    imageCell.backgroundView = [[UIView alloc] initWithFrame:imageCell.bounds];
    imageCell.backgroundColor = [UIColor grayColor];
    [imageCell addSubview:imageCell.backgroundView ];
    
    if (isPlayStarted) {
        imageCell.backGroundView.hidden = NO;
        imageCell.imgView.hidden = YES;
    } else {
        imageCell.backGroundView.hidden = YES;
        imageCell.imgView.hidden = NO;
       
    }
    return imageCell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    MNImageCollectionCell * imageCell = (MNImageCollectionCell *)[collectionView cellForItemAtIndexPath:indexPath];
    if (isPlayStarted) {
        
        imageCell.imgView.hidden = NO;
    
        
        [UIView transitionWithView: imageCell.contentView
                          duration:2
                           options:UIViewAnimationOptionTransitionFlipFromRight
                        animations:^{
                            imageCell.backgroundView.hidden = YES;
                           
                        } completion:nil];


    if ([imageCell.imgView.image isEqual:self.imageToGuess]) {
        
          __weak __typeof__(self) weakSelf = self;
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Success"
                                              message:@"You guess is successful!"
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:@"OK"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action)
                                   {
                                       __typeof__(self) strongSelf = weakSelf;
                                      strongSelf.retryBtn.hidden = NO;
                                      isPlayStarted = NO;
                                       strongSelf.imageToGuess = nil;
                                       [strongSelf.imgGridView reloadData];
                                   }];
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
           }
    }
    
}



#pragma mark- Loading Indicators (Show/Hide)

- (void)showLoadingIndicatorWithText:(NSString *)text {
    
   self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.HUD.labelText = @"Loading Game!";
}

- (void)hideLoadingIndicator {
    
   [MBProgressHUD hideHUDForView:self.view animated:YES];
}


- (IBAction)play:(id)sender {
    [self showLoadingIndicatorWithText:@"Loading..."];
    [self startGame];
}



@end

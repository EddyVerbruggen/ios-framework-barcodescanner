#import "QRCodeReaderViewController.h"
#import "QRCameraSwitchButton.h"
#import "QRCodeReaderView.h"

@interface QRCodeReaderViewController ()
@property (strong, nonatomic) QRCameraSwitchButton *switchCameraButton;
@property (strong, nonatomic) QRCodeReaderView     *cameraView;
@property (strong, nonatomic) UIButton             *cancelButton;
@property (strong, nonatomic) QRCodeReader         *codeReader;
@property (assign, nonatomic) BOOL                 startScanningAtLoad;

@property (copy, nonatomic) void (^completionBlock) (NSString * __nullable, NSString * __nullable);

@end

@implementation QRCodeReaderViewController

- (void)dealloc
{
  [self stopScanning];

  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
  return [self initWithCancelButtonTitle:nil];
}

- (id)initWithCancelButtonTitle:(NSString *)cancelTitle
{
  return [self initWithCancelButtonTitle:cancelTitle metadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
}

- (id)initWithMetadataObjectTypes:(NSArray *)metadataObjectTypes
{
  return [self initWithCancelButtonTitle:nil metadataObjectTypes:metadataObjectTypes];
}

- (id)initWithCancelButtonTitle:(NSString *)cancelTitle metadataObjectTypes:(NSArray *)metadataObjectTypes
{
  QRCodeReader *reader = [QRCodeReader readerWithMetadataObjectTypes:metadataObjectTypes];

  return [self initWithCancelButtonTitle:cancelTitle codeReader:reader];
}

- (id)initWithCancelButtonTitle:(NSString *)cancelTitle codeReader:(QRCodeReader *)codeReader
{
  return [self initWithCancelButtonTitle:cancelTitle codeReader:codeReader startScanningAtLoad:true];
}

- (id)initWithCancelButtonTitle:(NSString *)cancelTitle codeReader:(QRCodeReader *)codeReader startScanningAtLoad:(BOOL)startScanningAtLoad
{
  if ((self = [super init])) {
    self.view.backgroundColor = [UIColor blackColor];
    self.codeReader           = codeReader;
    self.startScanningAtLoad  = startScanningAtLoad;

    if (cancelTitle == nil) {
      cancelTitle = NSLocalizedString(@"Cancel", @"Cancel");
    }

    [self setupUIComponentsWithCancelButtonTitle:cancelTitle];
    [self setupAutoLayoutConstraints];

    [_cameraView.layer insertSublayer:_codeReader.previewLayer atIndex:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];

    //__weak typeof(self) weakSelf = self;

    [codeReader setCompletionWithBlock:^(NSString *resultAsString, NSString *typeAsString) {
      if (self.completionBlock != nil) {
        self.completionBlock(resultAsString, typeAsString);
      }

      if (self.delegate && [self.delegate respondsToSelector:@selector(reader:didScanResult:forType:)]) {
        [self.delegate reader:self didScanResult:resultAsString forType:(NSString *)typeAsString];
      }
    }];
  }
  return self;
}

+ (instancetype)readerWithCancelButtonTitle:(NSString *)cancelTitle
{
  return [[self alloc] initWithCancelButtonTitle:cancelTitle];
}

+ (instancetype)readerWithMetadataObjectTypes:(NSArray *)metadataObjectTypes
{
  return [[self alloc] initWithMetadataObjectTypes:metadataObjectTypes];
}

+ (instancetype)readerWithCancelButtonTitle:(NSString *)cancelTitle metadataObjectTypes:(NSArray *)metadataObjectTypes
{
  return [[self alloc] initWithCancelButtonTitle:cancelTitle metadataObjectTypes:metadataObjectTypes];
}

+ (instancetype)readerWithCancelButtonTitle:(NSString *)cancelTitle codeReader:(QRCodeReader *)codeReader
{
  return [[self alloc] initWithCancelButtonTitle:cancelTitle codeReader:codeReader];
}

+ (instancetype)readerWithCancelButtonTitle:(NSString *)cancelTitle codeReader:(QRCodeReader *)codeReader startScanningAtLoad:(BOOL)startScanningAtLoad
{
  return [[self alloc] initWithCancelButtonTitle:cancelTitle codeReader:codeReader startScanningAtLoad:startScanningAtLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  if (_startScanningAtLoad) {
    [self startScanning];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self stopScanning];

  [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];

  _codeReader.previewLayer.frame = self.view.bounds;
}

- (BOOL)shouldAutorotate
{
  return YES;
}

#pragma mark - Controlling the Reader

- (void)startScanning {
  [_codeReader startScanning];
}

- (void)stopScanning {
  [_codeReader stopScanning];
}

#pragma mark - Managing the Orientation

- (void)orientationChanged:(NSNotification *)notification
{
  [_cameraView setNeedsDisplay];

  if (_codeReader.previewLayer.connection.isVideoOrientationSupported) {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    _codeReader.previewLayer.connection.videoOrientation = [QRCodeReader videoOrientationFromInterfaceOrientation:
                                                            orientation];
  }
}

#pragma mark - Managing the Block

- (void)setCompletionWithBlock:(void (^) (NSString *resultAsString, NSString  *typeAsString))completionBlock
{
  self.completionBlock = completionBlock;
}

#pragma mark - Initializing the AV Components

- (void)setupUIComponentsWithCancelButtonTitle:(NSString *)cancelButtonTitle
{
  self.cameraView                                       = [[QRCodeReaderView alloc] init];
  _cameraView.translatesAutoresizingMaskIntoConstraints = NO;
  _cameraView.clipsToBounds                             = YES;
  [self.view addSubview:_cameraView];

  [_codeReader.previewLayer setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];

  if ([_codeReader.previewLayer.connection isVideoOrientationSupported]) {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    _codeReader.previewLayer.connection.videoOrientation = [QRCodeReader videoOrientationFromInterfaceOrientation:orientation];
  }

  if ([_codeReader hasFrontDevice]) {
    _switchCameraButton = [[QRCameraSwitchButton alloc] init];
    [_switchCameraButton setTranslatesAutoresizingMaskIntoConstraints:false];
    [_switchCameraButton addTarget:self action:@selector(switchCameraAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_switchCameraButton];
  }

  self.cancelButton                                       = [[UIButton alloc] init];
  _cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
  [_cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
  [_cancelButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
  [_cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:_cancelButton];
}

- (void)setupAutoLayoutConstraints
{
  NSDictionary *views = NSDictionaryOfVariableBindings(_cameraView, _cancelButton);

  [self.view addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_cameraView][_cancelButton(40)]|" options:0 metrics:nil views:views]];
  [self.view addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_cameraView]|" options:0 metrics:nil views:views]];
  [self.view addConstraints:
   [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_cancelButton]-|" options:0 metrics:nil views:views]];

  if (_switchCameraButton) {
    NSDictionary *switchViews = NSDictionaryOfVariableBindings(_switchCameraButton);

    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_switchCameraButton(50)]" options:0 metrics:nil views:switchViews]];
    [self.view addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_switchCameraButton(70)]|" options:0 metrics:nil views:switchViews]];
  }
}

- (void)switchDeviceInput
{
  [_codeReader switchDeviceInput];
}

#pragma mark - Catching Button Events

- (void)cancelAction:(UIButton *)button
{
  [_codeReader stopScanning];

  if (_completionBlock) {
    _completionBlock(nil, nil);
  }

  if (_delegate && [_delegate respondsToSelector:@selector(readerDidCancel:)]) {
    [_delegate readerDidCancel:self];
  } else {
  }
}

- (void)switchCameraAction:(UIButton *)button
{
  [self switchDeviceInput];
}

@end

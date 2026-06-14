//
// IapManager.m
// Version 1.1
// Created by lizi on 17/11/30.
//

#import "IapManager.h"
#import "NSData+Base64.h"
#import "NSString+SBJSON.h"
#import "JSON.h"
#import "ToolConfig.h"
#import "AdmobManager.h"

@implementation IapManager
- (id)init
{    
    if ((self = [super init])) {    
     
        //---------------------
        //----监听购买结果
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
        // 设置loading界面
        self.activityView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [self.activityView setBackgroundColor:[UIColor blackColor]];
        [self.activityView setAlpha:0.8];
        [[[UIApplication sharedApplication] keyWindow] addSubview:self.activityView];
//        [self.view addSubview:self.activityView];
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 32.0f, 32.0f)];
        [activityIndicator setCenter:self.activityView.center];
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        [self.activityView addSubview:activityIndicator];
        [activityIndicator setHidesWhenStopped:NO];
        [activityIndicator startAnimating];
        [activityIndicator release];
        [self.activityView release];
        [self.activityView setHidden:YES];
    }    
    return self;    
}    

- (void)buy:(int)productType
{
    if ([SKPaymentQueue canMakePayments]) {
        _buyType = productType;
        [self RequestProductData];
    }    
    else    
    {
        UIAlertView *alerView =  [[UIAlertView alloc] initWithTitle:@"注意"     
                                                            message:@"亲，你没允许应用程序内购买。"                                                            
                                                           delegate:nil cancelButtonTitle:NSLocalizedString(@"关闭",nil) otherButtonTitles:nil];    
        
        [alerView show];    
        [alerView release];    
        
    }     
}

// 请求商品
- (void)RequestProductData
{
    _productID = [NSString stringWithFormat:@"%@%d", kItemPrefix, _buyType];
    NSArray *product = [[NSArray alloc] initWithObjects:_productID, nil];
    
    NSSet *nsset = [NSSet setWithArray:product];    
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
    
    request.delegate = self;    
    [request start];
    
    [product release];
    [self.activityView setHidden:NO];
}

//收到产品信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{    
//    [self.activityView setHidden:YES];
    // NSLog(@"-----------productsRequest--------------");
    NSArray *myProduct = response.products;
    
    // 没有商品
    if ([myProduct count] == 0) return;
    
    SKProduct *selectPro = nil;
    for(SKProduct *product in myProduct){
        NSLog(@"描述信息 %@", product.description);
        NSLog(@"产品标题 %@", product.localizedTitle);
        NSLog(@"产品信息 %@", product.localizedDescription);
        NSLog(@"价格:   %@", product.price);
        NSLog(@"ProductID %@", product.productIdentifier);
        if ([product.productIdentifier isEqualToString:_productID]) {
            selectPro = product;
        }
    }
    SKPayment *payment = [SKPayment paymentWithProduct:selectPro];
    
    //NSLog(@"---------发送购买请求------------");
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

//请求失败
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
    NSLog(@"----------requestDidFail----------error=%@", error);
    NSString *viewTitle = @"无法连接到 iTunes Store";
    NSString *cancelTitle = @"确定";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:viewTitle message:nil delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}
//请求完成
- (void)requestDidFinish:(SKRequest *)request
{    
   NSLog(@"----------requestDidFinish--------------");
}    

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.activityView setHidden:YES];
    NSLog(@"tt------------------- %d", buttonIndex);
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions//交易结果
{
    for (SKPaymentTransaction *transaction in transactions)    
    {
        switch (transaction.transactionState)    
        {     
            case SKPaymentTransactionStatePurchased://交易完成 
                [self.activityView setHidden:YES];
                NSLog(@"-----交易完成 --------");
                [self completeTransaction:transaction];
                //if([self putStringToItunes:transaction.transactionReceipt]){
                    // 完成购买，回调刷新游戏数据
                    [[AdmobManager sharedInstance] purchaseSucc:_buyType];
                //}
                break;     
            case SKPaymentTransactionStateFailed://交易失败
                NSLog(@"-----交易失败 --------");
                [self.activityView setHidden:YES];
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored://已经购买过该商品
                NSLog(@"-----已经购买过该商品 --------");
                [self.activityView setHidden:YES];
                [self restoreTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing://商品添加进列表
                NSLog(@"-----商品添加进列表 --------");
                break;    
            default:
                break;    
        }    
    }    
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    NSLog(@"error = %@, code = %li", transaction.error, (long)transaction.error.code);
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    NSString *viewTitle = @"无法连接到 iTunes Store";
    NSString *cancelTitle = @"确定";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:viewTitle message:nil delegate:self cancelButtonTitle:cancelTitle otherButtonTitles:nil];
    [alertView show];
    [alertView release];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    // 恢复已经完成的所有交易.（仅限永久有效商品）
    //[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

//用户购成功的transactionReceipt验证
-(BOOL)putStringToItunes:(NSData*)iapData{
    [self.activityView setHidden:NO];
    NSString*encodingStr = [iapData base64EncodedString];
    
    NSString *utf8Strs = [[NSString alloc] initWithData:iapData encoding:NSUTF8StringEncoding];
    NSString *environment = [self environmentForReceipt:utf8Strs];
    
    NSString *verifyURL = @"https://buy.itunes.apple.com/verifyReceipt";
    if ([environment isEqualToString:@"environment=Sandbox"]) {
        verifyURL = @"https://sandbox.itunes.apple.com/verifyReceipt";
    }
    NSLog(@"verifyURL = %@", verifyURL);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:verifyURL]];
    [request setHTTPMethod:@"POST"];
    //设置contentType
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //设置Content-Length
    int length = (int)[encodingStr length];
    [request setValue:[NSString stringWithFormat:@"%d", length] forHTTPHeaderField:@"Content-Length"];
    
    NSDictionary* body = [NSDictionary dictionaryWithObjectsAndKeys:encodingStr, @"receipt-data", nil];
    SBJsonWriter *writer = [SBJsonWriter new];
    [request setHTTPBody:[[writer stringWithObject:body] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
    NSHTTPURLResponse *urlResponse=nil;
    NSError *errorr=nil;
    NSData *receivedData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&urlResponse
                                                             error:&errorr];
    
    //解析
    NSString *results=[[NSString alloc]initWithBytes:[receivedData bytes] length:[receivedData length] encoding:NSUTF8StringEncoding];
    //NSLog(@"-results-  %@",results);
    NSDictionary*dic = [results JSONValue];
    [self.activityView setHidden:YES];
    if([[dic objectForKey:@"status"] intValue]==0){//注意，status=@"0" 是验证收据成功
        return true;
    } else {
        
    }
    return false;
}

//收据的环境判断；
-(NSString * )environmentForReceipt:(NSString * )string
{
    string = [string stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    NSArray * array = [string componentsSeparatedByString:@";"];
    
    //存储收据环境的变量
    NSString * environment = array[2];
    return environment;
}

-(void)dealloc    
{
    //解除监听
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    
    [super dealloc];    
}     

@end


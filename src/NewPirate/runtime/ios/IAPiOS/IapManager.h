//
// IapManager.h
// Version 1.1
// Created by lizi on 17/11/30.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol IAPFinishDelegate
@required
-(void) finishBuy:(int)buyType;
@end

@interface IapManager : NSObject<SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate>
{
    int _buyType;
    NSString *_productID;
    id<IAPFinishDelegate> delegate;
}
@property (nonatomic, strong) UIView *activityView;

-(void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;
-(BOOL) putStringToItunes:(NSData*)iapData;
-(void) RequestProductData;
-(void) buy:(int)productType;
-(void) completeTransaction:(SKPaymentTransaction *)transaction;
-(void) failedTransaction:(SKPaymentTransaction *)transaction;
-(void) restoreTransaction: (SKPaymentTransaction *)transaction;
@end
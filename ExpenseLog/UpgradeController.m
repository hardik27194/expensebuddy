/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "UpgradeController.h"
#import "ExpenseModel.h"
#import "Defaults.h"
#import "Utils.h"
#import "ProductItemCell.h"
#import <StoreKit/StoreKit.h>

@interface UpgradeController () <UITableViewDataSource, UITableViewDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

@implementation UpgradeController {
    SKProductsRequest *_productsReq;
    NSArray *_iapProducts;
    BOOL _buyInProgress;
}

-(instancetype)init {
    self = [super init];

    [self resetTransactionObserver];
    return self;
}

-(void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

-(void)resetTransactionObserver {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.navigationItem) {
        UIBarButtonItem *bbiRestore = [[UIBarButtonItem alloc] initWithTitle:@"Restore Purchases" style:UIBarButtonItemStylePlain target:self action:@selector(restoreProducts)];
        self.navigationItem.rightBarButtonItem = bbiRestore;
    }
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(requestProducts) forControlEvents:UIControlEventValueChanged];
    
    [self resetTransactionObserver];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([SKPaymentQueue canMakePayments]) {
        _iapProducts = nil;
        [self requestProducts];
    } else {
        [Utils showModalDialogWithTitle:@"Not Available" message:@"Additional products are not available at this time."];
    }
}

-(void)restoreProducts {
    [Utils showTableViewRefreshControl:self.tableView refreshControl:self.refreshControl];
    [self.refreshControl beginRefreshing];
    self.navigationItem.rightBarButtonItem.title = @"Restoring Purchases...";
    self.navigationItem.rightBarButtonItem.enabled = NO;

    NSLog(@"Restoring products...");
    
    [self resetTransactionObserver];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

-(void)requestProducts {
    [Utils showTableViewRefreshControl:self.tableView refreshControl:self.refreshControl];
    [self.refreshControl beginRefreshing];
    
    NSSet *productIds = [NSSet setWithObjects:[ExpenseModel appInfo].fullVersionProductIdentifier, nil];
    _productsReq = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
    _productsReq.delegate = self;
        
    NSLog(@"Requesting product list.");
    [_productsReq start];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 54;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    static NSString *s = @"Purchases Available";
    return s;
}

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    [Utils formatToStandardHeaderView:view];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_iapProducts == nil) {
        return 0;
    } else {
        return _iapProducts.count;
    }
}

-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    _iapProducts = response.products;
    
    if (response.products.count > 0) {
        [self.tableView reloadData];
    } else {
        [Utils showModalDialogWithTitle:@"Not Available" message:@"No products are available at this time."];
    }
    
    [self.refreshControl endRefreshing];
}

-(void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    [Utils showModalDialogWithTitle:@"Offline" message:@"Products Store is currently offline. Please try again some other time."];
    [self.navigationItem.rightBarButtonItem setEnabled:NO];

    NSLog(@"didFailWithError: %@", error.description);
    
    [self.refreshControl endRefreshing];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseProductCell = @"ProductCell";
    
    ProductItemCell *cell = (ProductItemCell *)[tableView dequeueReusableCellWithIdentifier:reuseProductCell forIndexPath:indexPath];
    SKProduct *prod = _iapProducts[indexPath.row];
    
    cell.productNameLabel.text = prod.localizedTitle;
    cell.productDescriptionLabel.text = prod.localizedDescription;
    cell.buyBtn.tag = indexPath.row;
    
    if ([[Defaults inst] existsPurchasedProductId:prod.productIdentifier] == NO) {
        // Product not purchased.
        NSString *priceStr = [Utils formattedCurrencyAmount:prod.price.floatValue withLocale:prod.priceLocale];
        [cell.buyBtn setTitle:[NSString stringWithFormat:@"Buy %@", priceStr] forState:UIControlStateNormal];
        [cell.buyBtn setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];

        [cell.buyBtn removeTarget:self action:@selector(selectBuy:) forControlEvents:UIControlEventTouchUpInside];
        [cell.buyBtn addTarget:self action:@selector(selectBuy:) forControlEvents:UIControlEventTouchUpInside];

        if (_buyInProgress == NO) {
            [cell.buyBtn setEnabled:YES];
        } else {
            [cell.buyBtn setEnabled:NO];
        }
    } else {
        // Product already purchased.
        NSString *alreadyPurchasedStr = [NSString stringWithFormat:@"Purchased"];
        [cell.buyBtn setTitle:alreadyPurchasedStr forState:UIControlStateNormal];
        [cell.buyBtn setEnabled:NO];
    }
    
    return cell;
}

-(void)selectBuy:(UIButton *)sender {
    [self resetTransactionObserver];
    
    SKProduct *prod = _iapProducts[sender.tag];
    SKPayment *payment = [SKPayment paymentWithProduct:prod];

    NSLog(@"Sending payment for product: %@", prod.productIdentifier);
    [[SKPaymentQueue defaultQueue] addPayment:payment];

    _buyInProgress = YES;
    
    [self.tableView reloadData];
}

-(void)processProductId:(NSString *)productIdentifier {
    // Remember this product id as being purchased.
    [[Defaults inst] addPurchasedProductId:productIdentifier];
}

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    BOOL hasTransactionOccured = NO;
    BOOL hasTransactionFailed = NO;
    NSString *firstErrorMsg = nil;
    
    for (SKPaymentTransaction *trans in transactions) {
        if (trans.transactionState == SKPaymentTransactionStatePurchased) {
            [self processProductId:trans.payment.productIdentifier];
            [[SKPaymentQueue defaultQueue] finishTransaction:trans];
            hasTransactionOccured = YES;
            _buyInProgress = NO;
            
        } else if (trans.transactionState == SKPaymentTransactionStateRestored) {
            [self processProductId:trans.originalTransaction.payment.productIdentifier];
            [[SKPaymentQueue defaultQueue] finishTransaction:trans];
            hasTransactionOccured = YES;
            
            [self enableRestoreButton];

        } else if (trans.transactionState == SKPaymentTransactionStateFailed) {
            NSLog(@"SKPaymentTransactionStateFailed: %@", trans.error.description);
            if (firstErrorMsg == nil) {
                firstErrorMsg = trans.error.localizedDescription;
            }

            [[SKPaymentQueue defaultQueue] finishTransaction:trans];
            hasTransactionOccured = YES;
            hasTransactionFailed = YES;
            _buyInProgress = NO;
        }

    }
    
    if (hasTransactionFailed) {
        [Utils showModalDialogWithTitle:@"Store Error" message:firstErrorMsg];
    }
    
    if (hasTransactionOccured) {
        [self.tableView reloadData];
    }
}

-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    NSLog(@"Transactions were restored (restoreCompletedTransactionsFinished).");
    [Utils showModalDialogWithTitle:@"Restored" message:@"Previous purchases have been restored."];
    
    [self.refreshControl endRefreshing];
    [self enableRestoreButton];
}

-(void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSLog(@"restoreCompletedTransactionsFailedWithError: %@", error.description);
    [Utils showModalDialogWithTitle:@"Restore Error from Store" message:error.localizedDescription];

    [self.refreshControl endRefreshing];
    [self enableRestoreButton];
}

-(void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
    NSLog(@"removedTransactions: %@", transactions);
}

-(void)enableRestoreButton {
    self.navigationItem.rightBarButtonItem.title = @"Restore";
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

@end

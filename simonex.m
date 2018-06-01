// MIT License
//
// Copyright (c) 2018 Oliver Bayer
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import <objc/objc.h>
#import <objc/runtime.h>

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef void (^OnePasswordLoginDictionaryCompletionBlock)(NSDictionary * __nullable loginDictionary, NSError * __nullable error);

NS_ASSUME_NONNULL_BEGIN
@interface Credentials : NSObject
	@property (nonatomic, readonly) NSString * username;
	@property (nonatomic, readonly) NSString * password;

	- (nullable instancetype)initWithUsername:(NSString *)username password:(NSString *)password NS_DESIGNATED_INITIALIZER;
	- (nullable instancetype)init NS_UNAVAILABLE;
@end
NS_ASSUME_NONNULL_END

@implementation Credentials

- (instancetype)initWithUsername:(NSString *)username password:(NSString *)password {
		self = [super init];

		if (self) {
			_username = username;
			_password = password;
		}

		return self;
}

@end

#pragma mark - SimonexPasswordViewController

/**
Simple TableView based ViewController to select a couple of credentials.
*/
NS_ASSUME_NONNULL_BEGIN
@interface SimonexPasswordViewController : UITableViewController

@property (nonatomic, copy, nullable) void (^didSelectItemWithCredentials)(NSString *username, NSString *password);

@end
NS_ASSUME_NONNULL_END

@implementation SimonexPasswordViewController {
	NSArray<Credentials *> * _credentials;
}

- (void)viewDidLoad {
	_credentials = @[
		[[Credentials alloc] initWithUsername:@"oliver@example.com" password:@"12345678"]
	];

	[self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _credentials.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	Credentials *credentials = _credentials[indexPath.item];

	self.didSelectItemWithCredentials(credentials.username, credentials.password);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

	Credentials *credentials = _credentials[indexPath.item];
	cell.textLabel.text = credentials.username;

	return cell;
}

@end

#pragma mark - OnePasswordExtension swizzling

static void patched_findLoginForURLString(id self, SEL _cmd, NSString * urlString, UIViewController * controller, id sender, OnePasswordLoginDictionaryCompletionBlock completionBlock) {
	SimonexPasswordViewController *ctrl = [SimonexPasswordViewController new];

	ctrl.modalPresentationStyle = UIModalPresentationFormSheet;
	ctrl.didSelectItemWithCredentials = ^(NSString *username, NSString *password) {
		NSDictionary *dict = @{ @"username": username, @"password": password };
		completionBlock(dict, nil);

		[controller dismissViewControllerAnimated:YES completion:nil];
	};

	[controller presentViewController:ctrl animated:YES completion:nil];
}

static int patched_isAppExtensionAvailable(id self, SEL _cmd) {
	return 1;
}

#pragma mark - dylib injection hook

static void patch(NSString * className, NSString * selectorName, IMP patch) {
	Class class = NSClassFromString(className);
	SEL selector = NSSelectorFromString(selectorName);

	Method method = class_getInstanceMethod(class, selector);

	if (NULL == method) {
		NSLog(@"*** patch *** ERROR: Selector named: %@ not found", selectorName);
	} else {
		NSLog(@"*** patch *** Patched instance method: %@", selectorName);
	}

	method_setImplementation(method, patch);
}

__attribute__((constructor)) void hook() {
	patch(@"OnePasswordExtension", @"findLoginForURLString:forViewController:sender:completion:", (IMP)patched_findLoginForURLString);
	patch(@"OnePasswordExtension", @"isAppExtensionAvailable", (IMP)patched_isAppExtensionAvailable);
}

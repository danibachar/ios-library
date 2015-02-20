#import "UAInAppNotificationView.h"

@interface UAInAppNotificationView ()

@property(nonatomic, strong) UIView *tab;
@property(nonatomic, strong) UILabel *messageLabel;
@property(nonatomic, strong) UIButton *button1;
@property(nonatomic, strong) UIButton *button2;

@end

@implementation UAInAppNotificationView

- (instancetype)initWithPosition:(UAInAppNotificationPosition)position numberOfButtons:(NSUInteger)numberOfButtons {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;

        // rounded corners
        self.layer.cornerRadius = 4;
        self.layer.borderColor = [[UIColor blackColor] CGColor];
        self.layer.borderWidth = 0.5;

        self.messageLabel = [UILabel new];
        self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.messageLabel.userInteractionEnabled = NO;

        [self addSubview:self.messageLabel];

        self.tab = [UIView new];
        self.tab.translatesAutoresizingMaskIntoConstraints = NO;
        self.tab.layer.cornerRadius = 4;
        self.tab.autoresizesSubviews = YES;
        [self addSubview:self.tab];

        // add buttons depending on the passed number
        if (numberOfButtons) {
            self.button1 = [self buildButton];
            [self addSubview:self.button1];

            if (numberOfButtons > 1) {
                self.button2 = [self buildButton];
                [self addSubview:self.button2];
            }
        }

        [self buildLayoutWithPosition:position numberOfButtons:numberOfButtons];
    }

    return self;
}

- (UIButton *)buildButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    // rounded corners
    button.layer.cornerRadius = 4;
    return button;
}

- (NSArray *)constraintsForBottomPositionWithNumberOfButtons:(NSUInteger)numberOfButtons {
    NSMutableArray *constraints = [NSMutableArray array];

    // tab is at the top, followed by the label
    [constraints addObject:@"V:|-tabMargin-[tab]-verticalMargin-[label]"];

    // 0 buttons
    if (!numberOfButtons) {
        // label is followed by the edge
        [constraints addObject:@"V:[label]-verticalMargin-|"];
    } else if (numberOfButtons == 1) {
        // button 1 is vertically positioned underneath the label
        [constraints addObject:@"V:[label]-verticalMargin-[button1]-verticalMargin-|"];

        // button 1 takes up all space apart from margins on either side
        [constraints addObject:@"H:|-horizontalMargin-[button1]-horizontalMargin-|"];
    } else if (numberOfButtons > 1) {
        // button 1 is vertically positioned underneath the label
        [constraints addObject:@"V:[label]-verticalMargin-[button1]-verticalMargin-|"];

        // button 2 is vertically positioned underneath the label, followed by the edge
        [constraints addObject:@"V:[label]-verticalMargin-[button2]-verticalMargin-|"];

        // button 1 and two are equal in size
        [constraints addObject:@"H:|-horizontalMargin-[button1]-horizontalMargin-[button2(==button1)]-horizontalMargin-|"];
    }

    return constraints;
}

- (NSArray *)constraintsForTopPositionWithNumberOfButtons:(NSUInteger)numberOfButtons {
    NSMutableArray *constraints = [NSMutableArray array];

    // label is at the top
    [constraints addObject:@"V:|-verticalMargin-[label]"];

    // 0 buttons
    if (!numberOfButtons) {
        // label is followed by the tab and the edge
        [constraints addObject:@"V:[label]-verticalMargin-[tab]-tabMargin-|"];
    } else if (numberOfButtons == 1) {
        // button 1 is positioned beneath the label, followed by the tab and the edge
        [constraints addObject:@"V:[label]-verticalMargin-[button1]-verticalMargin-[tab]-tabMargin-|"];

        // button 1 takes up all space apart from margins on either side
        [constraints addObject:@"H:|-horizontalMargin-[button1]-horizontalMargin-|"];

    } else if (numberOfButtons > 1) {
        // button 2 is position beneath the label, followed by the tab and the edge
        [constraints addObject:@"V:[label]-verticalMargin-[button2]-verticalMargin-[tab]-tabMargin-|"];

        // button 1 is positioned beneath the label, followed by the tab and the edge
        [constraints addObject:@"V:[label]-verticalMargin-[button1]-verticalMargin-[tab]-tabMargin-|"];

        // button 1 and two are equal in size
        [constraints addObject:@"H:|-horizontalMargin-[button1]-horizontalMargin-[button2(==button1)]-horizontalMargin-|"];
    }
    
    return constraints;
}

- (void)buildLayoutWithPosition:(UAInAppNotificationPosition)position numberOfButtons:(NSUInteger)numberOfButtons {

    // layout constants
    CGFloat verticalMargin = 15;
    CGFloat horizontalMargin = 5;
    CGFloat lineHeight = 15;
    CGFloat nLines = 4;
    CGFloat tabHeight = 5;
    CGFloat tabWidth = 30;
    CGFloat tabMargin = 5;
    CGFloat labelHeight = lineHeight * nLines;

    // views and metrics dictionaries for binding in VFL expressions
    NSMutableDictionary *views = [NSMutableDictionary dictionary];
    [views setValue:self.tab forKey:@"tab"];
    [views setValue:self.messageLabel forKey:@"label"];
    [views setValue:self.button1 forKey:@"button1"];
    [views setValue:self.button2 forKey:@"button2"];

    id metrics = @{@"verticalMargin": @(verticalMargin),
                   @"horizontalMargin":@(horizontalMargin),
                   @"tabMargin":@(tabMargin),
                   @"tabHeight":@(tabHeight),
                   @"tabWidth":@(tabWidth),
                   @"labelHeight":@(labelHeight)};


    // centering the tab requires laying out a constraint the hard way
    [self addConstraint:[NSLayoutConstraint constraintWithItem:views[@"tab"]
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1 constant:0]];

    // constraints common to all configurations
    NSArray *commonConstraints = @[@"H:[tab(tabWidth)]", // set the tab width
                                   @"V:[tab(tabHeight)]", // set the tab height
                                   @"V:[label(labelHeight)]", //set the label height
                                   @"H:|-horizontalMargin-[label]-horizontalMargin-|"]; // label is inset by the horizontal margin


    // constraints that vary depending on position and number of buttons present
    NSMutableArray *positionalConstraints = [NSMutableArray array];


    if (position == UAInAppNotificationPositionBottom) {
        [positionalConstraints addObjectsFromArray:[self constraintsForBottomPositionWithNumberOfButtons:numberOfButtons]];
    } else {
        [positionalConstraints addObjectsFromArray:[self constraintsForTopPositionWithNumberOfButtons:numberOfButtons]];
    }

    // add all the constraints
    for (NSString *formatString in [commonConstraints arrayByAddingObjectsFromArray:positionalConstraints]) {
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:formatString
                                                                     options:0
                                                                     metrics:metrics
                                                                       views:views]];
    }
}

@end


//
//  AssocController.h
//  CSV Magic
//
//  Created by Vlad Alexa on 1/22/14.
//  Copyright (c) 2014 Vlad Alexa. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MainController.h"

@interface AssocController : NSObject <NSComboBoxDataSource,NSComboBoxDelegate>
{
    IBOutlet MainController *mainController;    
    IBOutlet NSImageView *imageView;
    IBOutlet NSComboBox *rowSelector;
    IBOutlet NSComboBox *colSelector;
    IBOutlet NSScrollView *scrollView;
}


@end

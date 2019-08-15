// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit
import NotificationCenter
import AppCenter
import AppCenterCrashes

class TodayViewController: UIViewController, NCWidgetProviding {
    var didStartAppCenter = false;
        
    override func viewDidLoad() {
      super.viewDidLoad()
      if (!didStartAppCenter){
        MSAppCenter.setLogLevel(.verbose);
        MSAppCenter.start("0dbca56b-b9ae-4d53-856a-7c2856137d85", withServices: [MSCrashes.self])
        didStartAppCenter = true;
      }
      // Do any additional setup after loading the view from its nib.
    }
        
  @IBAction func crashMe(_ sender: Any) {
    let buf: UnsafeMutablePointer<UInt>? = nil;
    buf![1] = 1;
  }
  
  func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
      // Perform any setup necessary in order to update the view.
        
      // If an error is encountered, use NCUpdateResult.Failed
      // If there's no update required, use NCUpdateResult.NoData
      // If there's an update, use NCUpdateResult.NewData
        
      completionHandler(NCUpdateResult.newData)
    }
    
}

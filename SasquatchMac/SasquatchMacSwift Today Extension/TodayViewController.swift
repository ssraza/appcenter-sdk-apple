// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import Cocoa
import NotificationCenter
import AppCenter
import AppCenterCrashes

class TodayViewController: NSViewController, NCWidgetProviding {

    override var nibName: NSNib.Name? {
        return NSNib.Name("TodayViewController")
    }
  
  var didStartAppCenter = false;
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if (!didStartAppCenter){
      MSAppCenter.setLogLevel(.verbose);
      MSAppCenter.start("7e873482-108f-4609-8ef2-c4cebd7418c0", withServices: [MSCrashes.self])
      didStartAppCenter = true;
    }
    // Do any additional setup after loading the view from its nib.
  }

  @IBAction func crashMe(_ sender: Any) {
    let buf: UnsafeMutablePointer<UInt>? = nil;
    buf![1] = 1;
  }
  
  func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Update your data and prepare for a snapshot. Call completion handler when you are done
        // with NoData if nothing has changed or NewData if there is new data since the last
        // time we called you
        completionHandler(.noData)
    }

}

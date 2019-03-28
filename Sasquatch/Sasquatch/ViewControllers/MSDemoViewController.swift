// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

import UIKit


private let kPropertiesSection: Int = 0
private let kEstimatedRowHeight: CGFloat = 88.0

class MSDemoViewController : UITableViewController, AppCenterProtocol {
  typealias CustomPropertyType = MSCustomPropertyTableViewCell.CustomPropertyType

  var textField: UITextField?
  var appCenter: AppCenterDelegate!
  
  var contacts:[[String]] = []
  private var properties = [(key: String, type: CustomPropertyType, value: Any?)]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = kEstimatedRowHeight
    tableView.setEditing(true, animated: false)
    
    // Make sure the UITabBarController does not cut off the last cell.
    self.edgesForExtendedLayout = []
    
  }
  
  @IBAction func send() {
    let customProperties = MSCustomProperties()
    for property in properties {
      switch property.type {
      case .Clear:
        customProperties.clearProperty(forKey: property.key)
      case .String:
        customProperties.setString(property.value as? String, forKey: property.key)
      case .Number:
        customProperties.setNumber(property.value as? NSNumber, forKey: property.key)
      case .Boolean:
        customProperties.setBool(property.value as! Bool, forKey: property.key)
      case .DateTime:
        customProperties.setDate(property.value as? Date, forKey: property.key)
      }
    }
    appCenter.setCustomProperties(customProperties)
    
    // Clear the list.
    properties.removeAll()
    tableView.reloadData()
    
    // Display a dialog.
    let alertController = UIAlertController(title: "The custom properties log is queued",
                                            message: nil,
                                            preferredStyle:.alert)
    alertController.addAction(UIAlertAction(title: "OK", style: .default))
    present(alertController, animated: true)
  }
  
  @IBAction func onDismissButtonPress(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  func cellIdentifierForRow(at indexPath: IndexPath) -> String {
    var cellIdentifier: String? = nil
    if isSendRow(at: indexPath) {
      cellIdentifier = "send"
    } else if isInsertRow(at: indexPath) {
      cellIdentifier = "insert"
    } else if isDismissRow(at:indexPath) {
      cellIdentifier = "dismiss"
    } else {
      cellIdentifier = "customProperty"
    }
    return cellIdentifier ?? ""
  }
  
  func isInsertRow(at indexPath: IndexPath) -> Bool {
    return isPropertiesRowSection(indexPath.section) && indexPath.row == 0
  }

  func isSendRow(at indexPath: IndexPath) -> Bool {
    return !isPropertiesRowSection(indexPath.section) && indexPath.row == 0
  }

  func isDismissRow(at indexPath: IndexPath) -> Bool {
    return !isPropertiesRowSection(indexPath.section) && indexPath.row == 1
  }

  func isPropertiesRowSection(_ section: Int) -> Bool {
    return section == kPropertiesSection
  }
  
  // MARK: - Table view delegate
  
  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
    if isInsertRow(at: indexPath) {
      return .insert
    } else {
      return .delete
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if isInsertRow(at: indexPath) {
      self.tableView(tableView, commit: .insert, forRowAt: indexPath)
    }
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return contacts.count
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
     return "To Dos"
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath)
    
    //print("\(#function) --- section = \(indexPath.section), row = \(indexPath.row)")
    
    
    cell.textLabel?.text = contacts[indexPath.row][0]
    
    switch contacts[indexPath.row][1] {
    case "blue":
      
      let color = UIColor.blue
      let semi = color.withAlphaComponent(0.2)
      cell.backgroundColor = semi
    case "red":
      let color = UIColor.red
      let semi = color.withAlphaComponent(0.2)
      cell.backgroundColor = semi
    case "green":
      let color = UIColor.green
      let semi = color.withAlphaComponent(0.2)
      cell.backgroundColor = semi
    default:
      cell.backgroundColor = UIColor.lightGray
    }
    
    return cell
  }
  
  @IBAction func onDone(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func onRefresh(_ sender: Any) {
    openAlertView()
  }
  
  func openAlertView() {
    let alert = UIAlertController(title: "What is your To Do?", message: "I want to...", preferredStyle: UIAlertControllerStyle.alert)
    alert.addTextField(configurationHandler: configurationTextField)
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler:{ (UIAlertAction) in
      print("User click Ok button")
      print(self.textField?.text ?? "defaultVal")
      
      let value = self.textField?.text ?? "placehoder,blue"

      let array = value.components(separatedBy: ",")
      let text: String  =  String(array.first!)
      
      var color: String  =  String(array.last!)
     
      if array.count < 2 {
        color = "default"
      }
      
      self.contacts.append([text, color])
      
      self.appCenter.createDocument(value);
      
      self.tableView.reloadData()
    }))
    self.present(alert, animated: true, completion: nil)
  }
  
  func configurationTextField(textField: UITextField!) {
    if (textField) != nil {
      self.textField = textField!        //Save reference to the UITextField
      self.textField?.placeholder = "Some text";
    }
  }
}

//
//  MenuTableViewController.swift
//  
//
//  Created by Phil Vasseur on 8/17/17.
//
//

import UIKit

class MenuTableViewController: UITableViewController {
    
    
    // MARK: - Global Variables
    var totalOrdersCount: Int = 0 //Used to keep track of how many orders already exist, so user can't accidently order more than 3.
    var ordersPlaced: [Orders] = [] //Returned to OrderScreen class when placeOrder button is pressed.
    var selectedDiningHall : String!
    var menuItems : [[String : Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        menuItems.append(["image" : UIImage(named: "the-yale-burger")!, "title" : "The Yale Burger", "description" :
            "A blend of finely chopped roasted mushrooms and ground beef. Smashed on the grill for maximum char and then served with a custom sauce on a brioche bun."])
        menuItems.append(["image" : UIImage(named: "the-beyond-burger")!, "title" : "Veggie Burger", "description" :
            "A vegan, plant based burger served with all the juicy, meat deliciousness of a traditional burger. Served on a locally crafted bun with lettuce, tomato, and a custom sauce."])
        self.tableView.backgroundColor = UIColor(hex: "#fafafa")

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "menuItemCell",
            for: indexPath) as? MenuTableViewCell else {
                fatalError("BAD ERROR... ORDER CONTROL TABLE CELL")
        }
        cell.setItemInfo(itemDetails: menuItems[indexPath.row])
        cell.delegate = self
        return cell
    }

}

//
//  UserViewController.swift
//  InstagramClone
//
//  Created by Xuehua Chen on 1/29/17.
//  Copyright © 2017 Xuehua Chen. All rights reserved.
//

import UIKit
import AWSDynamoDB

class UserViewController: UITableViewController {

    let dataService = DataService()

    var refresher: UIRefreshControl!
    var users = [User]()
    var isFollowing = ["": false]
    var credentialsProvider:AWSCognitoCredentialsProvider = AWSServiceManager.default().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    
    
    func refresh() {
        
        let mapper = AWSDynamoDBObjectMapper.default()
        let id = credentialsProvider.identityId! as String
        
        let scanExpression = AWSDynamoDBScanExpression()
        
        mapper.scan(User.self, expression: scanExpression) { (dynamoResults, err) in
            if (err != nil) {
                print(err as Any)
            } else {
                if (dynamoResults != nil) {
                    self.users.removeAll()
                    for user in dynamoResults?.items as! [User] {
                        if user.id != id {
                            self.users.append(user)
                            //self.addFollower(followee: user.id, map: mapper)
                        }
                    }
                }
            }
            
            self.dataService.findFollowings(follower: id, map: mapper).continue({ (task: AWSTask) -> Any? in
                
                if (task.error != nil) {
                    print(task.error as Any)
                }
                
                if (task.exception != nil) {
                    print(task.exception as Any)
                }
                
                if (task.result != nil) {
                    for item in task.result as! [Follower] {
                        self.isFollowing[item.followee] = true
                    }
                    
                }
                
                DispatchQueue.main.async {
                    print("reload")
                    self.tableView.reloadData()
                    self.refresher.endRefreshing()
                }
                
                return nil
            })
            
            
        }

    }
    
    func addFollower(followee: String) {
        let mapper = AWSDynamoDBObjectMapper.default()
        let follower = Follower()
        follower?.id = NSUUID().uuidString
        follower?.follower = credentialsProvider.identityId! as String
        follower?.followee = followee
        mapper.save(follower!)
    }
    
    func removeFollowee(followee: String) {
        let mapper = AWSDynamoDBObjectMapper.default()
        let id = credentialsProvider.identityId! as String
        
        dataService.findFollowee(follower: id, followee: followee, map: mapper).continue({ (task: AWSTask) -> Any? in
            if (task.error != nil) {
                print(task.error as Any)
            }
            
            if (task.exception != nil) {
                print(task.exception as Any)
            }
            
            if (task.result != nil) {
                for item in task.result as! [Follower] {
                    mapper.remove(item)
                }
            }
            return nil
        })

    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refresh()
        refresher = UIRefreshControl()
        refresher.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refresher.addTarget(self, action: #selector(UserViewController.refresh), for: UIControlEvents.valueChanged)
        tableView.addSubview(refresher)
        //refresher.addSubview(self.tableView)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = users[indexPath.row].name
        
        let followeeId = users[indexPath.row].id
        
        if isFollowing[followeeId] == true {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        print("selected")
        let followeeId = users[indexPath.row].id
        if isFollowing[followeeId] == false {
            addFollower(followee: followeeId)
            isFollowing[followeeId] = true
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            removeFollowee(followee: followeeId)
            isFollowing[followeeId] = false
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

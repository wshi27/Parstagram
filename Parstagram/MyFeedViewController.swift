//
//  MyFeedViewController.swift
//  Parstagram
//
//  Created by Weiwei Shi on 10/7/21.
//
import Parse
import AlamofireImage
import UIKit

class MyFeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var myFeedTableView: UITableView!
    
    var myPosts = [PFObject]()
    var numPosts:Int!
    let myRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myFeedTableView.delegate = self
        myFeedTableView.dataSource = self
        
        myRefreshControl.addTarget(self, action: #selector(loadPosts), for: .valueChanged)
        myFeedTableView.refreshControl = myRefreshControl

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadPosts()
    }
    @objc func loadPosts(){
        numPosts = 2
        let query = PFQuery(className:"Posts")
        query.whereKey("author", equalTo: PFUser.current() as Any)
        query.limit = numPosts
        
        query.findObjectsInBackground{(posts, error) in
            if posts != nil {
                self.myPosts = posts!
                self.myFeedTableView.reloadData()
                self.myRefreshControl.endRefreshing()
            } else{
                print("error \(String(describing: error?.localizedDescription))")
            }
        }
    }
    func loadMorePosts(){
        numPosts += 2
        let query = PFQuery(className:"Posts")
        query.whereKey("author", equalTo: PFUser.current() as Any)
        query.limit = numPosts
        
        query.findObjectsInBackground{(posts, error) in
            if posts != nil {
                self.myPosts = posts!
                self.myFeedTableView.reloadData()
                self.myRefreshControl.endRefreshing()
            } else{
                print("error \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    @IBAction func onLogout(_ sender: UIBarButtonItem) {
        PFUser.logOut()
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = myFeedTableView.dequeueReusableCell(withIdentifier: "MyPostCell") as! MyPostCell
        let post = myPosts[indexPath.row]
        
        cell.usernameLabel.text = PFUser.current()?.username
        cell.captionLabel.text = (post["caption"] as! String)
        let imageFile = post["image"] as! PFFileObject
        let urlString = imageFile.url!
        let url = URL(string: urlString)!
        
        cell.photoView.af.setImage(withURL: url)
        return cell
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == myPosts.count{
            loadMorePosts()
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

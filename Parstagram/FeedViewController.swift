//
//  FeedViewController.swift
//  Parstagram
//
//  Created by Weiwei Shi on 10/6/21.
//
import Parse
import UIKit
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate{
    
    @IBOutlet var feedTableView: UITableView!
    var posts = [PFObject]()
    var numPosts:Int!
    var showsCommentBar = false
    var selectedPost: PFObject!
    
    let myRefreshControl = UIRefreshControl()
    let commentBar = MessageInputBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
        
        feedTableView.delegate = self
        feedTableView.dataSource = self
        
        myRefreshControl.addTarget(self, action: #selector(loadPosts), for: .valueChanged)
        feedTableView.refreshControl = myRefreshControl
        
        feedTableView.keyboardDismissMode = .interactive
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillBeHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        //Create the comment
        let comment = PFObject(className: "Comments")
        comment["text"] = text
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()!

        selectedPost.add(comment, forKey: "comments")

        selectedPost.saveInBackground { (success, error) in
            if success {
                print("Comment saved")
                self.feedTableView.reloadData()
            } else {
                print("Error saving comment")
            }
        }
        //Clear and dismiss the input bar
        
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
    }
    @objc func keyboardWillBeHidden(note: Notification){
        commentBar.inputTextView.text = nil
        showsCommentBar = false
        becomeFirstResponder()
    }
    
    override var inputAccessoryView: UIView?{
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool{
        return showsCommentBar
    }
    
    @IBAction func onLogout(_ sender: UIBarButtonItem) {
        PFUser.logOut()
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(identifier: "LoginViewController")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let delegate = windowScene.delegate as? SceneDelegate else {return}
        delegate.window?.rootViewController = loginViewController
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadPosts()
    }
    @objc func loadPosts(){
        numPosts = 20
        let query = PFQuery(className:"Posts")
        query.order(byDescending: "updatedAt")
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = numPosts
        
        query.findObjectsInBackground{(posts, error) in
            if posts != nil {
                self.posts = posts!
                self.feedTableView.reloadData()
                self.myRefreshControl.endRefreshing()
            } else{
                print("error \(String(describing: error?.localizedDescription))")
            }
        }
    }
    func loadMorePosts() {
        numPosts += 20
        let query = PFQuery(className:"Posts")
        query.order(byDescending: "updatedAt")
        query.includeKeys(["author", "comments", "comments.author"])
        query.limit = numPosts
        
        query.findObjectsInBackground{(posts, error) in
            if posts != nil {
                self.posts.removeAll()
                self.posts = posts!
                self.feedTableView.reloadData()
                self.myRefreshControl.endRefreshing()
            } else{
                print("error \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        return comments.count + 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == 0 {
            let cell = feedTableView.dequeueReusableCell(withIdentifier: "PostCell") as! PostCell
            let user = post["author"] as! PFUser
            cell.usernameLabel.text = user.username
            cell.captionLabel.text = (post["caption"] as! String)
            let imageFile = post["image"] as! PFFileObject
            let urlString = imageFile.url!
            let url = URL(string: urlString)!
            
            cell.photoView.af.setImage(withURL: url)
            
            return cell
        } else if indexPath.row <= comments.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell") as! CommentCell
            let comment = comments[indexPath.row - 1]
            
            cell.commentLabel.text = comment["text"] as? String
            let user = comment["author"] as! PFUser
            cell.nameLabel.text = user.username
            
            return cell
        } else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "addCommentCell")!
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section + 1 == posts.count{
            loadMorePosts()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1 {
            showsCommentBar = true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
            selectedPost = post
            let path = IndexPath(row: indexPath.row, section: indexPath.section)
            feedTableView.scrollToRow(at: path, at: .middle, animated: true)
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



import UIKit
import Firebase
import Alamofire

class GroupChatRoomViewController: UIViewController, UITableViewDataSource,UITableViewDelegate, UITextFieldDelegate {
  
    

    @IBOutlet weak var button_send: UIButton!
    @IBOutlet weak var textfield_message: UITextField!
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var destinationRoom : String?
    var uid : String?
    var dataBaseRef : DatabaseReference?
    var observe : UInt?
    var comments : [ChatModel.Comment] = []
    var users : [String:AnyObject]?
    var peopleCount : Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("users").observeSingleEvent(of: DataEventType.value, with:
            { (datasnapshot) in
                self.users = datasnapshot.value as! [String:AnyObject]
                //print(dic.count)
        })
        button_send.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        getMessageList()
        
        self.tabBarController?.tabBar.isHidden = true
        let tap : UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    //시작
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    //종료
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        self.tabBarController?.tabBar.isHidden = false
        
        dataBaseRef?.removeObserver(withHandle: observe!)
    }
    
    
    func sendMessage() {
        let value : Dictionary<String,Any> = [
            "uid" : uid!,
            "message" : textfield_message.text!,
            "timestamp" : ServerValue.timestamp()
        ]
        Database.database().reference().child("chatrooms").child(destinationRoom!).child("comments").childByAutoId().setValue(value) { (err, ref) in
            
            Database.database().reference().child("chatrooms").child(self.destinationRoom!).child("users").observeSingleEvent(of: DataEventType.value, with: { (datasnapshot) in
                let dic = datasnapshot.value as! [String:Any]
                for item in dic.keys {
                    if (item == self.uid){
                        continue
                    }
                    let user = self.users![item]
                    self.sendgcm(pushToken: user!["pushToken"] as! String)
                }
                self.textfield_message.text = ""
            })
        }
    }
    
    func sendgcm(pushToken : String?) {
        let url = "https://gcm-http.googleapis.com/gcm/send"
        let header : HTTPHeaders = [
            "Content-Type":"application/json",
            "Authorization":"key=AIzaSyDDd8qaqXDF2hnnxN_mWXCUh9jK7wij_cw"
        ]
        
        let userName = Auth.auth().currentUser?.displayName
        
        var notificationModel = NotificationModel()
        notificationModel.to = pushToken
        notificationModel.notification.title = userName
        notificationModel.notification.text = textfield_message.text
        notificationModel.data.title = userName
        notificationModel.data.text = textfield_message.text
        
        let params = notificationModel.toJSON()
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
            print("GroupChatRoomVC = \(response.result.value)")
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(self.comments[indexPath.row].uid == uid) {
            let view = tableview.dequeueReusableCell(withIdentifier: "MyMessageCell", for: indexPath) as! MyMessageCell
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            if let time = self.comments[indexPath.row].timestamp {
                view.label_timestamp.text = time.toDayTime
            }
            setReadCount(label: view.label_read_counter, position: indexPath.row)
            return view
        } else {
            let destinationUser = users![self.comments[indexPath.row].uid!]
            let view = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMessageCell
            view.label_name.text = destinationUser!["name"] as! String
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            
            let imageUrl = destinationUser!["profileImageUrl"] as! String
            let url = URL(string:(imageUrl))
            view.imageview_profile.layer.cornerRadius = view.imageview_profile.frame.width/2
            view.imageview_profile.clipsToBounds = true
            view.imageview_profile.kf.setImage(with: url)
            //            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, err) in
            //                DispatchQueue.main.async {
            //                    view.imageview_profile.image = UIImage(data: data!)
            //
            //                }
            //            }).resume()
            if let time = self.comments[indexPath.row].timestamp {
                view.label_timestamp.text = time.toDayTime
            }
            setReadCount(label: view.label_read_counter, position: indexPath.row)
            return view
        }
        
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
 
    
    func setReadCount(label:UILabel?, position:Int?){
        let readCount = self.comments[position!].readUsers.count //읽은사람 인원수
        if (peopleCount == nil) {
            Database.database().reference().child("chatrooms").child(destinationRoom!).child("users").observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
                
                let dic = datasnapshot.value as! [String:Any]
                self.peopleCount = dic.count
                let noReadCount = self.peopleCount! - readCount
                
                if (noReadCount > 0){
                    label?.isHidden = false
                    label?.text = String(noReadCount)
                }else {
                    label?.isHidden = true
                }
            })
        } else {
            let noReadCount = self.peopleCount! - readCount
            if (noReadCount > 0){
                label?.isHidden = false
                label?.text = String(noReadCount)
            }else {
                label?.isHidden = true
            }
        }
    }
    
    
    func getMessageList() {
        dataBaseRef = Database.database().reference().child("chatrooms").child(self.destinationRoom!).child("comments")
        observe = dataBaseRef?.observe(DataEventType.value , with: { (datasnapshot) in
            self.comments.removeAll()
            var readUserDic : Dictionary<String,AnyObject> = [:]
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                let key = item.key as String
                let comment = ChatModel.Comment(JSON: item.value as! [String:AnyObject])
                let comment_modify = ChatModel.Comment(JSON: item.value as! [String:AnyObject])
                
                comment_modify?.readUsers[self.uid!] = true
                readUserDic[key] = comment?.toJSON() as! NSDictionary //Firebase가 NSDictionary만 지원
                self.comments.append(comment!)
            }
            let nsDic = readUserDic as NSDictionary
            
            if(self.comments.last?.readUsers.keys == nil) {
                return
            }
            if(!(self.comments.last?.readUsers.keys.contains(self.uid!))!) {
                
                
                datasnapshot.ref.updateChildValues(nsDic as! [AnyHashable : Any], withCompletionBlock: { (err, ref) in
                    self.tableview.reloadData()
                    if self.comments.count > 0 {
                        self.tableview.scrollToRow(at: IndexPath(item:self.comments.count-1,section:0), at: UITableViewScrollPosition.bottom, animated: false)
                    }
                })
            }else {
                self.tableview.reloadData()
                if self.comments.count > 0 {
                    self.tableview.scrollToRow(at: IndexPath(item:self.comments.count-1,section:0), at: UITableViewScrollPosition.bottom, animated: false)
                }
            }
            
        })
    }

    func keyboardWillShow(notification : Notification) {
        if let keyboardSize = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.bottomConstraint.constant = keyboardSize.height
        }
        UIView.animate(withDuration: 0, animations: {
            self.view.layoutIfNeeded()
        }, completion: {  //키보드가 밀릴때
            (complete) in
            if self.comments.count > 0 {
                self.tableview.scrollToRow(at: IndexPath(item:self.comments.count-1,section:0), at: UITableViewScrollPosition.bottom, animated: true)
            }
        })
        
    }
    
    func keyboardWillHide(notification : Notification) {
        self.bottomConstraint.constant = 20
        self.view.layoutIfNeeded()
    }
    
    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textfield_message.resignFirstResponder()
        return true
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    


}



import UIKit
import Firebase
import Alamofire
import Kingfisher

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    
  
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var tableview: UITableView!
    
    @IBOutlet var textfield_message: UITextField! //{ didset { textfield_message.delegate = self } }
    @IBOutlet var sendButton: UIButton!
    var uid : String?
    var chatRoomUid : String?
    
    var comments : [ChatModel.Comment] = []
    var destinationUsermodel : UserModel?
    
    var dataBaseRef : DatabaseReference?
    var observe : UInt?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textfield_message.delegate = self
        uid = Auth.auth().currentUser?.uid
        sendButton.addTarget(self, action: #selector(createRoom), for: .touchUpInside)
        checkChatRoom()
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
            let view = tableView.dequeueReusableCell(withIdentifier: "DestinationMessageCell", for: indexPath) as! DestinationMessageCell
            view.label_name.text = destinationUsermodel?.name
            view.label_message.text = self.comments[indexPath.row].message
            view.label_message.numberOfLines = 0
            
            let url = URL(string:(self.destinationUsermodel?.profileImageUrl)!)
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
    
    
    public var destinationUid: String?  //채팅할 대상의 uid
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createRoom() {
        checkChatRoom()
        let createRoomInfo : Dictionary<String,Any> = [ "users" : [
            uid! : true,
            destinationUid! : true
            ]
        ]
        if (chatRoomUid == nil) {
            self.sendButton.isEnabled = false
            //방 생성 코드
            Database.database().reference().child("chatrooms").childByAutoId().setValue(createRoomInfo, withCompletionBlock: { (err, rf) in
                if (err == nil) {
                    self.checkChatRoom()
                }
            })
        } else {
            let value : Dictionary<String,Any> = [
               
                    "uid" : uid!,
                    "message" : textfield_message.text!,
                    "timestamp" : ServerValue.timestamp()
            ]
            Database.database().reference().child("chatrooms").child(chatRoomUid!).child("comments").childByAutoId().setValue(value, withCompletionBlock: { (err, ref) in
                self.sendgcm()
                self.textfield_message.text = ""
            })
        }
      
    }
    
    func sendgcm() {
        let url = "https://gcm-http.googleapis.com/gcm/send"
        let header : HTTPHeaders = [
            "Content-Type":"application/json",
            "Authorization":"key=AIzaSyDDd8qaqXDF2hnnxN_mWXCUh9jK7wij_cw"
        ]
        
        let userName = Auth.auth().currentUser?.displayName
        
        var notificationModel = NotificationModel()
        notificationModel.to = destinationUsermodel?.pushToken
        notificationModel.notification.title = userName
        notificationModel.notification.text = textfield_message.text
        notificationModel.data.title = userName
        notificationModel.data.text = textfield_message.text
        
        let params = notificationModel.toJSON()
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: header).responseJSON { (response) in
            print(response.result.value)
        }
    }
  
    func checkChatRoom() {
        Database.database().reference().child("chatrooms").queryOrdered(byChild: "users/"+uid!).queryEqual(toValue: true).observeSingleEvent(of: DataEventType.value,with: { (datasnapshot) in
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                
                if let chatRoomdic = item.value as? [String:AnyObject] {
                    let chatModel = ChatModel(JSON: chatRoomdic)
                    if(chatModel?.users[self.destinationUid!] == true) {
                        self.chatRoomUid = item.key
                        self.getDestinationInfo()
                    }
                }
//                self.chatRoomUid = item.key
//                self.sendButton.isEnabled = true
            }
        })
    }
    
    func getDestinationInfo() {
        Database.database().reference().child("users").child(self.destinationUid!).observeSingleEvent(of: DataEventType.value , with : { (datasnapshot) in
            self.destinationUsermodel = UserModel()
            self.destinationUsermodel?.setValuesForKeys(datasnapshot.value as! [String:Any])
            self.getMessageList()
        })
    }
    
    func setReadCount(label:UILabel?, position:Int?){
        let readCount = self.comments[position!].readUsers.count //읽은사람 인원수
        Database.database().reference().child("chatrooms").child(chatRoomUid!).child("users").observeSingleEvent(of: DataEventType.value, with: {(datasnapshot) in
            
            let dic = datasnapshot.value as! [String:Any]
            let noReadCount = dic.count - readCount
            
            if (noReadCount > 0){
                label?.isHidden = false
                label?.text = String(noReadCount)
            }else {
                label?.isHidden = true
            }
        })
    }
    
    
    func getMessageList() {
        dataBaseRef = Database.database().reference().child("chatrooms").child(self.chatRoomUid!).child("comments")
        observe = dataBaseRef?.observe(DataEventType.value , with: { (datasnapshot) in
            self.comments.removeAll()
            var readUserDic : Dictionary<String,AnyObject> = [:]
            for item in datasnapshot.children.allObjects as! [DataSnapshot] {
                let key = item.key as String
                let comment = ChatModel.Comment(JSON: item.value as! [String:AnyObject])
                comment?.readUsers[self.uid!] = true
                readUserDic[key] = comment?.toJSON() as! NSDictionary //Firebase가 NSDictionary만 지원
                self.comments.append(comment!)
            }
            let nsDic = readUserDic as NSDictionary
            datasnapshot.ref.updateChildValues(nsDic as! [AnyHashable : Any], withCompletionBlock: { (err, ref) in
                self.tableview.reloadData()
                
                if self.comments.count > 0 {
                    self.tableview.scrollToRow(at: IndexPath(item:self.comments.count-1,section:0), at: UITableViewScrollPosition.bottom, animated: true)
                }
            })
          
        })
    }
    
    

}

extension Int {
    var toDayTime : String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        let date = Date(timeIntervalSince1970: Double(self)/1000)
        
        return dateFormatter.string(from: date)
    }
}

class MyMessageCell : UITableViewCell {
 
    @IBOutlet var label_message: UILabel!
    @IBOutlet var label_timestamp: UILabel!
    @IBOutlet weak var label_read_counter: UILabel!
}

class DestinationMessageCell : UITableViewCell {
    
    @IBOutlet var label_message: UILabel!
    @IBOutlet var imageview_profile: UIImageView!
    @IBOutlet var label_name: UILabel!
    @IBOutlet var label_timestamp: UILabel!
    @IBOutlet weak var label_read_counter: UILabel!
}






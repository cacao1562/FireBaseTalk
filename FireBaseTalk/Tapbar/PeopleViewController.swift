

import UIKit
import SnapKit
import Firebase
import Kingfisher

class PeopleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var array: [UserModel] = []
    var tableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableview = UITableView()
        tableview.delegate = self
        tableview.dataSource = self
        tableview.register(PeopleViewTableCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableview)
        tableview.snp.makeConstraints { (m) in
            m.top.equalTo(view)
            m.bottom.left.right.equalTo(view)
   
        }
        
        Database.database().reference().child("users").observe(DataEventType.value, with: { (snapshot) in
            
            self.array.removeAll()  //중복삭제
            
            let myUid = Auth.auth().currentUser?.uid
            
            for child in snapshot.children{
                let fchild = child as! DataSnapshot
                let userModel = UserModel()
                userModel.setValuesForKeys(fchild.value as! [String : Any])
                
                if(userModel.uid == myUid) {
                    continue
                }
                
                self.array.append(userModel)
            }
            
            DispatchQueue.main.async {
                self.tableview.reloadData();
                
            }
        })

    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let index = self.tableview.indexPathForSelectedRow{
            self.tableview.deselectRow(at: index, animated: true)
        }
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(true)
//
//        if let index = self.tableview.indexPathForSelectedRow{
//            self.tableview.deselectRow(at: index, animated: true)
//        }
//
//
//    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PeopleViewTableCell
        
        let imageview = cell.imageview
        
        imageview.snp.makeConstraints { (m) in
            m.centerY.equalTo(cell)
            m.left.equalTo(cell).offset(10)
            m.height.width.equalTo(50)
        }
        
        let url = URL(string: array[indexPath.row].profileImageUrl!)
        imageview.layer.cornerRadius = 50 / 2
        imageview.clipsToBounds = true
        imageview.kf.setImage(with: url)
//        URLSession.shared.dataTask(with: !) { (data, response, err) in
//            DispatchQueue.main.async {
//                imageview.image = UIImage(data: data!)
//                imageview.layer.cornerRadius = imageview.frame.size.width / 2
//                imageview.clipsToBounds = true
//            }
//
//        }.resume()
        
        let label = cell.label!
        
        label.snp.makeConstraints { (m) in
            m.centerY.equalTo(cell)
            m.left.equalTo(imageview.snp.right).offset(20)
            }
        label.text = array[indexPath.row].name
    
        
        let label_comment = cell.label_comment!
        label_comment.snp.makeConstraints { (make) in
            make.centerX.equalTo(cell.uiview_comment_background)
            make.centerY.equalTo(cell.uiview_comment_background)
        }
        if let comment = array[indexPath.row].comment {
            label_comment.text = comment
        }
        
        cell.uiview_comment_background.snp.makeConstraints { (make) in
            make.right.equalTo(cell).offset(-10)
            make.centerY.equalTo(cell)
            if let count = label_comment.text?.count {
                    make.width.equalTo(count * 13)
            }
             else {
                make.width.equalTo(0)
                }
            
            make.height.equalTo(30)
        }
        cell.uiview_comment_background.backgroundColor = UIColor.gray
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let view = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController
        view?.destinationUid = self.array[indexPath.row].uid
        
        self.navigationController?.pushViewController(view!, animated: true)
    }



}

class PeopleViewTableCell : UITableViewCell {
    var imageview : UIImageView = UIImageView()
    var label : UILabel! = UILabel()
    var label_comment : UILabel! = UILabel()
    var uiview_comment_background : UIView = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(imageview)
        self.addSubview(label)
        self.addSubview(uiview_comment_background)
        self.addSubview(label_comment)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}





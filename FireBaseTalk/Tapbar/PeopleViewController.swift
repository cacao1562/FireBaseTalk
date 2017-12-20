

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
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addSubview(imageview)
        self.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}





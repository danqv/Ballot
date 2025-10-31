pragma solidity ^0.4.17;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign(uint minimum) public {
        address newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[]) {
        return deployedCampaigns;
    }
}

contract Campaign {
    struct Request {
        string description;
        uint value;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    Request[] public requests;
    address public manager;
    uint public minimumContribution;
    mapping(address => bool) public approvers;
//theo dõi số người tham gia trong hợp đồng này
    uint public approversCount;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function Campaign(uint minimum, address creator) public {
        manager = creator;
        minimumContribution = minimum;
    }

    function contribute() public payable {
        require(msg.value > minimumContribution);
    // Ghi nhận việc đóng góp/phê duyệt
        approvers[msg.sender] = true;
    // khi số người tham gia tăng lên thì :  
        approversCount++;
    }

    function createRequest(string description, uint value, address recipient) public restricted {
        Request memory newRequest = Request({
           description: description,
           value: value,
           recipient: recipient,
           complete: false,
           approvalCount: 0
        });
// đưa newRequest từ memory vào storage
        requests.push(newRequest);
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

    //Đảm bảo người gửi có quyền phê duyệt (là người đóng góp approver).
        require(approvers[msg.sender]);
    //Đảm bảo người gửi chưa từng phê duyệt yêu cầu này trước đó (ngăn chặn việc bỏ phiếu hai lần).
        require(!request.approvals[msg.sender]);

    //xác nhận rằng người dùng này đã đồng ý phê duyệt yêu cầu.
        request.approvals[msg.sender] = true;
    //sẽ tăng số lượng phiếu phê duyệt đã nhận lên 1.
        request.approvalCount++;
    }
     //135.Finalizing a request (hoàn tất 1 yêu cầu) :
        // a. hoàn tất với yêu cầu cụ thể nào? ---> uint index
    function finalizeRequest(uint index) public restricted {
        Request storage request = requests[index]; //lập cái này để thay thế các requests[index] = request

    // nhiều hơn 1/2 số lượng approvers đồng ý thì mới được phê duyệt chi tiền cho vendor
        require(request.approvalCount > (approversCount / 2));
    //2. làm 1 số kiểm tra cơ bản :
    // a.đảm bảo yêu cầu này chưa được đánh dấu là hoàn thành 
        require(!request.complete);

    //sau khi cập nhật số tiền đó cho người nhận  
        request.recipient.transfer(request.value);
    //đảm bảo rằng yều cầu chưa hoàn thành đó thành hiện thực
        request.complete = true;
    }
}

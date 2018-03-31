pragma solidity ^0.4.20;

// Author: Booyoun Kim
// Date: 26 March 2019
// Version: Lotto v0.1.1

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract Lotto is usingOraclize {

	address owner;
	uint selectedNum;
	bool roundOpen = true;
	uint totalAmount;

	Buyer[] public buyers;
	Winner[1] public winner;

	function Lotto() {
		owner = msg.sender;
		alarm();
	}

    modifier onlyOwner() {
        if (msg.sender == owner) {
            _;
        }
    }

	struct Buyer {
		uint id;
		address addr;
		uint amount;
		uint startIssueNum;
		uint[] issueTickets;
	}

	// 中奖者记录
	struct Winner {
		uint winnerId;
		address winnerAddr;
		uint prize;
		uint selectedNum;
	}

	function alarm() private {
		// 2 01 8年3月24日上午10：56开始
		// 2 01 8年3月31日晚12点准时结束
		//7天+ 13小时+ 1分钟
    	oraclize_query(60 * 60 * 24 * 7 + 60 * 60 * 13 + 60 * 1, "URL", "");
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) throw;
        // do something, 1 day after contract creation
		closeRound();
    }

	function closeRound() private {
		roundOpen = false;

		// 选择中奖者
		// 第一名
		winner[0].selectedNum 	= getRandomNum(0);
		winner[0].winnerId 		= findBuyerIdBySelectedNum(winner[0].selectedNum);
		winner[0].winnerAddr 	= buyers[winner[0].winnerId].addr;
		winner[0].prize 		= calPrizeForOnePersonByRanking(1);

		// 第一名
		withdraw(winner[0].winnerId, winner[0].prize);
		
		//资金支出（剩下的20%）
		owner.transfer(this.balance);
	}

	// 全部票中的一个随机选择
	function getRandomNum(uint saltNum) constant returns (uint) {
		uint totalTicketNum = getTicketTotalNum();

		// random = uint(sha3(block.timestamp)) % max;		// 0 ~ (max - 1)
		uint random = uint(sha3(block.timestamp - saltNum)) % totalTicketNum;
		return random;
	}

	// 一个随机挑选的抽签号buyerId 寻找
	function findBuyerIdBySelectedNum(uint selectedRandomNum) private returns (uint) {
		// selectedRandomNum : 抽签号码
		uint selectId;

		for (uint i = 0; i < buyers.length; i++) {
			if (selectedRandomNum > buyers[i].amount / 1000000000000000) {
				selectedRandomNum -= buyers[i].amount / 1000000000000000;
			} else {
				// i 第二街 winner
				selectId = i;
				break;
			}
		}

		// selectId :中奖者id
		return selectId;
	}

	// 상금 계산
	// function calPrizeForOnePersonByRanking(uint ranking) private returns (uint) {
	function calPrizeForOnePersonByRanking(uint ranking) constant returns (uint) {
		// 全部金额的80%使用奖金。剩下的10%将被用作种子种子选手，10%使用运营资金
		uint prize = this.balance * 8 / 10;
		return prize;
	}

	// winner 领钱
	function withdraw(uint id, uint amount) private {
		if (amount > 0) {
			buyers[id].addr.transfer(amount);
		}
    }

	// 총 티켓 수
	function getTicketTotalNum() constant returns (uint) {
		uint sum = 0;
		if (buyers.length > 0) {
			for (uint i = 0; i < buyers.length; i++) {
				sum += buyers[i].amount / 1000000000000000;
			}
		}
		return sum;
	}

	function getOwner() constant returns (address) {
		return owner;
	}

	function getBuyerAddr(uint buyerId) constant returns (address) {
		return buyers[buyerId].addr;
	}

	function getBuyerAmount(uint buyerId) constant returns (uint) {
		return buyers[buyerId].amount;
	}

	function getBuyerLength() constant returns (uint) {
		return buyers.length;
	}

    function() payable {
    	if (msg.sender == 0x1B17eB8FAE3C28CB2463235F9D407b527ba4e6Dd) {
    		// 运营者汇款的奖金
    		return;
    	}

    	// 一张票是五公斤的四角。那个未满是被无视的
    	if (roundOpen == true && msg.value >= 1000000000000000) {
    		buyers.length += 1;
			uint id = buyers.length - 1;
			
			buyers[id].id 	= id;
			// 现有门票号码号（比起下一步，要在上面）
			uint startIssueNum = getTicketTotalNum();
			buyers[id].startIssueNum = startIssueNum;
			buyers[id].addr = msg.sender;
			buyers[id].amount = msg.value;
		}
	}
}
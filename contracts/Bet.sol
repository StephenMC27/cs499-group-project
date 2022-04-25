pragma solidity ^0.8.12;

contract Bet {
    struct Team {
        string teamName;
    }

    enum GameOutcome {PENDING, HOME, AWAY}

    struct Game {
        uint256 gameStart; 
        Team home;
        Team away;
        GameOutcome outcome;
        bool exists;
    }

    struct Better {
        address payable walletId;
        uint256 amount;
    }

    Game game;
    Better[] homeBets;
    Better[] awayBets;
    uint256 pool;

    function setGame(
        uint256 _timestamp,
        string memory _homeTeam,
        string memory _awayTeam
    ) public {
        game = Game(
            _timestamp,
            Team(_homeTeam),
            Team(_awayTeam),
            GameOutcome.PENDING,
            true
        );
    }

    function setOutcome(uint8 _outcome) public {
        require(game.exists);
        require(game.outcome == GameOutcome.PENDING, 'Game already concluded');
        require(game.gameStart < block.timestamp, "Game hasn't started yet");

        game.outcome = GameOutcome(_outcome);
        payWinners();
        selfdestruct(payable(msg.sender));
    }

    function payWinners() public {
        if (game.outcome == GameOutcome.HOME) {
            uint256 splitAmount = pool / homeBets.length;
            for (uint256 i = 0; i < homeBets.length; i++) {
                pay(homeBets[i].walletId, splitAmount);
            }
        } else if (game.outcome == GameOutcome.AWAY) {
            uint256 splitAmount = pool / awayBets.length;
            for (uint256 i = 0; i < awayBets.length; i++) {
                pay(awayBets[i].walletId, splitAmount);
            }
        } else {
            for (uint256 i = 0; i < homeBets.length; i++) {
                pay(homeBets[i].walletId, homeBets[i].amount);
            }
            for (uint256 i = 0; i < awayBets.length; i++) {
                pay(awayBets[i].walletId, awayBets[i].amount);
            }
        }
    }

    function pay(address payable winner, uint256 amt)
        public
        payable
        returns (bool)
    {
        require(
            address(this).balance >= amt,
            'Not enough funds to pay the winner'
        );
        winner.transfer(amt);
        return true;
    }

    event Received(address, uint256);

    function betOnHome() external payable {
        require(game.exists, 'game does not exist');

        homeBets.push(Better(payable(msg.sender), msg.value));
        pool += msg.value;
        emit Received(msg.sender, msg.value);
    }

    function betOnAway() external payable {
        require(game.exists, 'game does not exist');
        awayBets.push(Better(payable(msg.sender), msg.value));
        pool += msg.value;
        emit Received(msg.sender, msg.value);
    }
}
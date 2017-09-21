/*
	Utility functions for safe math operations.  See link below for more information:
	https://ethereum.stackexchange.com/questions/15258/safemath-safe-add-function-assertions-against-overflows
*/
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns (uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }

    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

}